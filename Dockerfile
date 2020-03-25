FROM alpine:latest

# Let's roll
COPY rootfs /

RUN set -xe && \
    apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apk del tzdata && \
    wget --no-check-certificate https://github.com/teddysun/across/raw/master/backup.sh -P / && \
    chmod +x /backup.sh && \
    chmod +x /usr/bin/start.sh

CMD ["/start.sh"]