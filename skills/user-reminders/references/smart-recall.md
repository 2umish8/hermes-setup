# Smart Recall Routing Convention

When the user says "rappelle-moi" or "note que", auto-route based on nature:

| Type | Destination | Example |
|---|---|---|
| **Undated personal reminder** | Skill `user-reminders` | "Rappelle-moi de penser au multi-gateway" |
| **Date-specific** | `cronjob` | "Rappelle-moi mercredi 14h de relancer X" |
| **Deadline with escalation** | `cronjob` + repeat | "Rappelle-moi J-3, J-1, jour J pour URSSAF" |
| **Durable fact / preference** | `memory` | "Je préfère les PRs squash-merge" |
| **Execution task for Hermes** | `todo` | "Analyse la structure Mowtif" |

Memory stays clean for durable facts only. Personal reminders go to the `user-reminders` skill (loaded on demand, not injected into every turn).