---
name: task-closure
category: communication
description: "Format de clôture des tâches : résumé court, instructions de vérification, options suivantes ou safe-to-clear"
tags:
  - output-format
  - task-completion
  - telegram
  - communication
trigger: |
  Use for EVERY completed task, request, or query that resulted in an action:
  - any terminal command was run
  - a file was created/modified
  - a config change was applied
  - a cron job was created
  - an install was performed
  Basically any time you have a result to report.
---
# Task Closure Format

Quand une tâche est terminée (ou une sous-étape significative), structurer la réponse en **3 sections exactement** :

## 1. Résumé bref de ce qui a été fait

2-3 lignes max. Faits, pas de storytelling. Exemple :
> "Ajouté `hermes.dev.mowtif.com` → `:3333` et `code.dev.mowtif.com` → `:8080` dans le Caddyfile. Caddy gère SSL Let's Encrypt auto. Pas de Nginx."

## 2. Comment l'utilisateur peut vérifier par lui-même

1-2 commandes curl ou bash que l'utilisateur peut copier-coller pour confirmer le résultat. Exemple :
```bash
curl -s -o /dev/null -w '%{http_code}' https://hermes.dev.mowtif.com/api/stats
# → 200
```

## 3. Prochaines étapes OU safe-to-clear

**Si la tâche a des suites logiques** (typiquement 2-4 options) : les proposer sous forme de choix pour l'utilisateur. Le format exact doit pouvoir être rendu en boutons Telegram. Exemple :

> **Prochaines étapes possibles :**
> 1. Ajouter l'auth Basic sur les nouveaux sous-domaines
> 2. Ajouter un monitoring/healthcheck
> 3. ✅ Safe to clear — rien à ajouter

**Si la tâche est un cul-de-sac** (rien à faire après) : dire explicitement `✅ Safe to clear`.

**Si c'est une information / réponse pure** (pas d'action) : juste `✅ Safe to clear` à la fin.

## Pitfalls

- **Ne pas laisser de section vide.** Si tu finis par "Options suite :" sans rien, c'est pire que pas d'options du tout.
- **Pas de fluff.** Pas de "Voici ce que j'ai fait pour vous today 😊". Juste le résumé.
- **Ne pas ré-expliquer le contexte.** L'utilisateur était là pendant toute la conversation.
- **Si le résultat est un échec/erreur**, le format reste le même : résumé de ce qui a échoué, comment vérifier l'erreur, options de correction.
- **Priorité au choix Telegram** quand plusieurs options valides existent. Safe-to-clear seulement quand vraiment rien à proposer.