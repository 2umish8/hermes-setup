---
name: cpu-monitoring
description: "Automate CPU usage monitoring via a cron job. Detect spikes above a configurable threshold, wait a cooldown period, then dump recent logs and notify the user."
category: devops
---
## Overview
- Designed for Linux systems with `ps`, `journalctl`, and `crontab`.
## Implementation Steps
- **Script creation** – Build Bash script `monitor-cpu.sh` with absolute paths, `flock` for concurrency.
- **Make executable** – `chmod +x $HOME/.hermes/.hermes/scripts/monitor-cpu.sh`.
- **Cron entry** – Add `* * * * * $HOME/.hermes/.hermes/scripts/monitor-cpu.sh` to crontab.

## Reference
- Full Bash script is stored in `references/cpu-spike-monitor.sh`. The executable script resides at `$HOME/.hermes/.hermes/scripts/monitor-cpu.sh`..
- Script path: `$HOME/.hermes/.hermes/scripts/monitor-cpu.sh`.

1. **Script creation** – Build Bash script using lock file, `flock`, absolute paths.
2. **Make executable** – `chmod +x ~/.hermes/.hermes/scripts/monitor-cpu.sh`.
3. **Cron entry** – Add `* * * * * ~/.hermes/.hermes/scripts/monitor-cpu.sh` to crontab.

## Pitfalls & Tips
- Ensure `journalctl` and `ps` are present; otherwise, the script will fail.
- The script writes logs under the user’s home; make sure this path exists or it will error.
- `flock` is used for concurrency control; if unavailable, consider a background guard.
- Keep threshold (300 %) and wait time (120 s) configurable via env vars for flexibility.
---