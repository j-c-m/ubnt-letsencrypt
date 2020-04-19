#!/bin/bash

usage() {
    echo "Usage: $0 -d <mydomain.com> [-d <additionaldomain.com>]" 1>&2; exit 1;
}

kill_and_wait() {
    local pid=$1
    [ -z $pid ] && return

    kill $pid 2> /dev/null
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
        i) ;;
        *)
          usage
          ;;
    esac
done
shift $((OPTIND -1))

# check for required parameters
if [ ${#DOMAIN[@]} -eq 0 ]; then
    usage
fi

# prepare our domain flags for acme.sh
for val in "${DOMAIN[@]}"; do
     DOMAINARG+="-d $val "
done

ACMEHOME=/config/.acme.sh

mkdir -p $ACMEHOME/webroot

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
if [ -e "/var/run/lighttpd.pid" ]; then
    kill_and_wait $(cat /var/run/lighttpd.pid)
fi

log "Starting temporary ACME challenge service."
/usr/sbin/lighttpd -f $ACMEHOME/lighttpd.conf

/sbin/iptables -I INPUT 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/ip6tables -I INPUT 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/iptables -t nat -I PREROUTING 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
mkdir -p /config/ssl
# trick sudo detection in acme.sh
unset SUDO_COMMAND
$ACMEHOME/acme.sh --issue $DOMAINARG -w $ACMEHOME/webroot --home $ACMEHOME \
--reloadcmd "cat $ACMEHOME/${DOMAIN[0]}/${DOMAIN[0]}.cer $ACMEHOME/${DOMAIN[0]}/${DOMAIN[0]}.key > /config/ssl/server.pem; cp $ACMEHOME/${DOMAIN[0]}/ca.cer /config/ssl/ca.pem"
/sbin/iptables -D INPUT -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/ip6tables -D INPUT -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/iptables -t nat -D PREROUTING 1

log "Stopping temporary ACME challenge service."
if [ -e "$ACMEHOME/lighttpd.pid" ]; then
    kill_and_wait $(cat $ACMEHOME/lighttpd.pid)
fi

log "Starting GUI service."
if [ -x "/bin/systemctl" ]; then
    /bin/systemctl start lighttpd.service
else
    /usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
fi
