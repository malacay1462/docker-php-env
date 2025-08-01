#!/bin/bash

# Load NVM for interactive shells
export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Start SSH service and daemon
service ssh --full-restart
/usr/sbin/sshd

# Start Supervisor (if needed)
# service supervisor --full-restart
# /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

# Start cron (if needed)
# /usr/sbin/cron

# Execute the main command (PHP-FPM from CMD) in foreground
exec "$@"