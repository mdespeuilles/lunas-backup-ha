FROM ghcr.io/home-assistant/base:3.24

RUN apk add --no-cache ca-certificates curl jq

COPY run.sh /run.sh
RUN chmod 755 /run.sh

CMD ["/run.sh"]
