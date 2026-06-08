#!/usr/bin/env bash
SCRIPT_DIR="/home/hermes/.hermes/scripts"
LOG_DIR="/home/hermes/.hermes/logs"
mkdir -p "$LOG_DIR"
now=$(date +%Y%m%d%H%M%S)
# Get total CPU usage across all processes
cpu_total=$(ps -A -o %cpu= | awk '{s+=$1} END{print s}')
spike_limit=300
if (( $(echo "$cpu_total > $spike_limit" | bc -l) )); then
  sleep 120
  cpu_check=$(ps -A -o %cpu= | awk '{s+=$1} END{print s}')
  if (( $(echo "$cpu_check > $spike_limit" | bc -l) )); then
    log_file="$LOG_DIR/cpu-spike-${now}.log"
    echo "CPU spike detected: $cpu_check%" > "$log_file"
    echo "Top process causing spike:" >> "$log_file"
    ps aux --sort=-%cpu | head -n 5 >> "$log_file"
    echo "Journalctl last 10 minutes:" >> "$log_file"
    journalctl --since "10 minutes ago" >> "$log_file"
    echo "CPU spike detected. Total CPU usage $cpu_check%.
Log saved to $log_file.
Top process: $(ps aux --sort=-%cpu | head -n 1)"
  fi
fi