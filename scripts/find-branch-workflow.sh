#!/usr/bin/env bash
set -euo pipefail

debug="${DEBUG:-}"
circleToken="${CIRCLE_TOKEN:-}"
targetBranch="${TARGET_BRANCH:-}"

if [ "x${circleToken}" = "x" ]; then
    echo "CIRCLE_TOKEN must be set" >&2
    exit 1
fi

if [ "x${targetBranch}" = "x" ]; then
    echo "TARGET_BRANCH must be set" >&2
    exit 1
fi

apiURL="https://circleci.com/api/v2"
slug="gh/sensu/sensu-enterprise-go"
targetWorkflow=""
nextPageToken=""
page=1

while true; do
    queryParams="branch=${targetBranch}"

    if ! [ "x${nextPageToken}" = "x" ]; then
        queryParams+="&page-token=${nextPageToken}"
    fi

    pipelinesURL="${apiURL}/project/${slug}/pipeline?${queryParams}"
    if ! [ "x${debug}" = "x" ]; then
        echo "fetching pipelines for branch: ${targetBranch}, page: ${page}" >&2
        echo "url: ${pipelinesURL}" >&2
    fi

    pipelines=$(curl -fsSL -H "Circle-Token: $circleToken" $pipelinesURL)
    nextPageToken=$(echo $pipelines | jq -r .next_page_token)
    items=$(echo $pipelines | jq -r '.items')

    ((page++))

    if [ "x${items}" = "x[]" ]; then
        if [ "${nextPageToken}" = "null" ]; then
            break
        fi
        continue
    fi

    createdPipelines=$(echo $pipelines | jq -r \
        '[.items[] | select(.state == "created")]')

    if [ "x${createdPipelines}" = "[]" ]; then
        if [ "x${nextPageToken}" = "x" ]; then
            break
        fi
        continue
    fi

    pipelineIDs=$(echo $createdPipelines | jq -r '.[].id')
    for pipelineID in $pipelineIDs; do
        pipelineID=${pipelineID%$'\r'} # strip CR because windows...
        wNextPageToken=""
        wPage=1
        
        while true; do
            wQueryParams=""

            if ! [ "x${wNextPageToken}" = "x" ]; then
                wQueryParams+="page-token=${wNextPageToken}"
            fi

            workflowsURL="${apiURL}/pipeline/${pipelineID}/workflow?${wQueryParams}"
            if ! [ "x${debug}" = "x" ]; then
                echo "fetching workflows for pipeline: ${pipelineID}, page: ${wPage}" >&2
                echo "url: ${workflowsURL}" >&2
            fi

            workflows=$(curl -fsSL -H "Circle-Token: $circleToken" $workflowsURL)
            wNextPageToken=$(echo $workflows | jq -r .next_page_token)

            ((wPage++))

            buildWorkflows=$(echo $workflows | jq -r \
                '[.items[] | select(.name == "build") |
                    select(.status == "success")]')

            if [ "${buildWorkflows}" = "[]" ]; then
                if [ "${wNextPageToken}" = "null" ]; then
                    break
                fi
                continue
            fi

            targetWorkflow=$(echo $buildWorkflows | jq -r '.[0].id')
            break
        done

        if ! [ "x${targetWorkflow}" = "x" ]; then
            break
        fi
    done

    break
done

if [ "x${targetWorkflow}" = "x" ]; then
    echo "no workflow was found for branch: ${targetBranch}" >&2
    exit 1
fi

if ! [ "x${debug}" = "x" ]; then
    echo "found workflow: ${targetWorkflow} for branch: ${targetBranch}" >&2
else
    echo $targetWorkflow
fi
