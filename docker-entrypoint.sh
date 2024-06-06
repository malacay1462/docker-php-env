#!/bin/bash

service ssh --full-restart
# service supervisor --full-restart

# /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
#/usr/sbin/cron
/usr/sbin/sshd -D

exec "$@"