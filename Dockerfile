FROM alpine:latest
RUN apk add --update --no-cache \
    bash \
    jq \
    curl \
    && rm -rf /var/cache/apk
WORKDIR /
COPY run.sh .
ENTRYPOINT ["/run.sh"]
