#!/usr/bin/env bash
# Monitor CPU usage and handle spikes
# This script will run once per minute via cron

# Calculate total CPU usage across all cores
cpu_total=$(ps -eo %cpu --no-headers | awk '{sum+=$1} END {print sum}')

# Function to check if CPU > 300%
check_spike() {
    if (( $(echo "$cpu_total > 300" | bc -l) )); then
        return 0
    else
        return 1
    fi
}

if check_spike; then
    # Wait 2 minutes
    sleep 120
    # Recalculate
    cpu_total=$(ps -eo %cpu --no-headers | awk '{sum+=$1} END {print sum}')
    if check_spike; then
        # Identify top process
        top_proc=$(ps aux --sort=-%cpu | head -1 | awk '{print $11 " (PID "$2")"}')
        logfile="/home/hermes/.hermes/logs/cpu-spike-$(date +%Y%m%d%H%M%S).log"
        mkdir -p "$(dirname "$logfile")"
        # Dump last 10 minutes of logs
        journalctl --no-pager --since "10 minutes ago" > "$logfile"
        # Notify the user (simple echo; cron will capture output)
        echo "CPU spike detected at $(date). Top process: $top_proc. Log saved to $logfile"
    fi
fi
