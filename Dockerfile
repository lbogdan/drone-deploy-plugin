FROM alpine:3.18.4

COPY plugin.sh /

RUN apk add --no-cache bash git openssh-client

ENTRYPOINT /bin/bash /plugin.sh
