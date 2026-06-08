# CPU Monitor Script
This reference file contains the Bash script used by the **cpu-monitor** skill. The script is designed to be run once per minute via cron. It monitors total CPU usage and logs spikes.

```bash
#!/usr/bin/env bash
set -euo pipefail

THRESHOLD=300

# Calculate total CPU usage across all cores
cpu_total() {
    ps -eo pcpu --no-headers | awk '{sum+=$1} END{print sum}'
}

cpu=$(cpu_total)
# Use awk for numeric comparison
if awk -v a="$cpu" 'BEGIN{ exit (a> '$THRESHOLD'?0:1) }'; then
    sleep 120
    cpu=$(cpu_total)
    if awk -v a="$cpu" 'BEGIN{ exit (a> '$THRESHOLD'?0:1) }'; then
        top_proc=$(ps aux --sort=-%cpu | head -n 2 | tail -n 1)
        logfile="/home/hermes/.hermes/logs/cpu-spike-$(date +%Y%m%d%H%M%S).log"
        mkdir -p "$(dirname "$logfile")"
        {
            echo "=== CPU spike alert ==="
            echo "CPU usage: ${cpu}%"
            echo "Top process causing spike:"
            echo "${top_proc}"
            echo
            echo "--- Last 10 minutes of system logs ---"
            journalctl --since "10 minutes ago"
        } > "$logfile"
        echo "CPU spike detected. Log saved to $logfile"
    fi
fi
```

The script writes a log file under `/home/hermes/.hermes/logs/` with a timestamp.
