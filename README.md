# linux automation projects

health_check.sh 

This script checks whether the Ubuntu server is healthy and operating normally. It can collect information such as CPU usage, RAM usage, disk-space usage, system uptime, running processes, and the status of important services such as SSH, Apache/Nginx, or MySQL. It can also check whether the server has network connectivity. The results can be displayed on the terminal or saved into a report file. This helps an administrator quickly identify problems such as high CPU usage, low disk space, insufficient memory, or stopped services.

backup.sh — Automated Backup

This script automates the process of backing up important data from the Ubuntu server. It can back up application files, configuration files such as /etc/ssh/sshd_config, website files, user data, and databases. The script can create a compressed backup using tools such as tar, include the current date and time in the backup filename, and store the backup in a separate directory or remote server. It can also delete backups older than a specified number of days. This prevents administrators from having to manually perform backups every day.

log_monitor.sh — Log Monitoring

This script automatically checks important system and application log files for unusual or important events. On Ubuntu, it can examine logs related to SSH authentication, system services, applications, and security events. For example, it can search for repeated failed SSH login attempts, authentication failures, service errors, or other error messages. If a suspicious or important event is detected, the script can record it in a separate report or generate an alert. This is useful for troubleshooting and basic security monitoring.


security_audit.sh — Server Security Audit

This script performs a basic security audit of the Ubuntu server. It can check whether the firewall is enabled, which ports are open, which users exist, who is currently logged in, whether unnecessary services are running, and whether SSH is configured securely. It can also check file permissions, SUID files, failed login attempts, and other basic security settings. At the end, it can generate a report containing PASS, WARNING, or FAIL results. This gives an administrator a quick overview of the server's security configuration.

audit_accounts.sh

Read a list of employee usernames from a text file provided.
Verify whether each employee account exists on the server.
Identify accounts that exist on the server but are missing from the approved list.
Check which accounts have administrative privileges through the wheel group.
Identify accounts that are locked or have expired passwords.
Generate a report containing the username, account status, group membership, and audit finding.
Save the report with the current date in its filename.
Produce a separate summary showing the total number of approved, missing, and unapproved accounts.
