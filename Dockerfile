FROM alpine:latest

# Let's roll
COPY rootfs /

RUN set -xe && \
    apk add --no-cache tzdata bash lftp && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apk del tzdata && \
    chmod +x /backup.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]