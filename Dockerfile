FROM alpine:latest
LABEL authors="notdevcody"

RUN apk update \
    && apk add --no-cache bash git curl openjdk21-jre e2fsprogs github-cli

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chown -R root:root /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]