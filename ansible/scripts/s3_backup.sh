#!/bin/bash
# PostgreSQL S3 backup script

# Configuration
BACKUP_DIR="/var/backups/postgresql"
S3_BUCKET="${S3_BUCKET:-}"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="pg_backup_$DATE.sql.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
S3_PATH="postgresql/$INSTANCE_ID/$BACKUP_FILE"
RETENTION_DAYS=7

# Check if S3 bucket is configured
if [ -z "$S3_BUCKET" ]; then
    echo "Error: S3_BUCKET environment variable is not set. Skipping S3 upload."
    exit 1
fi

# Check if backup file exists
if [ ! -f "$BACKUP_PATH" ]; then
    echo "Error: Backup file $BACKUP_PATH does not exist. Run backup_pg.sh first."
    exit 1
fi

# Upload to S3
echo "Uploading backup to S3 bucket $S3_BUCKET at $(date)"
aws s3 cp "$BACKUP_PATH" "s3://$S3_BUCKET/$S3_PATH"

# Check if upload was successful
if [ $? -eq 0 ]; then
    echo "Backup successfully uploaded to S3: s3://$S3_BUCKET/$S3_PATH"
    
    # Clean up local backup if S3 upload was successful
    echo "Removing local backup file: $BACKUP_PATH"
    rm -f "$BACKUP_PATH"
else
    echo "Failed to upload backup to S3!"
    exit 1
fi

# Clean up old backups in S3
echo "Cleaning up old backups in S3 older than $RETENTION_DAYS days"
aws s3 ls "s3://$S3_BUCKET/postgresql/$INSTANCE_ID/" | grep "pg_backup_" | awk '{print $4}' | while read -r old_backup; do
    backup_date=$(echo "$old_backup" | sed -E 's/pg_backup_([0-9]{4}-[0-9]{2}-[0-9]{2})_.*/\1/')
    backup_date_seconds=$(date -d "$backup_date" +%s)
    current_date_seconds=$(date +%s)
    age_days=$(( (current_date_seconds - backup_date_seconds) / 86400 ))
    
    if [ "$age_days" -gt "$RETENTION_DAYS" ]; then
        echo "Removing old S3 backup: $old_backup (${age_days} days old)"
        aws s3 rm "s3://$S3_BUCKET/postgresql/$INSTANCE_ID/$old_backup"
    fi
done

echo "S3 backup process completed at $(date)"
exit 0
