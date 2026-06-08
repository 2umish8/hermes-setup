#!/usr/bin/env bash

# CPU spike monitoring script
# Author: Hermes Agent auto-generated
# Description: Monitors total CPU usage, waits 2 minutes if >300%, dumps last 10 minutes of journalctl logs and notifies the user.

# Compute total CPU usage
CPU_SUM=$(ps aux --sort=-%cpu | awk '{sum+=$3} END{print sum}')

THRESHOLD=300
if (( $(awk -v cpu="$CPU_SUM" 'BEGIN{print (cpu > ''$THRESHOLD'')}') )); then
  echo "CPU usage high: $CPU_SUM%, waiting 2 minutes..."
  sleep 120
  CPU_SUM2=$(ps aux --sort=-%cpu | awk '{sum+=$3} END{print sum}')
  if (( $(awk -v cpu="$CPU_SUM2" 'BEGIN{print (cpu > ''$THRESHOLD'')}') )); then
    NOW=$(date +%Y%m%d%H%M%S)
    LOGDIR=/home/hermes/.hermes/logs
    LOGFILE="$LOGDIR/cpu-spike-$NOW.log"
    mkdir -p "$LOGDIR"
    TOPPROC=$(ps aux --sort=-%cpu | head -n 2 | tail -n 1)
    journalctl --since='10 minutes ago' --output=short > "$LOGFILE"
    echo "CPU spike detected. Top process: $TOPPROC. Log saved to $LOGFILE"
  else
    echo "[SILENT]"
  fi
else
  echo "[SILENT]"
fi
