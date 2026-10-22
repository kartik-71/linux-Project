
#!/bin/bash

# Log Monitoring Script for Ubuntu

LOG_FILE="/var/log/auth.log"
SYS_LOG="/var/log/syslog"
REPORT="log_monitor_report.txt"

echo "======================================"
echo "       UBUNTU LOG MONITOR"
echo "======================================"

echo "Log Monitoring Report - $(date)" > "$REPORT"
echo "======================================" >> "$REPORT"

# Check failed SSH login attempts
echo -e "\n[Failed SSH Login Attempts]" | tee -a "$REPORT"

if [ -r "$LOG_FILE" ]; then
    grep -iE "Failed password|authentication failure" "$LOG_FILE" \
        | tail -n 20 | tee -a "$REPORT"
else
    echo "Authentication log unavailable." | tee -a "$REPORT"
fi

# Check system errors
echo -e "\n[System Errors]" | tee -a "$REPORT"

if [ -r "$SYS_LOG" ]; then
    grep -iE "error|critical|failed" "$SYS_LOG" \
        | tail -n 20 | tee -a "$REPORT"
else
    echo "System log unavailable." | tee -a "$REPORT"
fi

# Finish report
echo -e "\nMonitoring completed at $(date)" | tee -a "$REPORT"

echo "======================================"
echo "Monitoring completed."
echo "Report saved to: $REPORT"
echo "======================================"
