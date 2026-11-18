ARG ALPINE_VERSION=3.24
FROM --platform=$BUILDPLATFORM golang:1.27.4-alpine3.24 AS etcdctl-build
ARG TARGETPLATFORM
ARG TARGETARCH
ARG ETCD_VERSION=3.7.3

RUN apk add --no-cache ca-certificates curl && \
    mkdir /src && \
    curl -fsSLo /tmp/etcd.tar.gz "https://github.com/etcd-io/etcd/archive/refs/tags/v${ETCD_VERSION}.tar.gz" && \
    tar -xzf /tmp/etcd.tar.gz --strip-components=1 -C /src
WORKDIR /src/etcdctl
RUN go mod edit -toolchain=go1.27.4 -require=golang.org/x/net@v0.63.0 && \
    case "${TARGETARCH}" in \
      amd64 | arm64 | ppc64le) \
        GOWORK=off CGO_ENABLED=0 GOOS=linux GOARCH="${TARGETARCH}" go build -mod=mod -trimpath -o /etcdctl . \
        ;; \
      *) \
        printf '#!/bin/sh\necho "etcdctl is not available for platform: %s"\n' "${TARGETPLATFORM}" > /etcdctl \
        ;; \
    esac && \
    chmod +x /etcdctl

FROM alpine:${ALPINE_VERSION}
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG ALPINE_VERSION

MAINTAINER Sensu, Inc. Engineering <engineering@sensu.io>

LABEL name="sensu/sensu" \
      maintainer="engineering@sensu.io" \
      vendor="Sensu, Inc." \
      license="All Rights Reserved. For details, visit https://sensu.io/sensu-license" \
      summary="Sensu Go - Full-stack monitoring" \
      description="Sensu is an event pipeline and monitoring system for everything from the server closet to the serverless application." \
      url="https://sensu.io/" \
      run="docker run -d --name sensu-backend sensu/sensu" \
      io.k8s.description="Sensu" \
      io.k8s.display-name="Sensu" \
      io.openshift.expose-services="8081:http,8080:http,3000:http,2379:http" \
      io.openshift.tags="sensu,monitoring,observability"

VOLUME /var/lib/sensu

EXPOSE 2379 2380 8080 8081 3000

RUN echo -e "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main\nhttps://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community\n" > /etc/apk/repositories

# tzdata: https://wiki.alpinelinux.org/wiki/Setting_the_timezone
RUN apk add --no-cache \
    ca-certificates \
    dumb-init \
    tzdata \
    'zlib>=1.4-r0' && \
    ln -sf /opt/sensu/bin/entrypoint.sh /usr/local/bin/sensu-agent && \
    ln -sf /opt/sensu/bin/entrypoint.sh /usr/local/bin/sensu-backend && \
    ln -sf /opt/sensu/bin/sensuctl /usr/local/bin/sensuctl

COPY --from=etcdctl-build /etcdctl /usr/local/bin/etcdctl

COPY target/${TARGETPLATFORM}/sensu-backend /opt/sensu/bin/sensu-backend
COPY target/${TARGETPLATFORM}/sensu-agent /opt/sensu/bin/sensu-agent
COPY target/${TARGETPLATFORM}/sensuctl /opt/sensu/bin/sensuctl
COPY entrypoint.sh /opt/sensu/bin/entrypoint.sh

RUN addgroup -S -g 10001 sensu
RUN adduser -DHS -u 10001 sensu -G sensu -h /var/lib/sensu

RUN mkdir -pv /etc/sensu
RUN mkdir -pv /var/cache/sensu
RUN mkdir -pv /var/lib/sensu
RUN mkdir -pv /var/log/sensu
RUN mkdir -pv /var/run/sensu

RUN chown -R sensu:sensu /etc/sensu
RUN chown -R sensu:sensu /var/cache/sensu
RUN chown -R sensu:sensu /var/lib/sensu
RUN chown -R sensu:sensu /var/log/sensu
RUN chown -R sensu:sensu /var/run/sensu

CMD ["sensu-backend"]