---
name: cpu-monitoring-script
description: Automate CPU spike monitoring via a Bash script run by cron, with threshold, wait, log capture, and top process identification, designed to avoid blocking long jobs and to follow cron best practices.
category: devops
---

# CPU Spike Monitoring Script

## Overview
Many production systems benefit from automated detection of sustained CPU overload. This skill provides a portable Bash script that
1. Reads total CPU usage across all cores.
2. If usage exceeds a configurable threshold, waits a defined period to confirm the spike.
3. On confirmation, logs telemetry (TOP processes, recent journal logs) to a timestamped file and emits a syslog notification.
4. Can be scheduled with a cron entry (e.g., every minute, or any user‑selected frequency).  

The script uses common Linux utilities only (`ps`, `awk`, `journalctl`, `logger`) and so is compatible with most distributions.

## Usage
1. **Create the script** – e.g., `/home/hermes/.hermes/cron/scripts/cpu_watchdog.sh`.
   ```bash
   #!/usr/bin/env bash
   THRESHOLD=300
   ... etc ...
   ```
2. **Make it executable**.
   ```bash
   chmod +x /home/hermes/cpu_monitor.sh
   ```
3. **Add a cron line** (per‑user or system).  
   Example per‑user:
   ```bash
   crontab -l | (cat; echo "* * * * * hermes /home/hermes/cpu_monitor.sh >> /dev/null 2>&1") | crontab -
   ```
4. **Confirm it works** – run script manually to ensure it logs when CPU exceeds threshold.

## Customization
- Change `THRESHOLD` to the percentage that triggers the spike.
- Adjust `sleep 120` to a different wait time.
- Redirect output to a different file/dir.
- Modify logger tag (`cpu_spike`).

## References
See the `references/cpu_monitoring.md` file for details on the script implementation and a concise recap of the log format and fields.

---
