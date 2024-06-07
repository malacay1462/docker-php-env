FROM phpdockerio/php:8.3-fpm

USER root

# Fix debconf warnings upon build
ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=nonRoot
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create Non root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

ARG USERNAME_SAIL=sail
ARG USER_UID_SAIL=1001
ARG USER_GID_SAIL=0

# Create Sail user
RUN useradd --uid $USER_UID_SAIL --gid $USER_GID_SAIL -m $USERNAME_SAIL \
    && echo $USERNAME_SAIL ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME_SAIL \
    && chmod 0440 /etc/sudoers.d/$USERNAME_SAIL
    
USER root

RUN apt-get update; \
    apt-get -y --no-install-recommends install \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    webp \
    ncdu \
    git \
    nodejs \
    ca-certificates \
    curl \
    apt-transport-https \
    make \
    gnupg \
    gnupg-agent \
    python3 \
    gcc \
    vim \
    htop \
    graphviz \
    mysql-client \
    aspell \
    aspell-de \
    build-essential \
    software-properties-common \
    unzip ; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*
    
RUN apt-get update; \
    apt-get -y --no-install-recommends install \
       php-ssh2 \
       php-yaml \
       php-memcached \
       php-intl \
       php-imagick \
       php-ssh2 \
       php-yaml \
       php-redis \
       php-xdebug \
       php-mysql \
       php-pear; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# php8.3-http php8.3-maxminddb php8.3-mcrypt php8.3-msgpack php8.3-phpdbg php8.3-gmagick php8.3-gd php8.3-decimal
RUN apt-get update; \
    apt-get -y --no-install-recommends install \
        php8.3-amqp \
        php8.3-ast \
        php8.3-bcmath \
        php8.3-bz2 \
        php8.3-gmp \
        php8.3-grpc \
        php8.3-imagick \
        php8.3-imap \
        php8.3-inotify \
        php8.3-interbase \
        php8.3-intl \
        php8.3-ldap \
        php8.3-mailparse \
        php8.3-maxminddb \
        php8.3-memcache \
        php8.3-memcached \
        php8.3-mysql \
        php8.3-oauth \
        php8.3-odbc \
        php8.3-pcov \
        php8.3-pgsql \
        php8.3-pspell \
        php8.3-redis \
        php8.3-soap \
        php8.3-sqlite3 \
        php8.3-ssh2 \
        php8.3-swoole \
        php8.3-tidy \
        php8.3-uuid \
        php8.3-vips \
        php8.3-xdebug \
        php8.3-xmlrpc \
        php8.3-apcu \
        php8.3-cli \
        php8.3-curl \
        php8.3-mbstring \
        php8.3-opcache \
        php8.3-readline \
        php8.3-xml \
        php8.3-zip \
        php8.3-yaml; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Install Cron & Supervisor
RUN apt-get update \
    && apt-get -y install \
    supervisor \
    cron \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* 

# Install ZSH - Deactivate dirty file parsing, it slows zsh extremly down
RUN apt-get update \
    && apt-get install -y \
    zsh \
    fonts-powerline \
    fonts-firacode \
    && chsh -s /usr/bin/zsh \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*\
    && sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" \
    && git config --global --add oh-my-zsh.hide-dirty 1

# Docker & Podman
#RUN for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
RUN apt-get update; \
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; \
    chmod a+r /etc/apt/keyrings/docker.gpg; \
    echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null; \
    apt-get update; \
    apt-get -y --no-install-recommends install \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
        podman; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Composer
RUN composer self-update --2

## SSH
RUN apt-get update && apt-get install -y openssh-server ssh
RUN mkdir -p /var/run/sshd
RUN echo 'root:test1234' | chpasswd
COPY "sshd_config" "/etc/ssh/sshd_config"

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN mkdir -p /etc/supervisor/custom.conf.d
COPY "crontab" "/etc/crontab"
COPY "supervisord.conf" "/etc/supervisor/supervisord.conf"

COPY "docker-entrypoint.sh" "/usr/local/bin/docker-entrypoint.sh"
RUN chmod 777 /usr/local/bin/docker-entrypoint.sh \
    && ln -s /usr/local/bin/docker-entrypoint.sh /

RUN (umask 077 && test -d ~/.ssh || mkdir ~/.ssh) \
    && (umask 077 && touch ~/.ssh/authorized_keys)

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/sbin/php-fpm8.3", "-O" ]

## SSH Port
EXPOSE 22

# Open up fcgi port
EXPOSE 9000