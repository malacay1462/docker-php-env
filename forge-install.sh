apt-get update; \
    apt-get -y --no-install-recommends install \
        imagemagick \
        php8.4-amqp \
        php8.4-ast \
        php8.4-bcmath \
        php8.4-bz2 \
        php8.4-gmp \
        php8.4-grpc \
        php8.4-imagick \
        php8.4-imap \
        php8.4-interbase \
        php8.4-intl \
        php8.4-ldap \
        php8.4-mailparse \
        php8.4-maxminddb \
        php8.4-memcache \
        php8.4-memcached \
        php8.4-mysql \
        php8.4-oauth \
        php8.4-odbc \
        php8.4-pgsql \
        php8.4-pspell \
        php8.4-redis \
        php8.4-soap \
        php8.4-sqlite3 \
        php8.4-ssh2 \
        php8.4-swoole \
        php8.4-tidy \
        php8.4-uuid \
        php8.4-vips \
        php8.4-xmlrpc \
        php8.4-apcu \
        php8.4-cli \
        php8.4-curl \
        php8.4-mbstring \
        php8.4-opcache \
        php8.4-readline \
        php8.4-xml \
        php8.4-zip \
        php8.4-yaml; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*