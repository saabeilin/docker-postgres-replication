#!/bin/bash
set -e

echo [*] configuring $POSTGRES_REPLICATION_ROLE instance

echo "max_connections = $MAX_CONNECTIONS" >> "$PGDATA/postgresql.conf"

# We set master replication-related parameters for both standby and master,
# so that the standby might work as a primary after failover.
echo "wal_level = hot_standby" >> "$PGDATA/postgresql.conf"
echo "wal_keep_segments = $WAL_KEEP_SEGMENTS" >> "$PGDATA/postgresql.conf"
echo "max_wal_senders = $MAX_WAL_SENDERS" >> "$PGDATA/postgresql.conf"
# standby settings, ignored on master
echo "hot_standby = on" >> "$PGDATA/postgresql.conf"

if [ x$POSTGRES_REPLICATION_PASSWORD = "x" ]; then
    echo "host replication $POSTGRES_REPLICATION_USER 0.0.0.0/0 trust" >> "$PGDATA/pg_hba.conf"
else
    echo "host replication $POSTGRES_REPLICATION_USER 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
fi
