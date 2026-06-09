---
name: cpu-monitoring
description: "Automate CPU usage monitoring via a cron job. Detect spikes above a configurable threshold, wait a cooldown period, then dump recent logs and notify the user."
category: devops
---
## Overview
- Runs a small Bash script on a one‑minute cron schedule.
- When total CPU usage (sum of all cores) exceeds **≈300 %** it pauses, re‑checks, and if the spike persists it writes the last ten minutes of `journalctl` and the top process to a log file.
- The log is placed under `~/.hermes/logs/cpu-spike‑<timestamp>.log`.
- It sends a notification message to the active Hermes session with the path.

## Implementation
1. **Script** – `cpu_monitor.sh` placed in `~/.hermes/scripts/`.
2. **Cron** – `* * * * * ~/.hermes/scripts/cpu_monitor.sh`.
3. **Permissions** – `chmod +x ~/.hermes/scripts/cpu_monitor.sh`.

## Support Files
- `references/cpu-spike-monitor.md` – full script source.
- `references/cpu-monitoring.md` – brief description (kept in the skill for quick reference).

## Pitfalls & Tips
- Requires `ps`, `journalctl`, and `bc` to be available.
- The script writes under the user's home; ensure that directory exists.
- `flock` is omitted here for simplicity; if multiple instances could run concurrently, guard with a lock file.
- Threshold and cooldown are hard‑coded but can be made environment‑variables (e.g. `CPU_THRESHOLD`, `CPU_COOLDOWN`).
- Always use absolute paths – e.g. `$HOME/.hermes/logs` – to avoid permission issues in cron.
---