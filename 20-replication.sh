#!/bin/bash
set -e

if [ $POSTGRES_REPLICATION_ROLE = "master" ]; then
    PGPASSWORD=${POSTGRES_PASSWORD:-""} psql -U postgres -c "CREATE ROLE $POSTGRES_REPLICATION_USER WITH REPLICATION PASSWORD '$POSTGRES_REPLICATION_PASSWORD' LOGIN"

elif [ $POSTGRES_REPLICATION_ROLE = "standby" ]; then
    # stop postgres instance and reset PGDATA,
    # confs will be copied by pg_basebackup
    pg_ctl -D "$PGDATA" -m fast -w stop
    # make sure standby's data directory is empty
    rm -r "$PGDATA"/*

    # wait for master to get up
    until \
        PGPASSWORD=${POSTGRES_REPLICATION_PASSWORD:-""} pg_isready \
        -h $POSTGRES_MASTER_SERVICE_HOST \
        -p $POSTGRES_MASTER_SERVICE_PORT \
        -U $POSTGRES_REPLICATION_USER \
        -d $POSTGRES_DB; do
        echo "waiting for master $POSTGRES_MASTER_SERVICE_HOST:$POSTGRES_MASTER_SERVICE_PORT..."
        sleep 1
    done

    PGPASSWORD=${POSTGRES_REPLICATION_PASSWORD:-""} pg_basebackup \
         --write-recovery-conf \
         --pgdata="$PGDATA" \
         --wal-method=fetch \
         --username=$POSTGRES_REPLICATION_USER \
         --host=$POSTGRES_MASTER_SERVICE_HOST \
         --port=$POSTGRES_MASTER_SERVICE_PORT \
         --progress \
         --verbose

    # useless postgres start to fullfil docker-entrypoint.sh stop
    pg_ctl -D "$PGDATA" \
         -o "-c listen_addresses=''" \
         -w start
fi

echo [*] $POSTGRES_REPLICATION_ROLE instance configured!
