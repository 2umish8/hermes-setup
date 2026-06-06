# Dashboard Backend — `server.py`

Full FastAPI implementation for the Hermes VPS Dashboard.

## File Location

`~/.hermes/dashboard/server.py`

## Key Components

### Routes

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/stats` | System disk, RAM, uptime, load (HTMX auto-refresh 30s) |
| GET | `/api/jobs` | All cron jobs with enriched display fields |
| GET | `/api/jobs/{id}` | Single job detail + run logs |
| POST | `/api/jobs/{id}/toggle` | Pause/resume a job |
| POST | `/api/jobs/{id}/run` | Trigger immediate execution via `hermes cron run` |
| DELETE | `/api/jobs/{id}` | Remove job + logs |
| POST | `/api/jobs/{id}/edit` | Update name/schedule/prompt |
| POST | `/api/jobs` | Create new job |
| GET | `/` | Serve `index.html` frontend |

### System Stats Parsing

```python
# disk — df -h, last line columns:
# Filesystem Size Used Avail Use% Mounted
disk = run_cmd(["df", "-h", "/"]).split("\n")[-1].split()
# [2]=used, [3]=avail, [4]=use%

# ram — free -h columns:
# total used free shared buff/cache available
mem_line = run_cmd(["free", "-h"]).split("\n")[1].split()
# [1]=total, [2]=used
# ⚠ mem[4] is "shared", NOT usage% — see pitfall below
```

### `free -h` Column Bug (discovered this session)

The `ram_pct` returned **"4.7Mi"** (the "shared" column value) instead of the actual usage percentage.

**Root cause:** `free -h` output columns are:

```
              total        used        free      shared  buff/cache   available
Mem:           3.7Gi       1.0Gi       646Mi       4.7Mi       2.4Gi       2.7Gi
```

Index 4 is `shared` (4.7Mi), not the usage percentage.

**Fix:** Parse bytes for accurate percentage:
```python
mem_bytes = run_cmd(["free", "-b"]).split("\n")[1].split()
total, used = int(mem_bytes[1]), int(mem_bytes[2])
ram_pct = f"{round(used / total * 100)}%"
```

### Cron Job CRUD

Reading `jobs.json`:
```python
CRON_JOBS = Path.home() / ".hermes" / "cron" / "jobs.json"
def load_jobs() -> list[dict]:
    return json.loads(CRON_JOBS.read_text()).get("jobs", [])
```

Writing back — must preserve indent=2 to match Hermes' own format:
```python
CRON_JOBS.write_text(json.dumps({"jobs": jobs, "updated_at": iso}, indent=2))
```

### Job ID Format

Hermes uses 12-char lowercase hex IDs (from md5). The create endpoint mirrors this:
```python
import hashlib, time
raw = name + str(time.time())
job_id = hashlib.md5(raw.encode()).hexdigest()[:12]
```

### Output Logs

`~/.hermes/cron/output/{job_id}/*.md` — one file per run, named `YYYY-MM-DD_HH-MM-SS.md`. Files are markdown with `# Cron Job: {name}` header, prompt, and response sections.

## Service File

```
~/.config/systemd/user/hermes-dashboard.service

[Service]
ExecStart=%h/.hermes/dashboard/start.sh
Restart=on-failure
RestartSec=5
```

No `Type=forking` — standard `Type=simple` since uvicorn stays in foreground.