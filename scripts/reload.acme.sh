#!/bin/sh

mkdir -p /config/ssl
cat /tmp/server.key /tmp/full.cer > /config/ssl/server.pem
rm /tmp/server.key /tmp/full.cer
