FROM ghcr.io/guoyk93/acicn/nginx:alpine-3.16 AS utils-nginx
FROM ghcr.io/guoyk93/acicn/debian:11

ENV PHP_VERSION 7.4

#############################
#  Install PHP from Source  #
#############################

# dependencies
RUN apt-get update && \
    apt-get install -y nginx build-essential autoconf cmake cmake-extras openssl libssl-dev libsodium-dev \
    libxml2-dev libsqlite3-dev libgd-dev libxpm-dev libicu-dev libbz2-dev libcurl4-openssl-dev \
    libenchant-2-dev libgmp-dev libldap2-dev libaspell-dev libreadline-dev libsnmp-dev \
    libxslt1-dev libgeoip-dev imagemagick libmemcached-dev libevent-dev liblz4-dev \
    librdkafka-dev libpq-dev libyaml-dev libzip-dev libtidy-dev libmcrypt-dev libonig-dev \
    libmariadb-dev libpcre3-dev libpspell-dev libldap2-dev libsasl2-dev libmagick++-dev \
    subversion libsvn-dev libhunspell-dev git && \
    rm -rf /var/lib/apt/lists/*

# enchant-1.6.1
RUN curl -sSLo enchant.tar.gz 'https://github.com/abiword/enchant/releases/download/enchant-1-6-1/enchant-1.6.1.tar.gz' && \
    mkdir -p /opt/src/enchant && \
    tar -xf enchant.tar.gz -C /opt/src/enchant --strip-components 1 && \
    rm -f enchant.tar.gz && \
    cd /opt/src/enchant && \
    ./configure && \
    make && \
    make install

# build and install php from source
RUN mkdir -p /opt/src/php && \
    curl -sSL -o php.tar.gz 'https://www.php.net/distributions/php-7.4.23.tar.gz' && \
    tar -xf php.tar.gz -C /opt/src/php --strip-components 1 && \
    rm -f php.tar.gz && \
    cd /opt/src/php && \
    ./configure --prefix=/opt --enable-fpm --enable-gd --with-external-gd \
    --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d \
    --with-jpeg --with-webp --with-xpm --with-freetype --enable-bcmath --with-zlib \
    --with-pcre-jit --enable-sockets --enable-soap --with-pdo-mysql --with-mysql-sock \
    --with-mysqli --enable-mysqlnd --with-openssl --with-zip --enable-mbstring \
    --enable-intl --enable-pcntl --with-bz2 --enable-calendar --enable-sysvmsg \
    --enable-sysvsem --enable-sysvshm --with-curl --enable-ftp --with-enchant \
    --enable-exif --with-gmp --with-gettext --with-sodium --enable-dba --with-pspell \
    --with-readline --with-snmp --with-xsl --enable-shmop --with-xmlrpc \
    --with-tidy --with-pgsql --with-pdo-pgsql --enable-phpdbg \
    --enable-phpdbg-webhelper --enable-phpdbg-readline --enable-sigchild \
    --with-pear --with-ldap --with-ldap-sasl && \
    make && make install

# configuration files and other stuff
ENV PATH "/opt/sbin:$PATH"
RUN mkdir -p /var/log/php-fpm
ADD ${PHP_VERSION}/etc /etc

#############################
#  Install Skywalking PHP   #
#############################

# dependencies
RUN apt-get update && \
    apt-get install -y gcc make libclang-dev protobuf-compiler && \
    rm -rf /var/lib/apt/lists/*

# install rust
RUN mkdir -p /opt/src/rust && \
    curl -sSL -o rust.tar.gz 'https://static.rust-lang.org/dist/rust-1.65.0-x86_64-unknown-linux-gnu.tar.gz' && \
    tar -xf rust.tar.gz -C /opt/src/rust --strip-components 1 && \
    rm -f rust.tar.gz && \
    cd /opt/src/rust && \
    ./install.sh --prefix=/opt && \
    cd / && \
    rm -rf /opt/src/rust

# build and install skywalking php agent from latest source
RUN git clone --recursive https://github.com/apache/skywalking-php.git /opt/src/skywalking-php && \
    cd /opt/src/skywalking-php && \
    git checkout -b current 470b8995c8cfd2fcc0af5cb87ba159069ae008e1 && \
    phpize && \
    ./configure && \
    make && \
    make install 

ADD skywalking_php.ini /etc/php.d/skywalking_php.ini

#############################
#      Configurations       #
#############################

# setup nginx with php-fpm
RUN rm -rf /etc/nginx
COPY --from=utils-nginx /etc/nginx /etc/nginx

ENV NGXCFG_DEFAULT_EXTRA_INDEX index.php
ENV NGXCFG_SNIPPETS_ENABLE_SPA true
ENV NGXCFG_SNIPPETS_SPA_INDEX  "/index.php?\$query_string"

ADD index.php /var/www/public/index.php
ADD php.conf /etc/nginx/default.conf.d/php.conf
RUN mkdir -p /etc/nginx/default.fastcgi.d /var/lib/php/session

# minit units
COPY --from=utils-nginx /etc/minit.d/nginx.yml /etc/minit.d/nginx.yml
ADD minit.d /etc/minit.d

# working directory
WORKDIR /var/www