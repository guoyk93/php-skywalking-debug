FROM php:7.4-fpm

RUN apt-get update && \
    apt-get install -y gcc make libclang-dev protobuf-compiler && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/rust && \
    curl -sSL -o rust.tar.gz 'https://static.rust-lang.org/dist/rust-1.65.0-x86_64-unknown-linux-gnu.tar.gz' && \
    tar -xf rust.tar.gz -C /opt/rust --strip-components 1 && \
    rm -f rust.tar.gz && \
    cd /opt/rust && \
    ./install.sh && \
    cd / && \
    rm -rf /opt/rust
