# Diagnostic de défaillance cron + Caddy

## Session du 2026-06-06 — Uptime monitoring échouait silencieusement

### Symptôme

Cron `Uptime monitoring - hermes & code subdomains` (no_agent, toutes les 15min) rapportait exit code 1 sans message d'alerte.

### Investigation

1. **`hermes cron list`** → job_id, script=healthcheck.sh, no_agent=true
2. **`bash -x ~/.hermes/scripts/healthcheck.sh`** → trace complète :
   - Les deux curls HTTPS → HTTP 000 (Connection refused sur port 443)
   - Le pipe `openssl s_client` dans le check cert → vide
   - Le script crashait sur la ligne du pipe openssl (set -e) AVANT d'émettre les alertes HTTP
3. **`curl https://hermes.dev.mowtif.com/api/stats`** → Connection refused confirmé
4. **`ss -tlnp | grep -E ':(80|443)'`** → rien sur 80/443
5. **`sudo systemctl status caddy`** → failed (exit code 1)
6. **`sudo journalctl -u caddy -n 50`** → `Error: adapting config using caddyfile: /etc/caddy/Caddyfile:122: unrecognized directive: open-webui.dev.mowtif.com`
7. **Examen du Caddyfile** → ligne 121 contenait `\n` littéral (backslash-n) au lieu d'un vrai saut de ligne avant le bloc `open-webui.dev.mowtif.com`

### Cause racine

Le Caddyfile avait été modifié (probablement par un agent) avec un `\n` littéral dans le texte, ce qui a :
- Concatené la fermeture du bloc `code.dev.mowtif.com` et le début du bloc suivant
- Forcé Caddy à interpréter `open-webui.dev.mowtif.com` comme une directive inconnue
- Empêché Caddy de démarrer → ports 80/443 fermés

### Fix

1. **Caddyfile** : `sudo sed -i 's/\\n# --- Open WebUI ---/# --- Open WebUI ---/' /etc/caddy/Caddyfile`
2. **Validate** : `sudo caddy validate --config /etc/caddy/Caddyfile`
3. **Restart** : `sudo systemctl restart caddy` (nécessaire car `admin off` dans la config)
4. **Vérifier** : `curl -s -o /dev/null -w '%{http_code}' https://hermes.dev.mowtif.com/api/stats` → 200
5. **healthcheck.sh** : ajouté `|| true` sur le pipe openssl pour que `set -e` ne tue pas le script

### Leçons

- **Toujours `sudo caddy fmt --overwrite` avant `validate`** — ça nettoie les artefacts d'écriture agent
- **Toujours `|| true` sur les pipes dans `$()`** avec `set -euo pipefail` — le moindre échec réseau rend le script muet
- **Un cron no_agent exit 1 sans stdout** = le script a crashé avant d'émettre quoi que ce soit. Lancer `bash -x` pour tracer.
- **Port 443 silencieux** → check Caddy en premier, pas les services backend
