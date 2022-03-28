FROM alpine:3.15
RUN apk add --no-cache \
    bash=5.1.16-r0 \
    jq=1.6-r1 \
    curl=7.80.0-r0 \
    && rm -rf /var/cache/apk
WORKDIR /
COPY run.sh .
ENTRYPOINT ["/run.sh"]
