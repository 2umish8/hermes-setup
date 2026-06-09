# CPU Monitoring Script Reference

This reference contains a concise explanation of the Bash script `cpu_watchdog.sh` that performs rolling CPU spike detection. It is intended for quick on‑the‑fly review by other agents and for future maintenance.

## Script Overview
1. **Calculate total CPU usage** – the script runs `ps -eo pcpu` and `awk` to sum all `%CPU` values across processes. The resulting number represents total CPU load percentage across all cores.
2. **Threshold check** – if the sum exceeds `THRESHOLD` (default 300 %) the spike is considered significant.
3. **Wait period** – the script sleeps for 120 s (configurable via `sleep <seconds>`). This ensures the spike is sustained, not an isolated spike.
4. **Re‑check** – the CPU is measured again after the wait period.
5. **Logging** – if spike persists:
   - Create `/home/hermes/.hermes/logs` if it does not exist.
   - Generate a timestamped log file `cpu-spike-<YYYYMMDDHHMMSS>.log`.
   - Dump the last 10 minutes of `journalctl` output into that file.
   - Append the top‑CPU‑consuming process (obtained with `ps aux --sort=-%cpu | head -n 2 | tail -n 1`) to the log.
6. **Syslog notification** – the script writes a concise entry to syslog using `logger -p user.notice`.

## Log Format
```

CPU spike detected. Dumping last 10 minutes of logs to /home/hermes/.hermes/logs/cpu-spike-<timestamp>.log
Top process causing spike: <PID> <COMMAND>

```

## Customization
- `THRESHOLD` – change the percentage that triggers the check.
- `sleep <seconds>` – alter the confirmation wait period.
- Log directory and filename – can be changed by editing the script.
- Logger tag – modify the `-p` flag to group syslog entries.

---
