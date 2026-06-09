#!/usr/bin/env bash
set -euo pipefail

# Calculate total CPU usage (percentage) across all processes
cpu=$(ps -eo pcpu --no-headers | awk '{sum+=$1} END {print sum}')
if (( $(echo "$cpu > 300" | bc -l) )); then
  sleep 120
  cpu2=$(ps -eo pcpu --no-headers | awk '{sum+=$1} END {print sum}')
  if (( $(echo "$cpu2 > 300" | bc -l) )); then
    topprocess=$(ps aux --sort=-%cpu | awk 'NR==2{print $0}')
    logs=$(journalctl --since "10 minutes ago" -q)
    logdir="/home/hermes/.hermes/logs"
    mkdir -p "$logdir"
    logfile=$logdir/cpu-spike-$(date +%Y%m%d%H%M%S).log
    {
      echo "Top process:"
      echo "$topprocess"
      echo
      echo "Last 10 minutes logs:"
      echo "$logs"
    } > "$logfile"
    echo "CPU spike detected. Log saved at $logfile" | hermes notify
    exit 0
  fi
fi
printf "[SILENT]" >/dev/null
