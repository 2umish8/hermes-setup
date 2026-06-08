---
name: reverse-proxy-management
category: devops
description: "Manage reverse proxies and SSL on the VPS — audit ports, add subdomains to Caddy, handle Nginx when needed, SSL cert provisioning"
tags:
  - caddy
  - nginx
  - ssl
  - lets-encrypt
  - reverse-proxy
  - subdomain
  - web-server
trigger: |
  User asks to:
    - set up / configure a reverse proxy (nginx, caddy)
    - add/renew SSL certificates
    - expose a local service via a domain name
    - set up HTTPS for a subdomain
    - migrate from one web server to another
---

# Reverse Proxy & SSL Management

## Règle d'or : Auditer avant d'agir

**BEFORE** installer ou modifier un serveur web, vérifier ce qui écoute sur 80/443 **ET** les ports cibles potentiels (3000, 8080, etc.) :

```bash
sudo ss -tlnp | grep -E ':(80|443|3000|8080|517[3-9]|5180) '
```

**Ne jamais** installer Nginx si Caddy est déjà actif — ils entrent en conflit sur les ports.

---

## Caddy (serveur actif sur ce VPS)

Caddy est le reverse proxy principal. Il gère SSL Let's Encrypt **automatiquement**.

### Ajouter un sous-domaine au Caddyfile

Éditer `/etc/caddy/Caddyfile` avec sudo :

```
monservice.dev.mowtif.com {
    reverse_proxy localhost:3333
}
```

Pour les services nécessitant le Host header (comme code-server) :

```
code.dev.mowtif.com {
    reverse_proxy localhost:8080 {
        header_up Host {http.reverse_proxy.upstream.hostport}
    }
}
```

Caddy gère les WebSockets **transparentement** — pas de directives spéciales.

### Formater avant de valider

Les éditeurs et agents peuvent introduire des `\n` littéraux (backslash-n au lieu de vrais sauts de ligne), ce qui casse le parser. **Toujours formater avant valider :**

```bash
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
```

### Valider & Appliquer

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
```

- **Caddyfile avec `admin off`** (le cas sur ce VPS) : `sudo systemctl restart caddy`
- **Caddyfile avec admin activé** : `sudo caddy reload`

Vérifier après restart :

```bash
sudo systemctl is-active caddy
curl -s -o /dev/null -w '%{http_code}' https://hermes.dev.mowtif.com/
```

### SSL

Caddy provisionne les certificats Let's Encrypt **au premier hit HTTPS**. Aucune intervention manuelle — pas de certbot, pas de chemins `ssl_certificate`.

---

## Nginx (alternative — pas recommandé quand Caddy est présent)

Si Nginx est absolument nécessaire :

1. Stopper & désactiver Caddy :
   `sudo systemctl stop caddy && sudo systemctl disable caddy`
2. Installer nginx + certbot (si pas déjà présents)
3. Transférer **tous** les blocs reverse_proxy du Caddyfile vers Nginx
4. Réimplémenter l'auth (Caddy `basicauth` → Nginx `auth_basic`)
5. Certbot pour les certificats :
   `sudo certbot --nginx -d hermes.dev.mowtif.com -d code.dev.mowtif.com --non-interactive --agree-tos -m umischael@gmail.com`
6. Activer le renouvellement auto :
   `sudo systemctl enable certbot.timer && sudo certbot renew --dry-run`

---

### Monitoring des agents (agy, fcc-claude, copilot)
Une fois les sous-domaines en place, ajouter un healthcheck automatisé. Le script de monitoring `~/.hermes/scripts/healthcheck.sh` doit contenir les endpoints :
- `agy-global.dev.mowtif.com|200`
- `agy-mowtif.dev.mowtif.com|200`
- `fcc-global.dev.mowtif.com|200`
- `fcc-mowtif.dev.mowtif.com|200`
- `copilot-global.dev.mowtif.com|200`
- `copilot-mowtif.dev.mowtif.com|200`

1. Placer un script dans `~/.hermes/scripts/` (voir `scripts/healthcheck.sh` dans ce skill)
2. Créer un cron Hermes en no_agent=true toutes les 15 min :
   ```bash
   hermes cron create --name "Uptime monitoring" --schedule "every 15m" --no-agent --script healthcheck.sh
   ```
3. Le script est **silencieux quand tout va bien** (stdout vide = pas de message)
4. Il alerte sur Telegram si :
   - HTTP code inattendu (ni 200 ni 302)
   - Connexion impossible (timeout, DNS failure)
   - Certificat SSL expire dans < 15 jours

### Ajouter des endpoints au monitoring

Éditer `~/.hermes/scripts/healthcheck.sh` (utilisé par le cron) et ajouter une ligne au tableau `ENDPOINTS` :
```
"mon-sous-domaine.dev.mowtif.com|200"
```
Format : `"host|expected_http_code"`. Le script vérifiera `https://$host` et attendra `expected_http_code`.

### Mise à jour des scripts
Si vous modifiez `~/.hermes/scripts/healthcheck.sh`, vérifiez qu'il est bien accessible par le job cron. Utilisez toujours des chemins relatifs à `~/.hermes/scripts/` pour les cron jobs `no_agent`.

---

## Références

- `references/caddyfile-mowtif.md` — Caddyfile complet de la stack Mowtif (format, structure, snippets).

---

## Pitfalls
### Pitfalls
- **Caddy occupe 80/443 en premier** — ne pas installer Nginx sans vérifier. Ils ne peuvent pas coexister sur les mêmes ports.
- **`admin off` dans le Caddyfile** → `caddy reload` échoue. Utiliser `systemctl restart`.
- **Conflits de port** — si un sous-domaine retourne 502, vérifier quel service écoute réellement sur le port cible avec `sudo ss -tlnp | grep :<port>`. Le service a pu crasher ou changer de port.
- **code-server besoin du Host header** — sans `header_up Host`, la redirection de login peut casser.
- **Let's Encrypt rate limits** — Caddy gère ça automatiquement ; certbot manuel peut les atteindre si lancé trop souvent.
- **Next.js en dev mode peut rendre 500** — erreur de config (env vars manquantes), pas un problème de reverse proxy.
- **Toujours formater après édition** — `sudo caddy fmt --overwrite /etc/caddy/Caddyfile`. Les `\n` littéraux (backslash-n au lieu de vrai newline) sont un mode de faillite classique quand un agent a écrit le fichier ; ça casse le parser silencieusement.
- **`set -euo pipefail` + pipe dans `$()` = piège** — si une commande dans un pipe échoue à l'intérieur d'une substitution `$()`, `set -e` peut tuer le script AVANT qu'il n'affiche les résultats. Toujours suffixer par `|| true` (ex: `expiry=$(...openssl s_client... | ...) || true`) ou wrapper le pipe dans une fonction avec `|| true`.
- **healthcheck.sh silencieux ≠ OK** — si tu vois un cron `no_agent` exit 1 sans message, lance `bash -x healthcheck.sh` pour tracer. Le script peut avoir crashé sur un check certificat avant d'émettre les alertes HTTP.