FROM alpine:3.21
LABEL org.opencontainers.image.source="https://github.com/jmpa-io/post-to-slack" \
      org.opencontainers.image.description="A GitHub Action for sending notifications from running jobs to Slack." \
      org.opencontainers.image.licenses="MIT"
# versions are not pinned: alpine drops old package versions from the index.
# hadolint ignore=DL3018
RUN apk add --no-cache bash jq curl
WORKDIR /action
COPY run.sh .
ENTRYPOINT ["/action/run.sh"]
