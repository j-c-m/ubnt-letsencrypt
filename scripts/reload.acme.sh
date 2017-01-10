#!/bin/sh

mkdir -p /config/ssl
cat /tmp/server.key /tmp/full.cer > /config/ssl/server.pem
rm /tmp/server.key /tmp/full.cer
kill -s INT $(cat /var/run/lighttpd.pid)
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf