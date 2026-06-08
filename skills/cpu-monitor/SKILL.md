---
name: cpu-monitor
description: Automates CPU spike monitoring with a cron job that logs spikes and notifies via Hermes. Provides a Bash script, cron setup, and optional notification handling.
category: system-ops
---

## Overview
This umbrella skill automates monitoring of system CPU usage. When total CPU usage across all cores exceeds **300 %** the script will:
1. Wait 2 minutes (to confirm the spike).
2. If the spike persists, dump the last 10 minutes of `journalctl` output to a timestamped log file.
3. Append the top CPU‑intensive process.
4. Notify the user (via the Hermes notification system).

The script is intended to be run as a cron job once per minute.

## How to Use
1. **Install the script** – Copy the script into `./scripts/check_cpu.sh` and make it executable.
2. **Add cron entry** – Add the following line to the user’s crontab:
   ```
   * * * * * /path/to/scripts/check_cpu.sh >> /dev/null 2>&1
   ```
   Replace `/path/to` with the absolute location of the script.
3. **Configure notifications** – In the script’s last line (the `hermes notify` command) replace the placeholder with the desired notification path or command.

## References
- cron_setup.md
- `ps -eo pcpu` – Calculates total CPU usage.
- `journalctl --since "10 minutes ago"` – Retrieves recent logs.
- `ps aux --sort=-%cpu | head -n 2` – Shows the process most consuming CPU.
Reference script: references/cpu_monitor_script.sh.md
references/cron_setup.md

* The script outputs a notification via `hermes notify` when a sustained CPU spike is detected. This informs the user immediately without checking log files.
` – contains the full Bash script used in this skill.

## Script
The script is stored in `/home/hermes/.hermes/scripts/cpu_monitor.sh`.
---