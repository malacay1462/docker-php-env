apt-get update; \
    apt-get -y --no-install-recommends install \
        php8.4-mcrypt; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*;