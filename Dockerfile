FROM alpine:3.21
RUN apk add --update --no-cache \
    bash \
    jq \
    curl \
    && rm -rf /var/cache/apk
WORKDIR /action
COPY run.sh .
ENTRYPOINT ["/action/run.sh"]
