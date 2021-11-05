#!/usr/bin/dumb-init sh

SENSU=/opt/sensu

called=$(basename $0)
called_path=${SENSU}/bin/${called}

: ${HOSTNAME:=$(hostname)}
: ${SENSU_HOSTNAME:=$HOSTNAME}

backend_init() {
    echo "== running backend init..."
    set -e
    ${called_path} init --wait
    INIT_RC=$?
    set +e
    if [ "x$INIT_RC" != "x0" ] && [ "x$INIT_RC" != "x3" ]; then
    echo "== backend init failed - exiting..."
        exit 1
    fi
}

if [ $called = "sensu-agent" ]; then
    : ${SENSU_BACKEND_URL:=ws://${SENSU_HOSTNAME}:8081}

    export SENSU_BACKEND_URL
elif [ $called = "sensu-backend" ]; then
    : ${SENSU_BACKEND_CLUSTER_ADMIN_USERNAME:=admin}
    : ${SENSU_BACKEND_CLUSTER_ADMIN_PASSWORD:=P@ssw0rd!}
    : ${SENSU_BACKEND_API_URL:=http://${SENSU_HOSTNAME}:8080}
    : ${WAIT_PORT:=2379}

    export SENSU_BACKEND_CLUSTER_ADMIN_USERNAME
    export SENSU_BACKEND_CLUSTER_ADMIN_PASSWORD
    export SENSU_BACKEND_API_URL

    backend_init &
fi

${called_path} $@
