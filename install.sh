#!/bin/bash

mkdir -p /config/.acme.sh /config/scripts
curl -o /config/.acme.sh/acme.sh https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh
curl -o /config/scripts/renew.acme.sh https://raw.githubusercontent.com/j-c-m/ubnt-letsencrypt/master/renew.acme.sh
chmod 755 /config/.acme.sh/acme.sh /config/scripts/renew.acme.sh
