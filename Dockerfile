FROM alpine:3.15
RUN apk add --no-cache \
    bash \
    jq \
    curl \
    && rm -rf /var/cache/apk
WORKDIR /
COPY run.sh .
ENTRYPOINT ["/run.sh"]
