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
WANIP=$(ip addr show $WAN | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

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

log "Stopping gui service."
if [ -e "/var/run/lighttpd.pid" ]
then
    kill_and_wait $(cat /var/run/lighttpd.pid)
fi

log "Starting temporary acme challenge service."
/usr/sbin/lighttpd -f $ACMEHOME/lighttpd.conf

/sbin/iptables -I INPUT 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
$ACMEHOME/acme.sh --issue $DOMAINARG -w $ACMEHOME/webroot --home $ACMEHOME --local-address $WANIP --keypath /tmp/server.key --fullchainpath /tmp/full.cer --reloadcmd /config/scripts/reload.acme.sh
/sbin/iptables -D INPUT 1

log "Stopping temporary acme challenge service."
if [ -e "$ACMEHOME/lighttpd.pid" ]
then
    kill_and_wait $(cat $ACMEHOME/lighttpd.pid)
fi

log "Starting gui service."
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
