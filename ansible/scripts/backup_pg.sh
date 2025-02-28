#!/bin/bash
# PostgreSQL backup script

# Configuration
BACKUP_DIR="/var/backups/postgresql"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/pg_backup_$DATE.sql.gz"
RETENTION_DAYS=7
S3_BACKUP_ENABLED="${S3_BACKUP_ENABLED:-true}"
S3_BUCKET="${S3_BUCKET:-}"

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Create backup
echo "Starting PostgreSQL backup at $(date)"
pg_dumpall -U postgres | gzip > $BACKUP_FILE

# Check if backup was successful
if [ $? -eq 0 ]; then
    echo "Backup completed successfully: $BACKUP_FILE"
    # Set proper permissions
    chmod 600 $BACKUP_FILE
    
    # Upload to S3 if enabled
    if [ "$S3_BACKUP_ENABLED" = "true" ] && [ -n "$S3_BUCKET" ]; then
        echo "Initiating S3 backup..."
        export S3_BUCKET
        /opt/pg_scripts/s3_backup.sh
        
        # If S3 backup was successful, we don't need to remove old local backups
        # as the s3_backup.sh script already removes the local backup after upload
        if [ $? -eq 0 ]; then
            echo "S3 backup successful, skipping local backup cleanup"
            exit 0
        else
            echo "S3 backup failed, keeping local backup"
        fi
    fi
else
    echo "Backup failed!"
    exit 1
fi

# Remove old backups (only if we're keeping local backups)
echo "Removing backups older than $RETENTION_DAYS days"
find $BACKUP_DIR -name "pg_backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete

echo "Backup process completed at $(date)"
exit 0
