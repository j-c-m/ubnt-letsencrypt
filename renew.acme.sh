#!/bin/bash

usage() {
    echo "Usage: $0 -d <mydomain.com> [-d <additionaldomain.com>] [options ...]
Options:
    -h, --help          Show this help message.
    -d, --domain        Specifies domain for cert, allowed multiple times.
    -f, --force         Force cert renewal.
    --debug [0|1|2|3]   Output debug info. Defaults to 1 if argument is omitted.
    --staging, --test   Use staging server, for testing.
" 1>&2; exit 1;
}

kill_and_wait() {
    local pid=$1
    [ -z $pid ] && return

    kill $pid 2> /dev/null
    while kill -s 0 $pid 2> /dev/null; do
        sleep 1
    done
}

log() {
    if [ -z "$2" ]
    then
        printf -- "%s %s\n" "[$(date)]" "$1"
    fi
}

STAGING="--server letsencrypt"

while [ ${#} -gt 0 ]; do
    case "${1}" in
        -h|--help)
            usage
            ;;
        -f|--force)
            FORCE="--force"
            ;;
        -i)
            shift
            ;;
        -d|--domain)
            if [ -z "$2" ] || [ "${2:0:1}" = "-" ]; then
                echo "Domain required"
                usage
            fi
            DOMAIN+=("$2")
            shift
            ;;
        --debug)
            if [ -z "$2" ] || [ "${2:0:1}" = "-" ]; then
                DEBUG="--debug 1"
            else
                DEBUG="--debug ${2}"
                shift
            fi
            ;;
        --staging|--test)
            STAGING="--staging"
            ;;
        *)
            echo "Unknown parameter : ${1}"
            usage
            ;;
    esac
    shift 1
done

# check for required parameters
if [ ${#DOMAIN[@]} -eq 0 ]; then
    echo "Domain required"
    usage
fi

# prepare our domain flags for acme.sh
for val in "${DOMAIN[@]}"; do
     DOMAINARG+="-d $val "
done

ACMEHOME=/config/.acme.sh

mkdir -p $ACMEHOME/webroot

(
cat <<EOF
server.modules = ( "mod_accesslog" )
server.document-root = "$ACMEHOME/webroot"
server.port = 80
server.bind = "0.0.0.0"
\$SERVER["socket"] == "[::]:80" {  }
server.pid-file = "$ACMEHOME/lighttpd.pid"
server.errorlog = "/dev/null"
accesslog.filename = "$ACMEHOME/lighttpd.log"
EOF
) >$ACMEHOME/lighttpd.conf

log "Stopping GUI service."
if [ -e "/var/run/lighttpd.pid" ]; then
    kill_and_wait $(cat /var/run/lighttpd.pid)
fi

log "Starting temporary ACME challenge service."
/usr/sbin/lighttpd -f $ACMEHOME/lighttpd.conf

/sbin/iptables -I INPUT 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/ip6tables -I INPUT 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/iptables -t nat -I PREROUTING 1 -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT

# trick sudo detection in acme.sh
unset SUDO_COMMAND
$ACMEHOME/acme.sh --issue $DOMAINARG -w $ACMEHOME/webroot --home $ACMEHOME \
--reloadcmd "cat \$CERT_PATH \$CERT_KEY_PATH > /config/ssl/server.pem; cp \$CA_CERT_PATH /config/ssl/ca.pem" \
${STAGING} ${FORCE} ${DEBUG}
/sbin/iptables -D INPUT -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/ip6tables -D INPUT -p tcp -m comment --comment TEMP_LETSENCRYPT -m tcp --dport 80 -j ACCEPT
/sbin/iptables -t nat -D PREROUTING 1

log "Stopping temporary ACME challenge service."
if [ -e "$ACMEHOME/lighttpd.pid" ]; then
    kill_and_wait $(cat $ACMEHOME/lighttpd.pid)
fi

log "Starting GUI service."
if [ -x "/bin/systemctl" ]; then
    /bin/systemctl start lighttpd.service
else
    /usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
fi
