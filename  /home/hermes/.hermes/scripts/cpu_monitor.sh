#!/usr/bin/env bash
# CPU spike monitor script
# Check current CPU usage in percentage across all cores
usage=$(ps -A -o %cpu | awk 'NR>1{sum+=$1} END{print sum}')
# Convert to integer for comparison; truncate decimal
usage_int=${usage%.*}
# Threshold check
if (( usage_int > 300 )); then
  echo "CPU usage currently $usage%, exceeding threshold. Waiting 2 minutes..."
  sleep 120
  # Recheck
  usage2=$(ps -A -o %cpu | awk 'NR>1{sum+=$1} END{print sum}')
  usage2_int=${usage2%.*}
  if (( usage2_int > 300 )); then
    logfile="/home/hermes/.hermes/logs/cpu-spike-$(date +%Y%m%d%H%M%S).log"
    mkdir -p /home/hermes/.hermes/logs
    echo "===== CPU Spike Log: $(date) =====" > "$logfile"
    echo "CPU usage: $usage2%" >> "$logfile"
    echo "Top process:" >> "$logfile"
    ps aux --sort=-%cpu | head -n 2 >> "$logfile"
    echo "=== Journalctl (last 10 mins) ===" >> "$logfile"
    journalctl --since='10 minutes ago' >> "$logfile" 2>/dev/null
    echo "CPU spike detected. Log written to $logfile"
    echo "CPU spike detected. Log location: $logfile"
  else
    echo "CPU usage back to normal after wait: $usage2%"
  fi
else
  echo "CPU usage normal: $usage%"
fi
