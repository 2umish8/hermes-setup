---
name: Monitor CPU Spike
category: system-monitor
description: Monitor CPU usage and log spikes, notifying user.
---

# Monitor CPU Spike

This skill creates a cron job that checks total CPU usage every minute. If usage exceeds the threshold (300%) it waits 2 minutes to confirm, then logs last 10 minutes of system logs plus top process information, storing a file under `~/.hermes/logs` and optionally emailing the user.

## Procedure

1. Create script `cpu_spike_monitor.sh` in `~/.hermes/scripts` (see references/script.md).
2. Make it executable.
3. Add a cron line `* * * * * /home/hermes/scripts/cpu_spike_monitor.sh >> /dev/null 2>&1`.

## Tips
- Adjust `THRESHOLD` or `sleep` if your system uses many cores.
- Ensure `mail` command is available for email alerts; otherwise, rely on stdout.
- The script uses `ps` and `journalctl`; if unavailable, install the packages.

## Reference

- `cpu_spike_monitor.sh` – script logic (see references/script.md).
