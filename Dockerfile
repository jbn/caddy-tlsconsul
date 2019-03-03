FROM golang:1.12-alpine
MAINTAINER Peter Teich <peter.teich@gmail.com>

ENV CADDY_VERSION 0.11.1

RUN set -x \
    && apk update && apk add --no-cache --upgrade \
        openssl git ca-certificates sed bash busybox

RUN \
    git clone https://github.com/mholt/caddy.git /go/src/github.com/mholt/caddy \
    #    && git checkout tags/v${CADDY_VERSION} \
    && git clone https://github.com/pteich/caddy-tlsconsul.git /go/src/github.com/mholt/caddy/vendor/github.com/pteich/caddy-tlsconsul \
    && cd /go/src/github.com/mholt/caddy \
    && go get -d github.com/caddyserver/builds \
    && go get -d github.com/hashicorp/consul/api

RUN sed -e "s#// This is where other plugins get plugged in (imported)#_ \"github.com/pteich/caddy-tlsconsul\"#" -i /go/src/github.com/mholt/caddy/caddy/caddymain/run.go

WORKDIR /go/src/github.com/mholt/caddy/caddy
RUN go run build.go -goos=linux -goarch=amd64

FROM alpine:latest
LABEL maintainer="peter.teich@gmail.com"
LABEL description="Caddy with integrated TLS Consul Storage plugin"

ENV DUMBINIT_VERSION 1.2.2
ENV CADDYPATH /.caddy

RUN set -x \
    && apk update && apk add --no-cache \
        openssl \
        dpkg \
        ca-certificates \
    && update-ca-certificates \
    && cd /tmp \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/dumb-init "https://github.com/Yelp/dumb-init/releases/download/v${DUMBINIT_VERSION}/dumb-init_${DUMBINIT_VERSION}_${dpkgArch}" \
    && chmod +x /usr/local/bin/dumb-init \
    && rm -rf /tmp/*

COPY --from=0 /go/src/github.com/mholt/caddy/caddy/caddy /bin/caddy
RUN chmod +x /bin/caddy

ENTRYPOINT ["/usr/local/bin/dumb-init","/bin/caddy"]

EXPOSE 80 443 2015
WORKDIR /var/www/html
CMD [""]
