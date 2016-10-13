FROM ubuntu:16.04

MAINTAINER Tran Duc Thang <thangtd90@gmail.com>

RUN DEBIAN_FRONTEND=noninteractive
RUN locale-gen en_US.UTF-8

ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=UTF-8
ENV LANG=en_US.UTF-8
ENV TERM xterm

# Install "software-properties-common" (for the "add-apt-repository")
RUN apt-get update && apt-get install -y \
    software-properties-common

# Install Mysql
RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections \
    && echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections \
    && apt-get install -y mysql-server

# Install Redis, Nginx, Mongo
RUN apt-get -y --force-yes install nginx redis-server mongodb supervisor \
    && mkdir -p /data/db

# Add the "PHP 7" ppa
RUN add-apt-repository -y \
    ppa:ondrej/php

# Install PHP-CLI 7, some PHP extentions and some useful Tools with APT
RUN apt-get update && apt-get install -y --force-yes \
        php7.0-cli \
        php7.0-common \
        php7.0-curl \
        php7.0-json \
        php7.0-xml \
        php7.0-mbstring \
        php7.0-mcrypt \
        php7.0-mysql \
        php7.0-pgsql \
        php7.0-sqlite \
        php7.0-sqlite3 \
        php7.0-zip \
        php7.0-memcached \
        php7.0-gd \
        php7.0-fpm \
        php7.0-xdebug \
        php-dev \
        libcurl4-openssl-dev \
        libedit-dev \
        libssl-dev \
        libxml2-dev \
        xz-utils \
        sqlite3 \
        libsqlite3-dev \
        git \
        curl \
        vim \
        nano \
        net-tools \
        pkg-config \
        iputils-ping

# remove load xdebug extension (only load on phpunit command)
RUN sed -i 's/^/;/g' /etc/php/7.0/cli/conf.d/20-xdebug.ini

# Add bin folder of composer to PATH.
RUN echo "export PATH=${PATH}:/var/www/html/vendor/bin:/root/.composer/vendor/bin" >> ~/.bashrc

# Install Composer
RUN curl -s http://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer global require "squizlabs/php_codesniffer=*"

# Load xdebug Zend extension with phpunit command
RUN echo "alias phpunit='php -dzend_extension=xdebug.so /var/www/laravel/vendor/bin/phpunit'" >> ~/.bashrc

# Install mongodb extension
RUN pecl install mongodb
RUN echo "extension=mongodb.so" >> /etc/php/7.0/cli/php.ini
RUN echo "extension=mongodb.so" >> /etc/php/7.0/fpm/php.ini

# Install Nodejs
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g n \
    && n stable \
    && npm install -g gulp bower eslint babel-eslint eslint-plugin-react

# Install SASS
RUN curl -O http://ftp.ruby-lang.org/pub/ruby/stable-snapshot.tar.gz \
    && tar -xzvf stable-snapshot.tar.gz \
    && cd stable-snapshot/ \
    && ./configure \
    && make \
    && make install \
    && gem install sass

# Install yarn
RUN npm install -g yarn

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www/html
EXPOSE 80 443

COPY default.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Default command
CMD ["/usr/bin/supervisord"]
