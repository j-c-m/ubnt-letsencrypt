#!/bin/bash

ACMEHOME=/config/.acme.sh
SSL_DIR=/config/ssl
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

kill_and_wait() {
    local pid=$1
    [ -z $pid ] && return

    kill -s INT $pid 2> /dev/null
    while kill -s 0 $pid 2> /dev/null; do
        sleep 1
    done
}

log() {
    if [ -z "$2" ]
    then
        printf -- "%s %s\n" "[$(date)]" "$1"
    fi
}
