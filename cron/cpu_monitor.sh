#!/usr/bin/env bash
cpu=$(ps -eo pcpu | awk 'NR>1{sum+=$1} END{printf("%.1f", sum)}')
if [ $(echo "$cpu > 300" | bc -l) -eq 1 ]; then
  sleep 120
  cpu2=$(ps -eo pcpu | awk 'NR>1{sum+=$1} END{printf("%.1f", sum)}')
  if [ $(echo "$cpu2 > 300" | bc -l) -eq 1 ]; then
    NOW=$(date +%Y%m%d%H%M%S)
    LOGDIR=/home/hermes/.hermes/logs
    mkdir -p "$LOGDIR"
    LOGFILE=$LOGDIR/cpu-spike-$NOW.log
    TOPPROC=$(ps aux --sort=-%cpu | head -n 2 | tail -n 1)
    {
      echo "Timestamp: $(date)"
      echo "Top CPU process:"
      echo "$TOPPROC"
      echo
      echo "journalctl logs (last 10 minutes):"
      journalctl --since "10 minutes ago"
    } > "$LOGFILE"
    echo "CPU spike detected. Log saved to $LOGFILE"
  fi
fi