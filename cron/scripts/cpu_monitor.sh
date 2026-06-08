#!/usr/bin/env bash
THRESHOLD=300

# Total CPU across all cores
USAGE=$(ps aux --no-headers | awk '{sum += $3} END {print sum}')

# Use bc for float comparison, or just integer truncation if preferred
if (( $(echo "$USAGE > $THRESHOLD" | bc -l) )); then
    sleep 120
    USAGE_AGAIN=$(ps aux --no-headers | awk '{sum += $3} END {print sum}')
    
    if (( $(echo "$USAGE_AGAIN > $THRESHOLD" | bc -l) )); then
        TIMESTAMP=$(date +%Y%m%d%H%M%S)
        LOGFILE="/home/hermes/.hermes/logs/cpu-spike-${TIMESTAMP}.log"
        
        echo "CPU Spike Report - ${TIMESTAMP}" > "$LOGFILE"
        echo "Total CPU Usage: ${USAGE_AGAIN}%" >> "$LOGFILE"
        echo -e "\nTop Processes:\n" >> "$LOGFILE"
        ps aux --sort=-%cpu | head -n 10 >> "$LOGFILE"
        echo -e "\nJournal Logs (last 10 mins):\n" >> "$LOGFILE"
        journalctl --since "10 minutes ago" >> "$LOGFILE"
        
        # Log to syslog/system, also echo for cron capture
        logger -t cpu_spike "CPU spike detected (${USAGE_AGAIN}%). Log: ${LOGFILE}"
        echo "CPU spike detected (${USAGE_AGAIN}%). Log: ${LOGFILE}"
    fi
fi
