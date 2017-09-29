#!/bin/sh

mkdir -p /config/ssl
cat /tmp/server.key /tmp/full.cer > /config/ssl/server.pem
mv /tmp/server.key /config/ssl/server.key
mv /tmp/full.cer /config/ssl/server.crt
