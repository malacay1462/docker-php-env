FROM phpdockerio/php:8.5-fpm

USER root

# Fix debconf warnings upon build
ARG DEBIAN_FRONTEND=noninteractive

# Create Sail user (for Laravel Sail compatibility)
ARG USERNAME_SAIL=sail
ARG USER_UID_SAIL=1001
ARG USER_GID_SAIL=0

RUN useradd --uid $USER_UID_SAIL --gid $USER_GID_SAIL -m $USERNAME_SAIL \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME_SAIL ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME_SAIL \
    && chmod 0440 /etc/sudoers.d/$USERNAME_SAIL

# System tools
RUN apt-get update; \
    apt-get -y --no-install-recommends install \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    webp \
    ncdu \
    git \
    ca-certificates \
    curl \
    vim \
    htop \
    graphviz \
    imagemagick \
    mysql-client \
    aspell \
    aspell-de \
    python3 \
    unzip ; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# PHP Extensions
# Note: opcache is now built into PHP 8.5 core (no separate package needed)
# Note: pcntl is built into PHP core
# Note: memcache package doesn't exist for 8.5, only memcached
RUN apt-get update; \
    apt-get -y --no-install-recommends install \
        php8.5-bcmath \
        php8.5-bz2 \
        php8.5-gd \
        php8.5-imagick \
        php8.5-intl \
        php8.5-maxminddb \
        # php8.5-memcache \
        php8.5-memcached \
        php8.5-mysql \
        php8.5-pcov \
        php8.5-pspell \
        php8.5-redis \
        php8.5-sqlite3 \
        # php8.5-pdo-sqlite \
        php8.5-tidy \
        php8.5-uuid \
        php8.5-vips \
        php8.5-xdebug \
        php8.5-apcu \
        php8.5-cli \
        php8.5-curl \
        php8.5-mbstring \
        # php8.5-opcache \
        # php8.5-pcntl \
        php8.5-readline \
        php8.5-xml \
        php8.5-zip \
        php8.5-yaml; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Composer
RUN composer self-update --2

# SSH
ARG SSH_ROOT_PASSWORD
RUN apt-get update && apt-get install -y openssh-server ssh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/run/sshd
RUN echo "root:${SSH_ROOT_PASSWORD}" | chpasswd
COPY "sshd_config" "/etc/ssh/sshd_config"

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

COPY "docker-entrypoint.sh" "/usr/local/bin/docker-entrypoint.sh"
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh \
    && ln -s /usr/local/bin/docker-entrypoint.sh /

RUN (umask 077 && test -d ~/.ssh || mkdir ~/.ssh) \
    && (umask 077 && touch ~/.ssh/authorized_keys)

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/sbin/php-fpm8.5", "-O" ]

# SSH Port
EXPOSE 22

# PHP-FPM Port
EXPOSE 9000
