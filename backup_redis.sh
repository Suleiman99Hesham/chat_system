#!/bin/bash

# Current timestamp
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Backup source and destination
SOURCE="./redis_data/dump.rdb"
DEST="./redis_backups/dump_${TIMESTAMP}.rdb"

# Copy the dump file
if [ -f $SOURCE ]; then
    cp $SOURCE $DEST
    echo "Backup created at ${DEST}"
else
    echo "No Redis dump file found to backup."
fi
