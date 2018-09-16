#!/bin/bash

cat $CERT_PATH $CERT_KEY_PATH > $SSL_DIR/server.pem; cp $CA_CERT_PATH $SSL_DIR/ca.pem
