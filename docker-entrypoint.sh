#!/bin/bash

#service cron --full-restart
service ssh --full-restart
service supervisor --full-restart

/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
#/usr/sbin/cron
/usr/sbin/sshd -D
#exec /usr/sbin/php-fpm7.4 -O

exec "$@"