#!/bin/bash

source /config/scripts/ubnt-letsencrypt/common.sh

usage() {
    echo "Usage: $0 -d <mydomain.com> [-d <additionaldomain.com>]" 1>&2; exit 1;
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

$ACMEHOME/acme.sh --home $ACMEHOME --webroot $ACMEHOME/webroot --issue $DOMAINARG \
--pre-hook "$SCRIPTPATH/pre-hook.sh" \
--post-hook "$SCRIPTPATH/post-hook.sh" \
--reloadcmd "$SCRIPTPATH/reloadcmd.sh"

if [ $? -eq 0 ]; then
    printf "Successfully issued and configured certificates for domain(s):\n"
    for val in "${DOMAIN[@]}"; do
         printf "\t$val\n"
    done
    printf "To use these certificates, please issue the following commands:\n"
    printf "\tset service gui cert-file $SSL_DIR/server.pem\n"
    printf "\tset service gui ca-file $SSL_DIR/ca.pem\n"
    printf "\tset system task-scheduler task renew.acme executable path $ACMEHOME/acme.sh\n"
    printf "\tset system task-scheduler task renew.acme executable arguments '--cron --home $ACMEHOME'\n"
    printf "\tset system task-scheduler task renew.acme interval 1d\n"
else
    log "Something went wrong issuing/installing certificates"
    exit $?
fi