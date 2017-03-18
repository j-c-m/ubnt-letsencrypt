#!/bin/bash

usage() {
    echo "Usage: $0 -d <mydomain.com> [-d <additionaldomain.com>] -i <wandev>" 1>&2; exit 1;
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

# prepare our domain flags for acme.sh
for val in "${DOMAIN[@]}"; do
     DOMAINARG+="-d $val "
done

if [ ${#DOMAIN[@]} -eq 0 ] || [ -z ${WAN+x} ]; then
    usage
fi 

ACMEHOME=/config/.acme.sh
WANIP=$(ip addr show $WAN | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

mkdir -p $ACMEHOME/webroot

(
cat <<EOF
server.modules = ( "mod_accesslog" )
server.document-root = "$ACMEHOME/webroot"
server.port = 80
server.bind = "$WANIP"
server.pid-file = "$ACMEHOME/lighttpd.pid"
accesslog.filename = "$ACMEHOME/lighttpd.log"
EOF
) >$ACMEHOME/lighttpd.conf

/usr/sbin/lighttpd -f $ACMEHOME/lighttpd.conf

/sbin/iptables -I INPUT 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
$ACMEHOME/acme.sh --issue $DOMAINARG -w $ACMEHOME/webroot --home $ACMEHOME --local-address $WANIP --keypath /tmp/server.key --fullchainpath /tmp/full.cer --reloadcmd /config/scripts/reload.acme.sh
/sbin/iptables -D INPUT 1

if [ -e "$ACMEHOME/lighttpd.pid" ]
then
    kill -s INT $(cat $ACMEHOME/lighttpd.pid)
fi
