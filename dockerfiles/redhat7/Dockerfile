ARG GO_VERSION
ARG ALPINE_VERSION

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS etcdctl-build
ARG TARGETPLATFORM
ARG TARGETARCH
ARG BUILDPLATFORM
ARG ETCD_VERSION
ARG ETCD_SOURCE_REVISION
ARG ETCD_SOURCE_SHA256

RUN echo "Building on ${BUILDPLATFORM} for ${TARGETPLATFORM}"

RUN apk add --no-cache ca-certificates coreutils curl && \
    mkdir /src && \
    curl -fsSLo /tmp/etcd.tar.gz "https://github.com/sensu/etcd/archive/${ETCD_SOURCE_REVISION}.tar.gz" && \
    printf '%s  %s\n' "${ETCD_SOURCE_SHA256}" /tmp/etcd.tar.gz | sha256sum -c - && \
    tar -xzf /tmp/etcd.tar.gz --strip-components=1 -C /src
WORKDIR /src/etcdctl
RUN --mount=type=cache,id=etcdctl-gomod,target=/go/pkg/mod,sharing=locked \
    --mount=type=cache,id=etcdctl-buildcache,target=/root/.cache/go-build,sharing=locked \
    case "${TARGETARCH}" in \
      amd64 | ppc64le) \
        GOWORK=off CGO_ENABLED=0 GOOS=linux GOARCH="${TARGETARCH}" go build \
          -mod=readonly \
          -trimpath \
          -ldflags "-X=go.etcd.io/etcd/api/v3/version.Version=${ETCD_VERSION} -X=go.etcd.io/etcd/api/v3/version.GitSHA=${ETCD_SOURCE_REVISION}" \
          -o /etcdctl . \
        ;; \
      *) \
        printf '#!/bin/sh\necho "etcdctl is not available for platform: %s"\n' "${TARGETPLATFORM}" > /etcdctl \
        ;; \
    esac && chmod +x /etcdctl

FROM registry.access.redhat.com/rhel7/rhel-tools as rhel-tools
ARG TARGETPLATFORM
ARG BUILDPLATFORM

FROM registry.access.redhat.com/rhel7/rhel
ARG TARGETPLATFORM
ARG BUILDPLATFORM

MAINTAINER Sensu, Inc. Engineering <engineering@sensu.io>

LABEL name="sensu/sensu-rhel" \
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

RUN case "$TARGETPLATFORM" in \
  "linux/amd64") export DUMB_INIT_ARCH="amd64" ;; \
  "linux/ppc64le") export DUMB_INIT_ARCH="ppc64el" ;; \
  "linux/s390x") export DUMB_INIT_ARCH="s390x" ;; \
esac; \
curl -L -o /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 && \
chmod +x /usr/bin/dumb-init

RUN ln -sf /opt/sensu/bin/entrypoint.sh /usr/local/bin/sensu-agent && \
  ln -sf /opt/sensu/bin/entrypoint.sh /usr/local/bin/sensu-backend && \
  ln -sf /opt/sensu/bin/sensuctl /usr/local/bin/sensuctl

COPY target/licenses /licenses
COPY target/$TARGETPLATFORM/sensu-backend /opt/sensu/bin/sensu-backend
COPY target/$TARGETPLATFORM/sensu-agent /opt/sensu/bin/sensu-agent
COPY target/$TARGETPLATFORM/sensuctl /opt/sensu/bin/sensuctl
COPY entrypoint.sh /opt/sensu/bin/entrypoint.sh

COPY --from=etcdctl-build /etcdctl /usr/local/bin/etcdctl
COPY --from=rhel-tools /usr/lib64/libpcap.so.1 /usr/lib64/libpcap.so.1
COPY --from=rhel-tools /usr/bin/nc /usr/local/bin/nc

RUN groupadd -g 10001 sensu
RUN useradd -r -u 10001 -g sensu -d /var/lib/sensu -s /bin/nologin sensu

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
