#!/usr/bin/env bash
set -euo pipefail

debug="${DEBUG:-0}"
scriptsPath=$(dirname ${BASH_SOURCE[0]})
circleToken="${CIRCLE_TOKEN:-}"
targetWorkflow="${TARGET_WORKFLOW:-}"
targetBranch="${TARGET_BRANCH:-}"
branch="${BRANCH:-main}"

if [ "x${circleToken}" = "x" ]; then
    echo "CIRCLE_TOKEN must be set" >&2
    exit 1
fi

if [ "x${targetWorkflow}" = "x" ] && [ "x${targetBranch}" = "x" ]; then
    echo "TARGET_WORKFLOW or TARGET_BRANCH must be set" >&2
    exit 1
fi

if [ "x${targetWorkflow}" = "x" ]; then
    export CIRCLE_TOKEN=${circleToken}
    export TARGET_BRANCH=${targetBranch}

    targetWorkflow=$(${scriptsPath}/find-branch-workflow.sh)
    echo "triggering build for target workflow: ${targetWorkflow}"
fi

jsonBody='{"branch":"'$branch'","parameters":{'
jsonBody+='"target_workflow":"'$targetWorkflow'",'
jsonBody+='}}'

extraOpts="-fsS"
if [ "${debug}" = "1" ]; then
    extraOpts="-v"
fi

curl -L -X POST \
    $extraOpts \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Circle-Token: ${circleToken}" \
    -d $jsonBody \
    https://circleci.com/api/v2/project/gh/sensu/sensu-docker/pipeline
