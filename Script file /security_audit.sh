
#!/bin/bash

# Ubuntu Server Security Audit

REPORT="security_audit_report.txt"

# Start report
{
    echo "=========================================="
    echo "       UBUNTU SERVER SECURITY AUDIT"
    echo "=========================================="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "=========================================="
} > "$REPORT"

# Function to display and save results
check_result() {
    STATUS="$1"
    MESSAGE="$2"

    echo "[$STATUS] $MESSAGE" | tee -a "$REPORT"
}

echo -e "\n--- 1. Firewall Status ---" | tee -a "$REPORT"

if command -v ufw >/dev/null 2>&1; then
    if sudo ufw status | grep -q "Status: active"; then
        check_result "PASS" "UFW firewall is active."
    else
        check_result "WARNING" "UFW firewall is inactive."
    fi
else
    check_result "WARNING" "UFW is not installed; check other firewall tools."
fi

echo -e "\n--- 2. Listening Network Ports ---" | tee -a "$REPORT"

if command -v ss >/dev/null 2>&1; then
    ss -tuln | tee -a "$REPORT"
    check_result "PASS" "Listening ports listed for review."
else
    check_result "WARNING" "The ss command is unavailable."
fi

echo -e "\n--- 3. User Accounts ---" | tee -a "$REPORT"

awk -F: '$3 == 0 || $3 >= 1000 {print $1 " (UID: " $3 ")"}' \
    /etc/passwd | tee -a "$REPORT"

check_result "PASS" "Local accounts listed for review."

echo -e "\n--- 4. Currently Logged-in Users ---" | tee -a "$REPORT"

who | tee -a "$REPORT"

check_result "PASS" "Logged-in user information collected."

echo -e "\n--- 5. Running Services ---" | tee -a "$REPORT"

if command -v systemctl >/dev/null 2>&1; then
    systemctl list-units --type=service --state=running \
        --no-pager | tee -a "$REPORT"
    check_result "WARNING" "Review running services for unnecessary services."
else
    check_result "WARNING" "systemctl is unavailable."
fi

echo -e "\n--- 6. SSH Security Configuration ---" | tee -a "$REPORT"

SSH_CONFIG="/etc/ssh/sshd_config"

if [ -r "$SSH_CONFIG" ]; then
    PERMIT_ROOT=$(sshd -T 2>/dev/null | awk '$1=="permitrootlogin"{print $2; exit}')
    PASSWORD_AUTH=$(sshd -T 2>/dev/null | awk '$1=="passwordauthentication"{print $2; exit}')

    if [ "$PERMIT_ROOT" = "no" ]; then
        check_result "PASS" "SSH root login is disabled."
    else
        check_result "WARNING" "SSH root login setting: ${PERMIT_ROOT:-unknown}."
    fi

    if [ "$PASSWORD_AUTH" = "no" ]; then
        check_result "PASS" "SSH password authentication is disabled."
    else
        check_result "WARNING" "SSH password authentication: ${PASSWORD_AUTH:-unknown}."
    fi
else
    check_result "WARNING" "SSH configuration is unavailable."
fi

echo -e "\n--- 7. World-Writable Files ---" | tee -a "$REPORT"

find /etc /usr/local -xdev -type f -perm -0002 \
    -print 2>/dev/null | head -n 20 | tee -a "$REPORT"

check_result "WARNING" "Review listed world-writable files, if any."

echo -e "\n--- 8. SUID Files ---" | tee -a "$REPORT"

find /usr/bin /usr/sbin /bin /sbin -xdev -type f -perm -4000 \
    -print 2>/dev/null | tee -a "$REPORT"

check_result "WARNING" "Review SUID files for unexpected entries."

echo -e "\n--- 9. Failed Login Attempts ---" | tee -a "$REPORT"

if command -v journalctl >/dev/null 2>&1; then
    journalctl --since "24 hours ago" --no-pager 2>/dev/null \
        | grep -iE "failed password|authentication failure" \
        | tail -n 20 | tee -a "$REPORT"
elif [ -r /var/log/auth.log ]; then
    grep -iE "failed password|authentication failure" \
        /var/log/auth.log | tail -n 20 | tee -a "$REPORT"
else
    echo "Authentication logs unavailable." | tee -a "$REPORT"
fi

echo -e "\n--- 10. Final Summary ---" | tee -a "$REPORT"

echo "Security audit completed at $(date)." | tee -a "$REPORT"
echo "Report saved to: $REPORT" | tee -a "$REPORT"

echo "=========================================="
echo "Audit completed. Review the report:"
echo "$REPORT"
echo "=========================================="
