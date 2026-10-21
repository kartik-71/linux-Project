# linux automation projects

health_check.sh 

This script checks whether the Ubuntu server is healthy and operating normally. It can collect information such as CPU usage, RAM usage, disk-space usage, system uptime, running processes, and the status of important services such as SSH, Apache/Nginx, or MySQL. It can also check whether the server has network connectivity. The results can be displayed on the terminal or saved into a report file. This helps an administrator quickly identify problems such as high CPU usage, low disk space, insufficient memory, or stopped services.

backup.sh — Automated Backup

This script automates the process of backing up important data from the Ubuntu server. It can back up application files, configuration files such as /etc/ssh/sshd_config, website files, user data, and databases. The script can create a compressed backup using tools such as tar, include the current date and time in the backup filename, and store the backup in a separate directory or remote server. It can also delete backups older than a specified number of days. This prevents administrators from having to manually perform backups every day.
