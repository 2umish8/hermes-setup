#!/usr/bin/env bash
set -e
TIMESTAMP=$(date +%Y%m%d%H%M%S)
LOGDIR="$HOME/.hermes/.hermes/logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/cpu-spike-$TIMESTAMP.log"
# total CPU usage
CPU=$(ps aux | awk '{s+=$3} END {print s}')
# threshold and delay
THRESHOLD=300
DELAY=120
if (( $(echo "$CPU > $THRESHOLD" | bc -l) )); then
  sleep $DELAY
  CPU2=$(ps aux | awk '{s+=$3} END {print s}')
  if (( $(echo "$CPU2 > $THRESHOLD" | bc -l) )); then
    TOP=$(ps aux --sort=-%cpu | head -n 2)
    JOURNAL=$(journalctl --since="10 minutes ago")
    echo "CPU Spike Detected: $CPU2%" > "$LOGFILE"
    echo -e "\nTop Process:\n$TOP" >> "$LOGFILE"
    echo -e "\n--- Journal Logs (Last 10m) ---\n$JOURNAL" >> "$LOGFILE"
    echo "CPU spike: $CPU2% logged to $LOGFILE"
  fi
fi
