#!/bin/bash

mkdir -p /config/.acme.sh /config/scripts/ubnt-letsencrypt

curl -o /config/.acme.sh/acme.sh https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh
chmod 755 /config/.acme.sh/acme.sh

for file in common.sh setup.sh pre-hook.sh post-hook.sh reloadcmd.sh
do
    curl -o "/config/scripts/ubnt-letsencrypt/$file" "https://raw.githubusercontent.com/dotsam/ubnt-letsencrypt/use-hooks/$file"
    chmod 755 /config/scripts/ubnt-letsencrypt/$file
done
