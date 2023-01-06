# php-skywalking-debug

https://github.com/apache/skywalking/issues/10240

## How to reproduce

This image is build with `Apache Skywalking Agent` enabled, but without a available `Apache Skywalking Server` address.

1. Start container

    ```shell
    docker run -ti --rm --name php-skywalking-debug -p 8088:80 ghcr.io/guoyk93/php-skywalking-debug:latest
    ```

2. Stress the container with `Apache Benchmark Tool`

    ```shell
    ab -n 10000 -c 200 http://127.0.0.1:8088/
    ```

3. At some point of time, approximate 5000 (`pm.max_children*100`) requests done, whole `php-fpm` process will freeze. Any new http request will respond with `nginx` `504 Gateway Time-out`, until container restart.

## Credits

Guo Y.K., MIT License
