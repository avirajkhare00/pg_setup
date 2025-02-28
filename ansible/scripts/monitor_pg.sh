#!/bin/bash
# PostgreSQL monitoring script

# Configuration
LOG_FILE="/var/log/pg_monitor.log"
MAX_LOG_SIZE_MB=100
ALERT_THRESHOLD_CONNECTIONS=80  # Percentage of max connections
ALERT_THRESHOLD_DISK_USAGE=80   # Percentage of disk usage

# Rotate log if it gets too large
if [ -f "$LOG_FILE" ]; then
    log_size_mb=$(du -m "$LOG_FILE" | cut -f1)
    if [ "$log_size_mb" -gt "$MAX_LOG_SIZE_MB" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
    fi
fi

# Get PostgreSQL max connections
max_connections=$(psql -U postgres -t -c "SHOW max_connections;" | tr -d ' ')

# Get current connection count
current_connections=$(psql -U postgres -t -c "SELECT count(*) FROM pg_stat_activity;" | tr -d ' ')

# Calculate connection percentage
connection_percentage=$((current_connections * 100 / max_connections))

# Check disk usage for PostgreSQL data directory
data_dir_usage=$(df -h /var/lib/postgresql/data | tail -1 | awk '{print $5}' | tr -d '%')

# Log timestamp
echo "=== PostgreSQL Monitoring Report $(date) ===" >> "$LOG_FILE"

# Log connection information
echo "Connections: $current_connections/$max_connections ($connection_percentage%)" >> "$LOG_FILE"

# Log disk usage
echo "Data directory disk usage: $data_dir_usage%" >> "$LOG_FILE"

# Check for long-running queries (longer than 5 minutes)
echo "Long-running queries:" >> "$LOG_FILE"
psql -U postgres -c "
SELECT 
    pid, 
    now() - pg_stat_activity.query_start AS duration, 
    query 
FROM pg_stat_activity 
WHERE state = 'active' 
    AND now() - pg_stat_activity.query_start > interval '5 minutes'
ORDER BY duration DESC;
" >> "$LOG_FILE"

# Check for locks
echo "Locks:" >> "$LOG_FILE"
psql -U postgres -c "
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocking_locks.pid AS blocking_pid,
    blocked_activity.usename AS blocked_user,
    blocking_activity.usename AS blocking_user,
    now() - blocked_activity.query_start AS blocked_duration,
    blocked_activity.query AS blocked_query
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.GRANTED;
" >> "$LOG_FILE"

# Check for alerts
if [ "$connection_percentage" -gt "$ALERT_THRESHOLD_CONNECTIONS" ]; then
    echo "ALERT: High connection usage ($connection_percentage%)" >> "$LOG_FILE"
fi

if [ "$data_dir_usage" -gt "$ALERT_THRESHOLD_DISK_USAGE" ]; then
    echo "ALERT: High disk usage ($data_dir_usage%)" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"
exit 0
