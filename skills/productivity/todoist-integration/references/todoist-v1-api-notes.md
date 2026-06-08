# Todoist v1 Sync API — Session Notes

## Working Endpoint (as of June 2026)

```
POST https://api.todoist.com/api/v1/sync
Authorization: Bearer <token>
Content-Type: application/x-www-form-urlencoded

Body: sync_token=*&resource_types=["items","projects"]
```

## Confirmed Dead Endpoints

- `GET /rest/v2/tasks` → 410 Gone
- `POST /API/v9/sync` → 410 Gone
- `GET /rest/v2/tasks?filter=overdue` → 410 Gone

## Response Structure (v1 sync, full sync)

Top-level keys returned: `items`, `projects`, `sections`, `labels`, `filters`, `completed_info`, `user`, `stats`, `sync_token`, etc.

## `items` Array — Key Fields

```
id, content, description, project_id, section_id, parent_id,
due (object), priority (1-4), checked (bool), is_deleted (bool),
is_collapsed, child_order, day_order, labels (list),
added_at, completed_at, completed_by_uid,
is_recurring (nested in due), deadline, duration, goal_ids
```

## `due` Object

```
{
  "date": "2026-06-06" | "2026-05-17T17:00:00" | "2026-05-22T17:00:00Z",
  "is_recurring": true|false,
  "lang": "en"|"fr",
  "string": "every day at 17:00" | "tous 8",
  "timezone": null | "Europe/Paris"
}
```

## Priority Mapping

- API priority 1 = UI P4 (default/low)
- API priority 2 = UI P3
- API priority 3 = UI P2
- API priority 4 = UI P1 (highest)

**Display tip**: If `priority > 1`, show as `⚡P{priority}`.

## MCP Tool: find-tasks-by-date

The MCP server exposes `find-tasks-by-date` which accepts:
- `startDate`: YYYY-MM-DD or 'today'
- `daysCount`: 1-30
- `overdueOption`: 'include-overdue' | 'overdue-only' | 'exclude-overdue'
- `responsibleUser`: filter by assignee

This is the cleanest way to get overdue tasks when MCP tools are available in-session.
