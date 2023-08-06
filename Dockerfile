FROM phpdockerio/php:8.2-fpm

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
    
USER $USERNAME

# Fig
#FIG_LOGIN_TOKEN= \
#RUN export INTEGRATIONS="dotfiles ssh"; \
#    curl -fSsL https://repo.fig.io/scripts/install-headless.sh | /bin/bash || true
#RUN export INTEGRATIONS="daemon"; \
#    curl -fSsL https://repo.fig.io/scripts/install-headless.sh | /bin/bash || true
    
USER root

#RUN export INTEGRATIONS="dotfiles ssh"; \
#    curl -fSsL https://repo.fig.io/scripts/install-headless.sh | /bin/bash || true
#RUN export INTEGRATIONS="daemon"; \
#    curl -fSsL https://repo.fig.io/scripts/install-headless.sh | /bin/bash || true

# Node Repo
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

#RUN add-apt-repository universe \
#    && add-apt-repository multiverse \
#    && add-apt-repository restricted

# Install selected extensions and other stuff
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
    aspell \
    aspell-de \
    build-essential \
    software-properties-common \
    unzip ; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# php-json
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

# php8.2-http php8.2-fileinfo php8.2-gd php8.2-gmagick php8.2-common php8.2-psr
RUN apt-get update; \
    apt-get -y --no-install-recommends install \
        php8.2-amqp \
        php8.2-ast \
        php8.2-bcmath \
        php8.2-bz2 \
        php8.2-gmp \
        php8.2-grpc \
        php8.2-imagick \
        php8.2-imap \
        php8.2-inotify \
        php8.2-interbase \
        php8.2-intl \
        php8.2-ldap \
        php8.2-mailparse \
        php8.2-maxminddb \
        php8.2-mcrypt \
        php8.2-memcache \
        php8.2-memcached \
        php8.2-mysql \
        php8.2-oauth \
        php8.2-odbc \
        php8.2-pcov \
        php8.2-pgsql \
        php8.2-pspell \
        php8.2-redis \
        php8.2-soap \
        php8.2-sqlite3 \
        php8.2-ssh2 \
        php8.2-swoole \
        php8.2-tidy \
        php8.2-uuid \
        php8.2-vips \
        php8.2-xdebug \
        php8.2-xmlrpc \
        php8.2-apcu \
        php8.2-cli \
        php8.2-curl \
        php8.2-mbstring \
        php8.2-opcache \
        php8.2-readline \
        php8.2-xml \
        php8.2-zip \
        php8.2-yaml; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Pecl Redis
#RUN pecl install -o -f redis \
#    &&  rm -rf /tmp/pear \
#    &&  docker-php-ext-enable redis

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

# Globals NPM
RUN npm install -g @vue/cli @vue/cli-service-global svgo @maizzle/cli

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
CMD ["/usr/sbin/php-fpm8.2", "-O" ]

## SSH Port
EXPOSE 22

# Open up fcgi port
EXPOSE 9000