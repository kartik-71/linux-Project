
#!/bin/bash

# Ubuntu Server Backup Script

# Source directory to back up
SOURCE="/home/$USER/Documents"

# Backup destination directory
DESTINATION="/home/$USER/backups"

# Create timestamp
DATE=$(date +%Y-%m-%d_%H-%M-%S)

# Backup filename
BACKUP_FILE="backup_$DATE.tar.gz"

echo "=================================="
echo "       SERVER BACKUP SCRIPT"
echo "=================================="

# Check if source directory exists
if [ ! -d "$SOURCE" ]; then
    echo "Error: Source directory does not exist: $SOURCE"
    exit 1
fi

# Create backup directory if it does not exist
mkdir -p "$DESTINATION" || {
    echo "Error: Cannot create backup directory."
    exit 1
}

echo "Source: $SOURCE"
echo "Destination: $DESTINATION"
echo "Starting backup..."

# Create compressed backup
if tar -czf "$DESTINATION/$BACKUP_FILE" -C "$SOURCE" .; then
    echo "Backup completed successfully!"
    echo "Backup file: $DESTINATION/$BACKUP_FILE"
else
    echo "Error: Backup failed."
    exit 1
fi

# Delete backups older than 7 days
echo
echo "Removing backups older than 7 days..."

find "$DESTINATION" -maxdepth 1 -type f \
    -name "backup_*.tar.gz" -mtime +7 -delete

echo "Old backup cleanup completed."

echo "=================================="
echo "       BACKUP FINISHED"
echo "=================================="

