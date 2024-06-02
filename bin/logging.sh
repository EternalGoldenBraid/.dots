#!/bin/bash

# Function to append logs with a timestamp
log_message() {
    local log_type=$1
    local message=$2
    local log_file=$3

    # Check if the log file exists
    if [ ! -f $log_file ]; then
        touch $log_file
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$log_type] - $message" >> $log_file
}

