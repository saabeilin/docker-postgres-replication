# -*- mode: conf -*-
FROM postgres:11.4-alpine

MAINTAINER saabeilin@gmail.com

# common settings
ENV MAX_CONNECTIONS 500
ENV WAL_KEEP_SEGMENTS 256
ENV MAX_WAL_SENDERS 100

# master/standby settings
ENV POSTGRES_REPLICATION_ROLE master
ENV POSTGRES_REPLICATION_USER replication
ENV POSTGRES_REPLICATION_PASSWORD ""

# standby settings
ENV POSTGRES_MASTER_SERVICE_HOST localhost
ENV POSTGRES_MASTER_SERVICE_PORT 5432

COPY 10-config.sh /docker-entrypoint-initdb.d/
COPY 20-replication.sh /docker-entrypoint-initdb.d/
# Evaluate vars inside PGDATA at runtime.
# For example HOSTNAME in 'ENV PGDATA=/mnt/$HOSTNAME'
# is resolved runtime rather then during build
RUN sed -i 's/set -e/set -e -x\nPGDATA=$(eval echo "$PGDATA")/' /docker-entrypoint.sh
