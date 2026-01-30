FROM phpdockerio/php:8.5-fpm

USER root

# Fix debconf warnings upon build
ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=nonRoot
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create Non root user
RUN (getent group $USER_GID >/dev/null 2>&1 || groupadd --gid $USER_GID $USERNAME) \
    && (id -u $USER_UID >/dev/null 2>&1 && echo "User with UID $USER_UID already exists" || useradd --uid $USER_UID --gid $USER_GID -m $USERNAME) \
    && apt-get update \
    && apt-get install -y sudo \
    && (test -f /etc/sudoers.d/$USERNAME || echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME) \
    && chmod 0440 /etc/sudoers.d/$USERNAME 2>/dev/null || true

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
    imagemagick \
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
       php-redis \
       php-xdebug \
       php-mysql; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# php8.5-http php8.5-maxminddb php8.5-mcrypt php8.5-msgpack php8.5-phpdbg php8.5-gmagick php8.5-gd php8.5-decimal
RUN apt-get update; \
    apt-get -y --no-install-recommends install \
        php8.5-amqp \
        php8.5-ast \
        php8.5-bcmath \
        php8.5-bz2 \
        php8.5-gmp \
        php8.5-grpc \
        php8.5-imagick \
        php8.5-imap \
        php8.5-interbase \
        php8.5-intl \
        php8.5-ldap \
        php8.5-mailparse \
        php8.5-maxminddb \
        php8.5-memcache \
        php8.5-memcached \
        php8.5-mysql \
        php8.5-oauth \
        php8.5-odbc \
        php8.5-pcov \
        php8.5-pgsql \
        php8.5-pspell \
        php8.5-redis \
        php8.5-soap \
        php8.5-sqlite3 \
        php8.5-ssh2 \
        php8.5-swoole \
        php8.5-tidy \
        php8.5-uuid \
        php8.5-vips \
        php8.5-xdebug \
        php8.5-xmlrpc \
        php8.5-apcu \
        php8.5-cli \
        php8.5-curl \
        php8.5-mbstring \
        php8.5-opcache \
        php8.5-readline \
        php8.5-xml \
        php8.5-zip \
        php8.5-yaml; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Install inotify via PECL
RUN apt-get update && apt-get install -y php8.5-dev && \
    pecl install inotify && \
    echo "extension=inotify.so" > /etc/php/8.5/mods-available/inotify.ini && \
    phpenmod inotify && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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


# Node.js with NVM (Node Version Manager)
ENV NVM_DIR="/root/.nvm"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default lts/* \
    && npm install -g npm@latest \
    && npm install -g @vue/cli \
    && npm install -g vite

# Make NVM and Node available in all shells
RUN echo 'export NVM_DIR="/root/.nvm"' >> /root/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /root/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /root/.bashrc

# Composer
RUN composer self-update --2

## SSH
RUN apt-get update && apt-get install -y openssh-server ssh
RUN mkdir -p /var/run/sshd
RUN echo 'root:test1234' | chpasswd
COPY "sshd_config" "/etc/ssh/sshd_config"

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
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
CMD ["/usr/sbin/php-fpm8.5", "-O" ]

## SSH Port
EXPOSE 22

# Open up fcgi port
EXPOSE 9000