#!/bin/bash

usage() {
    echo "Usage: $0 -d <mydomain.com> [-d <additionaldomain.com>] -i <wandev>" 1>&2; exit 1;
}

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

# first parse our options
while getopts "hd:i:" opt; do
    case $opt in
        d) DOMAIN+=("$OPTARG");;
        i) WAN=$OPTARG;;
        *)
          usage
          ;;
    esac
done
shift $((OPTIND -1))

# check for required parameters
if [ ${#DOMAIN[@]} -eq 0 ] || [ -z ${WAN+x} ]; then
    usage
fi

# prepare our domain flags for acme.sh
for val in "${DOMAIN[@]}"; do
     DOMAINARG+="-d $val "
done

ACMEHOME=/config/.acme.sh
WANIP=$(ip addr show $WAN | grep "inet\b" | awk '{print $2}' | head -n 1 | cut -d/ -f1)

if [ -z "$WANIP" ]; then
    log "Unable to determine WAN IP."
    exit 1
fi

mkdir -p $ACMEHOME/webroot

(
cat <<EOF
server.modules = ( "mod_accesslog" )
server.document-root = "$ACMEHOME/webroot"
server.port = 80
server.bind = "$WANIP"
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
/sbin/iptables -t nat -I PREROUTING 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
mkdir -p /config/ssl
$ACMEHOME/acme.sh --issue $DOMAINARG -w $ACMEHOME/webroot --home $ACMEHOME \
--reloadcmd "cat $ACMEHOME/${DOMAIN[0]}/${DOMAIN[0]}.cer $ACMEHOME/${DOMAIN[0]}/${DOMAIN[0]}.key > /config/ssl/server.pem; cp $ACMEHOME/${DOMAIN[0]}/ca.cer /config/ssl/ca.pem"
/sbin/iptables -D INPUT 1
/sbin/iptables -t nat -D PREROUTING 1

log "Stopping temporary ACME challenge service."
if [ -e "$ACMEHOME/lighttpd.pid" ]
then
    kill_and_wait $(cat $ACMEHOME/lighttpd.pid)
fi

log "Starting GUI service."
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
