ARG GO_VERSION=1.27.4
ARG ALPINE_VERSION=3.24

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS etcdctl-build
ARG TARGETPLATFORM
ARG TARGETARCH
ARG BUILDPLATFORM
ARG ETCD_SOURCE_REVISION=1b1ef2de63da0afae672ef5ddd411c7419921c23

RUN echo "Building on ${BUILDPLATFORM} for ${TARGETPLATFORM}"

RUN set -eu; \
    apk add --no-cache ca-certificates git; \
    git clone --filter=blob:none --no-checkout https://github.com/sensu/etcd.git /src/etcd; \
    git -C /src/etcd checkout --detach "${ETCD_SOURCE_REVISION}"; \
    actual_revision="$(git -C /src/etcd rev-parse HEAD)"; \
    if [ "${actual_revision}" != "${ETCD_SOURCE_REVISION}" ]; then \
      echo "Expected etcd revision ${ETCD_SOURCE_REVISION}, got ${actual_revision}" >&2; \
      exit 1; \
    fi
WORKDIR /src/etcd/etcdctl
RUN --mount=type=cache,id=etcdctl-gomod,target=/go/pkg/mod,sharing=locked \
    --mount=type=cache,id=etcdctl-buildcache,target=/root/.cache/go-build,sharing=locked \
    set -eu; \
    if [ "${TARGETARCH}" != "amd64" ]; then \
      echo "RHEL 9 etcdctl is supported only on linux/amd64" >&2; \
      exit 1; \
    fi; \
    GOWORK=off CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -mod=readonly \
      -trimpath \
      -ldflags "-X=go.etcd.io/etcd/api/v3/version.GitSHA=${ETCD_SOURCE_REVISION}" \
      -o /etcdctl .; \
    chmod +x /etcdctl

FROM registry.access.redhat.com/ubi9/ubi:9.9
ARG TARGETPLATFORM
ARG BUILDPLATFORM

LABEL name="sensu/sensu-rhel9" \
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

# ubi9 base already ships curl-minimal (provides /usr/bin/curl); installing
# "curl" conflicts with it, so only add the packages not present in the base.
RUN dnf install -y libpcap nmap-ncat && dnf clean all

RUN case "$TARGETPLATFORM" in \
  "linux/amd64") export DUMB_INIT_ARCH="amd64" ;; \
  "linux/s390x") export DUMB_INIT_ARCH="s390x" ;; \
esac; \
curl -fL -o /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 && \
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
