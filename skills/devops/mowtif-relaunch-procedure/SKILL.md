---
name: mowtif-relaunch-procedure
description: Procédures de secours après un redémarrage système sur le VPS.
---
# Post-Reboot Relaunch Procedure

Procédures de secours après un redémarrage système sur le VPS.

## 1. Script Automatisé
Le script `/usr/local/bin/relaunch-mowtif` est installé et exécutable globalement. 
**Commande :** `relaunch-mowtif`

## 2. Procédure Manuelle (Plan B)
Si le script échoue, exécuter les étapes suivantes :

### A. Sessions TMUX
Le VPS utilise plusieurs sessions pour le dev et les agents.
- **Relancer la session principale Mowtif :**
  `tmux new-session -d -s mowtif-dev -n dev -c /home/hermes/projects/Mowtif "pnpm dev"`
- **Vérifier les autres sessions :** 
  `tmux ls`
  *(Si manquantes, relancer les outils de chaque agent spécifique).*

### B. Infrastructure Proxy
- **Redémarrer Caddy :**
  `sudo systemctl restart caddy`
- **Vérifier le statut :**
  `systemctl status caddy`

### C. Vérification des processus
- **Vérifier les processus Node/Turbo :**
  `ps aux | grep -E "node|turbo"`

## 3. Débogage
- Si Caddy ne démarre pas : `journalctl -u caddy --no-pager | tail -n 50`
- Si une session tmux échoue : Vérifier les logs dans le répertoire du projet correspondant.
