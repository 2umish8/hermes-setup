## CPU Spike Monitoring Best Practices

- Use `ps -eo pcpu --no-headers` to sum CPU usage without including the header line.
- Sleep for *exactly* 2 minutes (`sleep 120`) before re‑checking the total to give transient spikes a chance to subside.
- Validate the second check with the same `--no-headers` flag to avoid double‑counting headers.
- Log the last 10 minutes of system journal with `journalctl --since "-10min"` and **not** `--since "10min"` (negated relative).
- Capture the top‑CPU process with `ps aux --sort=-%cpu | head -n 2` and append it to the log.
- Ensure the monitoring script is executable (`chmod +x`) and placed under `~/.hermes/scripts`.
- Add a single minute cron entry: `* * * * * /home/hermes/.hermes/scripts/cpu-monitor.sh >> /dev/null 2>&1`.
- Avoid duplicate crontab entries – when installing, remove any pre‑existing lines that call the script.
- The script should exit silently when the CPU usage is below the threshold.
