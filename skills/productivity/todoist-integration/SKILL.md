---
name: todoist-integration
description: "Todoist via MCP server + v1 Sync API. Task management, overdue checks, project queries."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [todoist, mcp, tasks, productivity, accountability]
    related_skills: [native-mcp]
---

# Todoist Integration

Connect to Todoist via the MCP server (`@doist/todoist-mcp`) and/or directly via the v1 Sync API.

## MCP Server Setup

The MCP server provides 50+ tools (find-tasks, add-tasks, complete-tasks, etc.) and auto-registers as `mcp_todoist_*` tools.

### Config (`~/.hermes/config.yaml`)

```yaml
mcp_servers:
  todoist:
    command: npx
    args: ["-y", "@doist/todoist-mcp"]
    env:
      TODOIST_API_KEY: "<user-token>"
```

### Verify

```bash
hermes mcp list          # Check server appears
hermes mcp test todoist  # Full connectivity + tool discovery test
```

### Pitfalls

- `args` MUST be a YAML list (`["-y", "@doist/todoist-mcp"]`), NOT a string (`'[]'`). String args break discovery.
- MCP tools are injected at gateway startup. After config changes, the gateway must restart (cannot restart from inside the gateway — use `hermes gateway stop` + `hermes gateway start` from external shell, or restart the systemd service).
- The `@doist/todoist-mcp` package uses npx — Node.js must be installed.

## Direct API Access (v1 Sync API)

When MCP tools aren't available in-session (pre-restart), or for bulk data extraction, use the REST/Sync API directly.

### Endpoint

```
POST https://api.todoist.com/api/v1/sync
Content-Type: application/x-www-form-urlencoded
Authorization: Bearer <token>
```

### Key Parameters

| Param | Value | Description |
|-------|-------|-------------|
| `sync_token` | `*` | Full sync (first call) |
| `resource_types` | `["items", "projects"]` | Limit payload (see below) |

### Critical: API v2 is DEAD

The old REST v2 API (`/rest/v2/tasks`) returns **410 Gone**. The Sync v9 API (`/API/v9/sync`) also returns 410. Only `/api/v1/sync` works.

### Field Name Changes (v9 → v1)

| Old (v9) | New (v1) |
|----------|----------|
| `items` | `items` (kept in sync responses, despite docs saying "tasks") |
| `is_completed` | `checked` (boolean) |
| `notes` | `comments` |
| `notifications` | `reminders` |

**IMPORTANT**: Despite the v1 docs saying `items → tasks`, the sync endpoint still returns the key as `items`. Always check both: `result.get('tasks', result.get('items', []))`.

### `due.date` Format Variants

The `due.date` field can be any of:
- `YYYY-MM-DD` (date only)
- `YYYY-MM-DDTHH:MM:SS` (datetime, no TZ)
- `YYYY-MM-DDTHH:MM:SSZ` (datetime UTC)

Parsing function:
```python
def parse_date(s):
    for fmt in ('%Y-%m-%dT%H:%M:%SZ', '%Y-%m-%dT%H:%M:%S', '%Y-%m-%d'):
        try:
            return datetime.strptime(s, fmt).date()
        except ValueError:
            continue
    return None
```

### Useful Resource Types

- `["items", "projects"]` — tasks + projects (most common)
- `["items"]` — tasks only
- `["all"]` — everything (heavier payload)

## Overdue Tasks Pattern

The API has no `filter=overdue` parameter. Fetch all active tasks, then filter client-side:

```python
today = date.today()
overdue = []
for t in items:
    if t.get('checked', False) or t.get('is_deleted', False):
        continue
    due = t.get('due')
    if not due or not due.get('date'):
        continue
    d = parse_date(due['date'])
    if d and d < today:
        overdue.append(t)
```

## Project Name Lookup

Always fetch projects alongside tasks for human-readable labels:

```python
projects = {p['id']: p.get('name', '?') for p in result.get('projects', [])}
proj_name = projects.get(task.get('project_id'), '?')
```

## References

See `references/todoist-v1-api-notes.md` for endpoint details and field mappings.
See `references/todoist-cron-jobs.md` for cron job JSON format for accountability bots.

## Multi-Profile Accountability Bot Pattern

Todoist integration shines when paired with a dedicated accountability persona running as a separate Hermes profile. The pattern:

1. **Separate profile**: `hermes profile create accountability --clone`
2. **Separate Telegram bot**: Create via BotFather, set token in profile's config.yaml under `telegram.bot_token` AND in `.env` as `TELEGRAM_BOT_TOKEN`
3. **MCP Todoist**: Add `mcp_servers.todoist` to the profile's `config.yaml` with the same API key
4. **Cross-profile awareness**: The accountability bot's cron jobs can use `session_search(profile='default')` to see what the user worked on in their main profile
5. **Cron jobs**: Morning briefing (8h), evening check-in (21h), weekly review (Sunday 10h)

### Pitfalls — Multi-Profile Setup

- **Telegram token conflict**: Each profile MUST have a unique bot token. If two profiles share a token, the second gateway will fail with "Telegram bot token already in use (PID ...)". The token must be set in BOTH `config.yaml` (`telegram.bot_token`) AND `.env` (`TELEGRAM_BOT_TOKEN`) — the .env takes precedence for the gateway runtime.
- **API server port conflict**: Each profile's API server needs a different port. Set `api_server.port: 8643` (etc.) in the profile's config.yaml. Default is 8642.
- **`hermes gateway restart --profile X` cannot run from inside the gateway**: Use `systemctl --user restart hermes-gateway-X` instead.
- **`hermes cron create --profile` CLI bug**: The `--profile` flag on the global `hermes` parser conflicts with the `cron create` subparser's positional `prompt` argument — the prompt gets eaten. **Workaround**: Write the cron `jobs.json` file directly to `~/.hermes/profiles/NAME/cron/jobs.json` and restart the gateway. See `references/todoist-cron-jobs.md` for the JSON format.
- **Gateway systemd service naming**: `hermes gateway install --profile mira` creates `hermes-gateway-mira.service`. Manage with `systemctl --user {start|stop|restart|status} hermes-gateway-mira`.

### Cross-Profile Session Visibility

The accountability bot reads the main profile's sessions via `session_search(profile='default')`. This gives visibility into:
- What the user worked on (tech sessions, coding, etc.)
- How long they worked
- Whether activity aligns with stated goals

Embed this in cron prompts: "Utilise session_search(profile='default') pour voir ce sur quoi l'utilisateur a travaillé."
