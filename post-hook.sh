#!/bin/bash

source /config/scripts/ubnt-letsencrypt/common.sh

/sbin/iptables -D INPUT -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/ip6tables -D INPUT -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/iptables -t nat -D PREROUTING 1

log "Stopping temporary ACME challenge service."
if [ -e "$ACMEHOME/lighttpd.pid" ]
then
    kill_and_wait $(cat $ACMEHOME/lighttpd.pid)
fi

log "Starting GUI service."
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
