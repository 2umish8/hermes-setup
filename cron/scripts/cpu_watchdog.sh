#!/usr/bin/env bash
THRESHOLD=300

get_cpu() {
    ps aux | awk 'NR>1 {sum += $3} END {print sum}'
}

# 1. Initial check
usage=$(get_cpu)
if (( $(echo "$usage > $THRESHOLD" | bc -l) )); then
    # 2. Wait 2 minutes
    sleep 120
    
    # 3. Re-check
    usage_second=$(get_cpu)
    if (( $(echo "$usage_second > $THRESHOLD" | bc -l) )); then
        # 4. Spike confirmed - Dump Logs
        LOG_DIR="/home/hermes/.hermes/logs"
        mkdir -p "$LOG_DIR"
        TIMESTAMP=$(date +%Y%m%d%H%M%S)
        LOG_PATH="$LOG_DIR/cpu-spike-$TIMESTAMP.log"
        
        journalctl --since "10 minutes ago" > "$LOG_PATH"
        
        echo -e "\n\n--- Top CPU Process ---" >> "$LOG_PATH"
        ps aux --sort=-%cpu | head -n 2 | tail -n 1 >> "$LOG_PATH"
        
        echo "CPU spike detected: $usage_second%. Log created: $LOG_PATH"
    fi
fi
