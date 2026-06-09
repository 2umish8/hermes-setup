# CPU Spike Monitoring Script

This is the Bash script used by the **cpu-monitor** skill. It checks total system CPU usage, waits 2 minutes if the total exceeds **300 %**, rechecks, and if the spike persists writes a log of the last 10 minutes of `journalctl` along with the top CPU‑intensive process.

```bash
#!/usr/bin/env bash
# CPU Spike Monitor
# If total CPU usage across all cores exceeds 300%, wait 2 minutes (to confirm the spike), re‑check and, if the spike persists, dump the last 10 minutes of journalctl logs along with the top CPU process to ~/.hermes/logs/cpu_spike-<TIMESTAMP>.log.

set -euo pipefail

# Function to aggregate total CPU usage
get_total_cpu() {
    ps -eo pcpu --no-headers | awk '{sum+=$1} END {print sum}'
}

LOG_DIR="$HOME/.hermes/logs"
mkdir -p "$LOG_DIR"

cpu_total=$(get_total_cpu)

if [ "$(echo "$cpu_total > 300" | bc -l)" -ne 0 ]; then
    echo "CPU usage $cpu_total% exceeds threshold at $(date). Waiting 2 minutes..."
    sleep 120
    cpu_total=$(get_total_cpu)
    if [ "$(echo "$cpu_total > 300" | bc -l)" -ne 0 ]; then
        echo "CPU usage still $cpu_total% after wait. Dumping logs..."
        log_file="$LOG_DIR/cpu-spike-$(date +%Y%m%d%H%M%S).log"
        {
            echo "CPU spike detected at $(date)"
            echo "Top process causing spike:"
            ps aux --sort=-%cpu | head -n 2 | tail -n 1
            echo
            echo "--- Last 10 minutes of journalctl logs ---"
            journalctl --since "10 minutes ago"
        } > "$log_file"
        echo "CPU spike logged to $log_file"
        hermes notify "CPU spike detected, log stored at $log_file"
    else
        echo "CPU usage returned to normal ($cpu_total%) after 2 minute wait at $(date)."
    fi
fi
```

**Location**: `~/.hermes/scripts/cpu_monitor.sh`

Make sure the script is executable (`chmod +x ~/.hermes/scripts/cpu_monitor.sh`).
