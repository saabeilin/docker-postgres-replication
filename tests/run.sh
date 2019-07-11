#!/usr/bin/env bash
set -eo pipefail

image="$1"

export POSTGRES_USER='postgres'
export POSTGRES_PASSWORD=''
export POSTGRES_DB='postgres'
export POSTGRES_REPLICATION_PASSWORD='whatever'


psql() {
    role="$1"
    docker run --rm -i \
               --link "postgres-$role" \
               --entrypoint psql \
               "$image" \
               --host "postgres-$role" \
               --username "$POSTGRES_USER" \
               --dbname "$POSTGRES_DB" \
               --no-align --tuples-only \
               -c "${@:2}"
}

poll() {
    set +e
    MAX_TRIES=$1
    tries=0
    while true
    do
        sleep 2
        psql master '\l' > /dev/null 2> /dev/null && psql standby '\l' > /dev/null 2> /dev/null
        if [ $? -eq 0 ]; then
            break
        else
            echo "Waiting for db to be up..."
            ((tries++))
        fi
        if [ $tries -eq $MAX_TRIES ]; then
            echo "FAIL: cannot connect to postgres"
            exit 1
        fi
    done
    set -e
}

mid=$(docker run -d -e POSTGRES_REPLICATION_PASSWORD=$POSTGRES_REPLICATION_PASSWORD --name postgres-master "$image")
sid=$(docker run -d -e POSTGRES_REPLICATION_PASSWORD=$POSTGRES_REPLICATION_PASSWORD --name postgres-standby \
             --link postgres-master \
             -e POSTGRES_MASTER_SERVICE_HOST=postgres-master \
             -e POSTGRES_REPLICATION_ROLE=standby \
             -t "$image")
trap "docker rm -f $mid $sid > /dev/null" EXIT

poll 3 times
psql master "CREATE TABLE replication_test (a INT, b INT, c VARCHAR(255))"
psql master "INSERT INTO replication_test VALUES (1, 2, 'it works')"

output=$(psql standby "SELECT c from replication_test")
if [ "$output" == 'it works' ]; then
    echo "OK"
    exit 0
else
    echo "FAIL"
    exit 1
fi
