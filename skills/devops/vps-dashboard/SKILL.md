---
name: vps-dashboard
description: "Build web control panels exposing Hermes internals — FastAPI + HTMX dashboards for cron visibility, system monitoring, and VPS management"
tags: [dashboard, web, fastapi, htmx, cron, monitoring, systemd]
---

# VPS Dashboard

Build lightweight web dashboards that expose Hermes' internal systems (cron jobs, system stats) as a visual control panel. Designed to complement Telegram as the primary control surface — browser for deep visibility, Telegram for quick actions.

## When to Build This

- User wants **visibility** into cron jobs and system state beyond what Telegram messages provide
- User wants to **self-modify** the dashboard (HTML/JS in code-server or similar IDE)
- User wants a **live dashboard** with auto-refresh that doesn't require an agent session
- The cron system is already in use and needs a human-friendly frontend

## Architecture Pattern

```
~/.hermes/dashboard/
├── server.py       # FastAPI backend (REST API)
├── index.html      # Single-page frontend (HTMX, dark theme)
├── requirements.txt
├── start.sh
└── .venv/          # Isolated Python venv

~/.config/systemd/user/hermes-dashboard.service
```

### Backend (FastAPI)
- Lightweight REST layer that reads from `~/.hermes/cron/jobs.json` directly
- Endpoints: `/api/stats` (system health), `/api/jobs` (cron list), `/api/jobs/{id}` (detail), toggle/run/delete/edit/create
- Serves the frontend HTML at `/`
- Auto-refresh via HTMX polling (30s stats, 15s jobs)

### Frontend (HTMX Single Page)
- No build step, no framework — just HTML + CSS + HTMX loaded from CDN
- Dark theme, responsive (mobile-friendly columns)
- Actions done via `fetch()` + manual DOM manipulation
- Key elements: stats cards, jobs table with status badges, detail modal, create form

### Service Setup (systemd user)
```bash
systemctl --user daemon-reload
systemctl --user enable hermes-dashboard.service
systemctl --user start hermes-dashboard.service
```

## Port Convention

| Service | Port |
|---------|------|
| code-server (VS Code) | 8080 |
| Mowtif / Next.js apps | 3000 |
| Hermes Dashboard | **3333** |

Check conflicts before picking: `ss -tlnp | grep -E ':(3333|5678)'`

## Cron Data Model

`~/.hermes/cron/jobs.json` is a flat JSON file (not SQLite). Structure:

```json
{
  "jobs": [
    {
      "id": "540da09011aa",
      "name": "my-job",
      "prompt": "# Backup script",
      "schedule": {"kind": "cron", "expr": "0 */12 * * *", "display": "0 */12 * * *"},
      "repeat": {"times": null, "completed": 1},
      "enabled": true,
      "state": "scheduled",
      "next_run_at": "2026-06-06T12:00:00+00:00",
      "last_run_at": "2026-06-06T00:00:58+00:00",
      "last_status": "ok",
      "deliver": "origin",
      "origin": {"platform": "telegram", "chat_id": "...", "chat_name": "...", "thread_id": null},
      "workdir": "/home/hermes/project"
    }
  ]
}
```

Output logs live in `~/.hermes/cron/output/{job_id}/*.md` — one file per run.

## Pitfalls

### `free -h` column parsing

`free -h` output columns are: **total, used, free, shared, buff/cache, available**.

Index 4 is **"shared"**, NOT the usage percentage. You must calculate percentage manually:
```python
# WRONG — returns "shared" column:
mem_raw = run_cmd(["free", "-h"]).split("\n")[1].split()
ram_pct = mem_raw[4]  # ← This is "shared", not %

# RIGHT — calculate from bytes:
mem_bytes = run_cmd(["free", "-b"]).split("\n")[1].split()
total = int(mem_bytes[1])
used = int(mem_bytes[2])
ram_pct = f"{round(used / total * 100)}%"
```

### PEP 668 system Python

On newer Debian/Ubuntu, system Python is PEP 668 protected. Create a venv:
```bash
uv venv ~/.hermes/dashboard/.venv --python 3.11
uv pip install --python ~/.hermes/dashboard/.venv/bin/python fastapi uvicorn
```

### uv installs are slow on first run

Network-bound uv/pip installs can exceed the foreground timeout guard. Use `background=true` with `notify_on_complete=true` for dependency installation.

### jobs.json formatting

`scheduler.py` writes `jobs.json` with `indent=2`. When you `save_jobs()` in the dashboard, match the same indentation to avoid dirty diffs in git-tracked setups.

## Related Skills

- `vps-autonomy` — VPS config, YOLO mode, git backup
- `hermes-agent` — CLI setup, config, provider management

## References

- `references/server-py.md` — full dashboard backend implementation
- `references/index-html.md` — full frontend implementation (HTMX template)