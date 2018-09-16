#!/bin/bash

source /config/scripts/ubnt-letsencrypt/common.sh

mkdir -p $ACMEHOME/webroot
mkdir -p $SSL_DIR

(
cat <<EOF
server.modules = ( "mod_accesslog" )
server.document-root = "$ACMEHOME/webroot"
server.port = 80
server.bind = "0.0.0.0"
\$SERVER["socket"] == "[::]:80" {  }
server.pid-file = "$ACMEHOME/lighttpd.pid"
server.errorlog = "/dev/null"
accesslog.filename = "$ACMEHOME/lighttpd.log"
EOF
) >$ACMEHOME/lighttpd.conf

log "Stopping GUI service."
if [ -e "/var/run/lighttpd.pid" ]
then
    kill_and_wait $(cat /var/run/lighttpd.pid)
fi

log "Starting temporary ACME challenge service."
/usr/sbin/lighttpd -f $ACMEHOME/lighttpd.conf

/sbin/iptables -I INPUT 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/ip6tables -I INPUT 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/iptables -t nat -I PREROUTING 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
