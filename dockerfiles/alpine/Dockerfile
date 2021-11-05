FROM alpine:3.12 as etcdctl-fetch
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG ETCD_VERSION="3.5.0"

RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM"
RUN echo -e "https://alpine.global.ssl.fastly.net/alpine/v3.12/main\nhttps://alpine.global.ssl.fastly.net/alpine/v3.12/community\n" > /etc/apk/repositories
RUN apk add --no-cache ca-certificates curl

RUN export TARGET_ARCH=$(apk --print-arch) && \
case "$TARGET_ARCH" in \
  x86_64) export ETCD_ARCH="amd64" ;; \
  aarch64) export ETCD_ARCH="arm64" ;; \
  ppc64le) export ETCD_ARCH="ppc64le" ;; \
esac; \
case "$TARGET_ARCH" in \
  x86_64 | aarch64 | ppc64le) \
  export ETCD_NAME="etcd-v${ETCD_VERSION}-linux-${ETCD_ARCH}" && \
  curl -fsSLO https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/$ETCD_NAME.tar.gz && \
  tar xvf $ETCD_NAME.tar.gz --strip-components 1 $ETCD_NAME/etcd $ETCD_NAME/etcdctl \
  ;; \
  *) \
  printf "#!/bin/sh\necho \"etcdctl is not available for platform: ${TARGETPLATFORM}\"\n" > /etcdctl \
  ;; \
esac

RUN chmod +x /etcdctl

FROM alpine:3.12
ARG TARGETPLATFORM
ARG BUILDPLATFORM

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

RUN echo -e "https://alpine.global.ssl.fastly.net/alpine/v3.12/main\nhttps://alpine.global.ssl.fastly.net/alpine/v3.12/community\n" > /etc/apk/repositories
RUN apk add --no-cache ca-certificates dumb-init && \
    ln -sf /opt/sensu/bin/entrypoint.sh /usr/local/bin/sensu-agent && \
    ln -sf /opt/sensu/bin/entrypoint.sh /usr/local/bin/sensu-backend && \
    ln -sf /opt/sensu/bin/sensuctl /usr/local/bin/sensuctl

COPY --from=etcdctl-fetch etcdctl /usr/local/bin/etcdctl

COPY target/$TARGETPLATFORM/sensu-backend /opt/sensu/bin/sensu-backend
COPY target/$TARGETPLATFORM/sensu-agent /opt/sensu/bin/sensu-agent
COPY target/$TARGETPLATFORM/sensuctl /opt/sensu/bin/sensuctl
COPY entrypoint.sh /opt/sensu/bin/entrypoint.sh

RUN addgroup -S sensu
RUN adduser -DHS sensu -G sensu -h /var/lib/sensu

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
