FROM php:7.4-fpm

RUN : && \
    # install apt packages
    apt-get update && \
    apt-get install -y gcc make libclang-dev protobuf-compiler git && \
    rm -rf /var/lib/apt/lists/* && \
    # install rust
    mkdir -p rust && \
    curl -sSL -o rust.tar.gz 'https://static.rust-lang.org/dist/rust-1.65.0-x86_64-unknown-linux-gnu.tar.gz' && \
    tar -xf rust.tar.gz -C ./rust --strip-components 1 && \
    rm -f rust.tar.gz && \
    cd rust && \
    ./install.sh && \
    cd .. && rm -rf rust && \
    # install apache skywalking-php
    git clone --recursive https://github.com/apache/skywalking-php.git && \
    cd skywalking-php && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    cd .. && rm -rf skywalking-php


