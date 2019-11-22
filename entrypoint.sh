#!/bin/bash
set -e

function cleanup {
  echo "Removing /data/*"
  rm -rf /data/*
}

trap 'kill ${!}; cleanup' SIGINT
trap 'kill ${!}; cleanup' SIGTERM
trap 'kill ${!}; cleanup' SIGTSTP

SSH_AUTH_KEY=${SSH_AUTH_KEY}
USERNAME=${USERNAME:-user}
PASSWORD=${PASSWORD:-pass}
ALLOW=${ALLOW:-192.168.8.0/24 192.168.24.0/24 172.16.0.0/12 127.0.0.1/32}
VOLUME=${VOLUME:-/data}

if [ "$1" = 'rsync_server' ]; then

    mkdir -p /root/.ssh
    echo "$SSH_AUTH_KEY" > /root/.ssh/authorized_keys

    exec /usr/sbin/sshd &

    echo "root:$PASSWORD" | chpasswd

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

    exec /usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf "$@" &
fi

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done