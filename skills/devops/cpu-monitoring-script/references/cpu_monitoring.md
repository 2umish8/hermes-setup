# CPU Monitoring Script Details

This reference documents the key behaviours of the `cpu_monitor.sh` script installed under `/home/hermes/cpu_monitor.sh`.

## Core Logic
1. **Threshold** – The script compares the total CPU utilisation (sum of %CPU across all processes) against `THRESHOLD` which defaults to **300 %**.
2. **Immediate Check** – If the utilisation is above the threshold, the script waits explicitly for **120 seconds** (2 minutes).
3. **Re‑check** – After the wait, it recalculates CPU usage. If it is still above the threshold, a log file is generated.
4. **Log Generation** – The log includes:
   - Timestamp
   - Total CPU usage
   - Top 10 CPU‑consuming processes (`ps aux --sort=-%cpu | head -n 10`)
   - The last 10 minutes of system journal (`journalctl --since "10 minutes ago"`).
5. **Persisting** – The log file is stored in `/home/hermes/.hermes/logs/` with a name pattern `cpu-spike-YYYYMMDDHHMMSS.log`.
6. **Notification** – A syslog entry is written via `logger -t cpu_spike` so system monitoring tools or administrators can catch the spike.

## Typical Usage Path
1. Place script in `/home/hermes/cpu_monitor.sh`.
2. `chmod +x` it.
3. Add a per‑user cron line that runs it every minute. Example:
   ```bash
   crontab -l | (cat; echo "* * * * * hermes /home/hermes/cpu_monitor.sh >> /dev/null 2>&1") | crontab -
   ```
4. Verify operation by temporarily raising the threshold or creating load.

---
