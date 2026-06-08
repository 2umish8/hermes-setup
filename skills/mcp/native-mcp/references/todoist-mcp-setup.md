# Todoist MCP Server Setup

## Package
- npm: `@doist/todoist-mcp`
- Transport: stdio via `npx -y @doist/todoist-mcp`
- Env var: `TODOIST_API_KEY` (personal token from Todoist Settings > Integrations)

## Config Pattern
```yaml
mcp_servers:
  todoist:
    command: npx
    args: ["-y", "@doist/todoist-mcp"]
    env:
      TODOIST_API_KEY: "<token>"
```

## Verification
```bash
hermes mcp list          # Check server appears
hermes mcp test todoist  # Full connectivity + tool discovery test (~50 tools)
```

## Known Tools (50+)
Core: `find-tasks`, `find-tasks-by-date`, `add-tasks`, `update-tasks`, `complete-tasks`, `reschedule-tasks`
Projects: `find-projects`, `add-projects`, `update-projects`, `find-sections`, `add-sections`
Goals: `find-goals`, `add-goals`, `update-goals`, `complete-goals`, `link-goal-tasks`
Comments: `find-comments`, `add-comments`, `update-comments`
Labels/Filters: `find-labels`, `add-labels`, `find-filters`, `add-filters`
Analytics: `get-productivity-stats`, `get-project-health`, `get-project-activity-stats`
Other: `search`, `fetch`, `fetch-object`, `delete-object`, `user-info`, `list-workspaces`

## Todoist API v1 Migration (2025-2026)
- **REST v2 is DEAD** (returns 410 Gone). Do NOT use `/rest/v2/` endpoints.
- **Sync v9 is DEAD** (also returns 410). Do NOT use `/API/v9/sync`.
- **New API:** `POST /api/v1/sync` — unified Sync + REST.
- **Auth:** `Authorization: Bearer <token>` header (was query param `?token=` in v9 sync).
- **Field renames:** `is_completed` → `checked` (bool), `notes` → `comments`, `notifications` → `reminders`.
- **IDs:** Now opaque strings (not numeric).
- **resource_types:** Docs say `items → tasks`, but the sync endpoint still returns the key as `items` and accepts `items` as resource_type. Use `["items", "projects"]` NOT `["tasks", "projects"]`.
- **Response key:** Always check both: `result.get('tasks', result.get('items', []))` — the sync response uses `items` despite the rename docs.

### Direct API Fallback (no MCP)
When MCP tools aren't injected yet (pre-restart), query Todoist directly:

```python
import urllib.request, urllib.parse, json, ssl
data = urllib.parse.urlencode({
    'sync_token': '*',
    'resource_types': '["items", "projects"]'  # NOT "tasks"
}).encode()
req = urllib.request.Request(
    'https://api.todoist.com/api/v1/sync',
    data=data,
    headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/x-www-form-urlencoded'}
)
resp = urllib.request.urlopen(req, context=ssl.create_default_context())
result = json.loads(resp.read())
tasks = result.get('tasks', result.get('items', []))  # check both keys
```

## Pitfalls
- `args` MUST be a YAML list (`["-y", "@doist/todoist-mcp"]`), NOT a string (`'[]'`). String args break discovery.
- Overdue filtering: the API has no `filter=overdue` param. Fetch all tasks, then filter client-side by `due.date < today`.
- `due.date` format varies: `YYYY-MM-DD`, `YYYY-MM-DDTHH:MM:SS`, or `YYYY-MM-DDTHH:MM:SSZ`. Parse all three.
- `is_recurring` is on the `due` object, not the task.
- Priority 1 = normal (P4 in UI), Priority 4 = urgent (P1 in UI). Inverted.
- MCP tools are injected at gateway startup. After config changes, restart the gateway.
- Cannot restart gateway from inside the gateway — use `systemctl --user restart hermes-gateway`.
