#!/usr/bin/env bash
# CPU watchdog script
# Check total CPU usage across all cores.
get_total_cpu() {
  awk 'NR>1{sum+=$1} END {print sum}' <(ps -eo %cpu --no-headers)
}

cpu_total=$(get_total_cpu)
if (( $(echo "$cpu_total > 300" | bc -l) )); then
  sleep 120
  cpu_total2=$(get_total_cpu)
  if (( $(echo "$cpu_total2 > 300" | bc -l) )); then
    logfile="/home/hermes/.hermes/logs/cpu-spike-$(date +%Y%m%d%H%M%S).log"
    mkdir -p "$(dirname "$logfile")"
    {
      echo "CPU spike detected at $(date)"
      echo "Total CPU: ${cpu_total2}%%"
      echo "Top process:"
      ps aux --sort=-%cpu | head -n 2
      echo "Journal logs last 10 minutes:"
      journalctl --since "10 minutes ago"
    } > "$logfile"
    # Notify via Hermes CLI
    hermes notify "CPU spike detected. Log at $logfile"
  fi
fi
