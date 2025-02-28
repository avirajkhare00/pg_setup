#!/bin/bash
# PostgreSQL vacuum analyze script

echo "Starting PostgreSQL VACUUM ANALYZE at $(date)"

# Run VACUUM ANALYZE on all databases
psql -U postgres -c "SELECT datname FROM pg_database WHERE datistemplate = false;" | grep -v "datname\|row" | while read -r db; do
    if [ -n "$db" ]; then
        echo "Running VACUUM ANALYZE on database: $db"
        psql -U postgres -d "$db" -c "VACUUM ANALYZE;"
    fi
done

echo "VACUUM ANALYZE completed at $(date)"
exit 0
