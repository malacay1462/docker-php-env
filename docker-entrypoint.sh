#!/bin/bash

# Start SSH service
service ssh --full-restart
/usr/sbin/sshd

# Execute the main command (PHP-FPM from CMD) in foreground
exec "$@"
