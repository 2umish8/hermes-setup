---
name: agent-orchestration
description: "Configure, automate, and monitor independent AI agent instances using tmux and cron."
---

# Agent Orchestration

## Automatisation du démarrage (tmux)
Utiliser un script de démarrage dans `~/.hermes/scripts/setup_agents.sh` pour lancer plusieurs sessions `tmux` isolées.

Exemple :
```bash
tmux new-session -d -s agy_global 'agy --global'
tmux new-session -d -s agy_mowtif 'cd /home/hermes/mowtif && agy --local'
```

## Monitoring & Persistance
1. **Script de healthcheck :** Utiliser `~/.hermes/scripts/healthcheck.sh` pour vérifier que les services répondent (HTTP 200).
2. **Cron de vérification :** Créer un job cron `no_agent=true` qui relance le script de démarrage s'il détecte des sessions mortes, ou qui appelle régulièrement le script de healthcheck pour monitorer les endpoints.

## Pitfalls
- **Sessions tmux crashées :** Toujours nettoyer les anciennes sessions (`tmux kill-session -t <name>`) avant de lancer le script de démarrage pour éviter les erreurs de socket.
- **Chemins absolus :** Dans les cron jobs, utiliser des chemins complets vers les scripts et les répertoires de travail (`/home/hermes/...`).
- **Healthchecks silencieux :** Un script de healthcheck ne doit rien afficher sur `stdout` si tout va bien pour éviter de polluer les logs. Utiliser `ALERTS=""` et n'afficher que si `ALERTS` n'est pas vide.