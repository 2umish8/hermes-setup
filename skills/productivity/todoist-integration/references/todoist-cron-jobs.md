# Todoist Cron Jobs — JSON Format for Accountability Bots

When `hermes cron create --profile X` fails due to CLI argument parsing bugs, write cron jobs directly to the profile's cron directory.

## File Location

```
~/.hermes/profiles/<NAME>/cron/jobs.json
```

## JSON Schema

```json
{
  "jobs": [
    {
      "id": "unique-kebab-id",
      "name": "human-readable-name",
      "prompt": "Self-contained prompt for the agent...",
      "skills": [],
      "schedule": {
        "kind": "cron",
        "expr": "0 8 * * *",
        "display": "0 8 * * *"
      },
      "enabled": true,
      "deliver": "origin",
      "no_agent": false,
      "model": null,
      "provider": null
    }
  ]
}
```

## Key Fields

- `id`: Unique identifier (kebab-case). Used for tracking run history.
- `name`: Human-readable name shown in `hermes cron list`.
- `prompt`: The full self-contained instruction. Must include all context the agent needs — it runs in a fresh session with no conversation history.
- `schedule.expr`: Standard 5-field cron expression. `0 8 * * *` = daily at 8:00 AM.
- `deliver`: `"origin"` delivers to the profile's configured home channel. Can also be `"telegram"`, `"discord"`, etc.
- `skills`: List of skill names to preload before running the prompt. Empty `[]` for none.
- `no_agent`: `false` = LLM-driven (agent runs the prompt). `true` = script-only (script stdout delivered verbatim).

## Example: Accountability Bot Cron Jobs

```json
{
  "jobs": [
    {
      "id": "mira-morning-001",
      "name": "morning-briefing",
      "prompt": "Tu es Mira TheWatcher, accountability partner. C'est le matin.\n\nCONTEXTE: Utilise session_search(profile='default') pour voir l'activité récente.\n\n1. Consulte les tâches Todoist dues aujourd'hui (mcp_todoist_find_tasks_by_date)\n2. Rappelle les tâches en retard\n3. Donne le ton de la journée\n4. Termine par une question d'engagement\n\nStyle Mark Manson. Français. Messages courts Telegram.",
      "skills": [],
      "schedule": {"kind": "cron", "expr": "0 8 * * *", "display": "0 8 * * *"},
      "enabled": true,
      "deliver": "origin",
      "no_agent": false,
      "model": null,
      "provider": null
    },
    {
      "id": "mira-evening-001",
      "name": "evening-checkin",
      "prompt": "Tu es Mira TheWatcher. Check-in du soir.\n\n1. Vérifie tâches complétées (mcp_todoist_find_completed_tasks)\n2. Vérifie ce qui n'a pas été fait\n3. Compare avec sessions du profil default\n4. Prépare mini plan pour demain\n\nStyle Mark Manson. Français.",
      "skills": [],
      "schedule": {"kind": "cron", "expr": "0 21 * * *", "display": "0 21 * * *"},
      "enabled": true,
      "deliver": "origin",
      "no_agent": false,
      "model": null,
      "provider": null
    },
    {
      "id": "mira-weekly-001",
      "name": "weekly-review",
      "prompt": "Tu es Mira TheWatcher. Review hebdomadaire.\n\n1. Stats de la semaine (mcp_todoist_get_productivity_stats)\n2. Patterns: tâches repoussées, excuses récurrentes\n3. Compare avec objectifs long terme\n4. Note sur 10 + 3 priorités semaine prochaine\n\nStyle Mark Manson. Français.",
      "skills": [],
      "schedule": {"kind": "cron", "expr": "0 10 * * 0", "display": "0 10 * * 0"},
      "enabled": true,
      "deliver": "origin",
      "no_agent": false,
      "model": null,
      "provider": null
    }
  ]
}
```

## After Writing

Restart the profile's gateway to pick up new cron jobs:
```bash
systemctl --user restart hermes-gateway-<profile-name>
```

Verify with:
```bash
hermes --profile <name> cron list
```

## Pitfalls

- The `deliver` field must be `"origin"` (not `"telegram"`) if you want it delivered to the profile's home channel. Using `"telegram"` explicitly may work but `"origin"` is more portable.
- Prompts must be fully self-contained — cron sessions have no conversation context.
- Use `\n` for newlines in the JSON string.
- The `id` field should be stable across restarts. Changing it creates a new job instead of updating.
