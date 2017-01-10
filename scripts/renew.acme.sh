#!/bin/sh

# config
DOMAIN=subdomain.example.com
WAN=eth0
# end

ACMEHOME=/config/.acme.sh
WANIP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

/sbin/iptables -I WAN_LOCAL 2 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j RETURN
$ACMEHOME/acme.sh --issue -d $DOMAIN --standalone --home $ACMEHOME --local-address $WANIP --keypath /tmp/server.key --fullchainpath /tmp/full.cer --reloadcmd /config/scripts/reload.acme.sh $@
/sbin/iptables -D WAN_LOCAL 2