---
name: auto-logger
description: Use when a process needs to be tracked across reboots or state changes.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [logging, automation, persistence, state-tracking]
    related_skills: [user-reminders]
---

# Auto-Logger

## Overview
This skill automates the tracking of significant system or process changes. When activated, it notes the change, ensures persistence across reboots (via crontab or state files), and notifies the user in the response.

## When to Use
- When you discover a process that needs to persist across reboots.
- When an environmental change (e.g., config update, tool install) needs to be logged for auditability.
- When you want to ensure the agent reports its state/modifications during the next initialization or when prompted.


## Intégration à `after-reboot-setup`
Pour que le suivi soit automatique lors de chaque redémarrage :
1. Détecter si le service/processus a besoin d'être ajouté au script `/usr/local/bin/after-reboot-setup`.
2. Utiliser `patch` pour ajouter la commande de lancement correspondante dans le script.
3. Notifier l'utilisateur de l'ajout automatique.


## Common Pitfalls
- **Logging too much:** Avoid logging trivial tasks. Only log state-changing operations.
- **Lost state:** Always double-check if the process *actually* restarts. Use `systemd` or `cron` rather than just writing a file if you need true persistence.

## Verification Checklist
- [ ] Log entry created in `~/.hermes/logs/system_changes.log`
- [ ] Persistence mechanism verified (e.g., cron job created or systemd unit enabled)
- [ ] User notified in the current message
