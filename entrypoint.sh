#!/bin/bash
set -e

SSH_AUTH_USERNAME=${CUSTOM_USERNAME:-docker}
CUSTOM_UID=${CUSTOM_UID:-1000}
CUSTOM_GID=${CUSTOM_GID:-1000}

groupadd -g "$CUSTOM_GID" "$SSH_AUTH_USERNAME"
useradd -g "$CUSTOM_GID" -u "$CUSTOM_UID" "$SSH_AUTH_USERNAME"

ALLOW=${ALLOW:-192.168.8.0/24 192.168.24.0/24 172.16.0.0/12 127.0.0.1/32}
VOLUME=${VOLUME:-/data}

if [ "$1" = 'rsync_server' ]; then

    mkdir -p /home/"$SSH_AUTH_USERNAME"/.ssh
    echo "$SSH_AUTH_KEY" > /home/"$SSH_AUTH_USERNAME"/.ssh/authorized_keys

    exec /usr/sbin/sshd &

    echo "$USERNAME:$PASSWORD" > /etc/rsyncd.secrets
    chmod 0400 /etc/rsyncd.secrets

    mkdir -p $VOLUME

    [ -f /etc/rsyncd.conf ] || cat <<EOF > /etc/rsyncd.conf
    pid file = /var/run/rsyncd.pid
    log file = /dev/stdout
    timeout = 300
    max connections = 10
    port = 873

    [volume]
        uid = root
        gid = root
        hosts deny = *
        hosts allow = ${ALLOW}
        read only = false
        path = ${VOLUME}
        comment = ${VOLUME} directory
        auth users = ${USERNAME}
        secrets file = /etc/rsyncd.secrets
EOF

    exec /usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf "$@"
fi