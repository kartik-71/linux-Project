

#!/bin/bash

# Ubuntu Server Health Check Script

REPORT="health_report_$(date +%Y-%m-%d_%H-%M-%S).txt"

# Display and save output to a report file
exec > >(tee -a "$REPORT") 2>&1

echo "=========================================="
echo "       UBUNTU SERVER HEALTH CHECK"
echo "=========================================="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo

# 1. System Uptime
echo "----- SYSTEM UPTIME -----"
uptime
echo

# 2. CPU Usage
echo "----- CPU USAGE -----"
top -bn1 | grep "Cpu(s)" || mpstat 1 1
echo

# 3. RAM Usage
echo "----- MEMORY USAGE -----"
free -h
echo

# 4. Disk Space Usage
echo "----- DISK SPACE -----"
df -h
echo

# 5. Top 5 Processes by CPU Usage
echo "----- TOP 5 CPU PROCESSES -----"
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
echo

# 6. Important Service Status
echo "----- SERVICE STATUS -----"

SERVICES=("ssh" "apache2" "nginx" "mysql")

for SERVICE in "${SERVICES[@]}"; do
    if systemctl list-unit-files "${SERVICE}.service" \
        --no-legend 2>/dev/null | grep -q "${SERVICE}.service"; then
        if systemctl is-active --quiet "$SERVICE"; then
            echo "$SERVICE: RUNNING"
        else
            echo "$SERVICE: STOPPED or INACTIVE"
        fi
    else
        echo "$SERVICE: NOT INSTALLED"
    fi
done
echo

# 7. Network Connectivity
echo "----- NETWORK CONNECTIVITY -----"

if ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1; then
    echo "Internet connectivity: OK"
else
    echo "Internet connectivity: FAILED"
fi

if getent hosts google.com >/dev/null 2>&1; then
    echo "DNS resolution: OK"
else
    echo "DNS resolution: FAILED"
fi
echo

# 8. Final Summary
echo "=========================================="
echo "       HEALTH CHECK COMPLETED"
echo "Report saved to: $REPORT"
echo "=========================================="
