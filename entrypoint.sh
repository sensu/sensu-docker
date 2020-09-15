#!/usr/bin/dumb-init sh

SENSU=/opt/sensu

called=$(basename $0)
called_path=${SENSU}/bin/${called}

: ${HOSTNAME:=$(hostname)}
: ${SENSU_HOSTNAME:=$HOSTNAME}

if [ $called = "sensu-agent" ]; then
    : ${SENSU_BACKEND_URL:=ws://${SENSU_HOSTNAME}:8080}

    export SENSU_BACKEND_URL
elif [ $called = "sensu-backend" ]; then
    : ${SENSU_BACKEND_CLUSTER_ADMIN_USERNAME:=admin}
    : ${SENSU_BACKEND_CLUSTER_ADMIN_PASSWORD:=P@ssw0rd!}
    : ${SENSU_BACKEND_API_URL:=http://${SENSU_HOSTNAME}:8080}
    : ${SENSU_BACKEND_ETCD_INITIAL_CLUSTER:=default=http://${SENSU_HOSTNAME}:2380}
    : ${SENSU_BACKEND_ETCD_ADVERTISE_CLIENT_URLS:=http://${SENSU_HOSTNAME}:2379}
    : ${SENSU_BACKEND_ETCD_INITIAL_ADVERTISE_PEER_URLS:=http://${SENSU_HOSTNAME}:2380}
    : ${SENSU_BACKEND_ETCD_LISTEN_CLIENT_URLS:=http://[::]:2379}
    : ${SENSU_BACKEND_ETCD_LISTEN_PEER_URLS:=http://[::]:2380}
    : ${WAIT_PORT:=2379}

    export SENSU_BACKEND_CLUSTER_ADMIN_USERNAME
    export SENSU_BACKEND_CLUSTER_ADMIN_PASSWORD
    export SENSU_BACKEND_API_URL
    export SENSU_BACKEND_ETCD_INITIAL_CLUSTER
    export SENSU_BACKEND_ETCD_ADVERTISE_CLIENT_URLS
    export SENSU_BACKEND_ETCD_INITIAL_ADVERTISE_PEER_URLS
    export SENSU_BACKEND_ETCD_LISTEN_CLIENT_URLS
    export SENSU_BACKEND_ETCD_LISTEN_PEER_URLS

    # wait for etcd to become available
    # TODO(JK): move this logic into the backend init logic so we don't need to
    # determine which host & port to check in this script.
    while /bin/true; do
        echo "== waiting for ${SENSU_HOSTNAME}:${WAIT_PORT} to become available before running backend-init..."
        NC_RC=0
        set -e
        nc -z $SENSU_HOSTNAME $WAIT_PORT || NC_RC=$?
        set +e
        if [ "x$NC_RC" = "x0" ]; then
            echo "== running backend init..."
            set -e
            ${called_path} init
            INIT_RC=$?
            set +e
            if [ "x$INIT_RC" != "x0" ] && [ "x$INIT_RC" != "x3" ]; then
                echo "== backend init failed - exiting..."
                exit 1
            fi
            break
        else
            sleep 1.0
        fi
    done &
fi

${called_path} $@
