# Cron Setup for CPU Monitor

To run the CPU monitor script once per minute, add the following line to your user crontab:

```
* * * * * /home/hermes/.hermes/skills/cpu-monitor/scripts/cpu_monitor.sh >> /home/hermes/.hermes/logs/cpu_monitor_check.log 2>&1
```

Replace the path with the correct absolute path if you moved the skill. The script will log to `~/.hermes/logs/cpu_monitor_check.log`. You can also redirect the output to `/dev/null` if you want silence, but the internal script prints alerts to `stderr` for immediate visibility.

## Notes
- The script requires `bc` for floating‑point comparison. If `bc` is not installed, install it (`apt install bc`).
- The script assumes `journalctl` is available for log extraction.
- Ensure the script has execution permissions (`chmod +x script_path`).
