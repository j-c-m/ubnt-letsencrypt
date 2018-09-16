#!/bin/bash

source /config/scripts/ubnt-letsencrypt/common.sh

cat $CERT_PATH $CERT_KEY_PATH > $SSL_DIR/server.pem; cp $CA_CERT_PATH $SSL_DIR/ca.pem
