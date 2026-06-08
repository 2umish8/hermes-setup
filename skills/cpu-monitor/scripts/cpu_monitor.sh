#!/bin/bash
# CPU monitor script
cpu_usage=$(ps aux | awk 'NR>1{sum += $3} END {print sum}')
threshold=300
sleep_interval=120
if (( $(echo "$cpu_usage > $threshold" | bc -l) )); then
  sleep $sleep_interval
  cpu_usage=$(ps aux | awk 'NR>1{sum += $3} END {print sum}')
  if (( $(echo "$cpu_usage > $threshold" | bc -l) )); then
    logfile="/home/hermes/.hermes/logs/cpu-spike-$(date +%Y%m%d%H%M%S).log"
    mkdir -p "$(dirname "$logfile")"
    top_proc=$(ps aux --sort=-%cpu | head -n 2)
    journal_logs=$(journalctl --since '10 minutes ago')
    echo "CPU Usage Spike Detected: $cpu_usage%" > "$logfile"
    echo "Top Process:" >> "$logfile"
    echo "$top_proc" >> "$logfile"
    echo "--- Journal Logs (Last 10m) ---" >> "$logfile"
    echo "$journal_logs" >> "$logfile"
    echo "ALERT: CPU spike detected ($cpu_usage% ). Logs saved to $logfile. Top process:" >&2
    echo "$top_proc" >&2
  fi
fi
