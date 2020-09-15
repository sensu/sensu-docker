#!/usr/bin/env bash
set -euo pipefail

_jq() {
    echo $1 | base64 --decode | jq -r $2
}

section() {
    echo
    echo "============================================================================================================================================"
    echo " $1"
    echo "============================================================================================================================================"
}

target_workflow="${1:-}"
target_job="${2:-}"
destination="${3:-}"
filter="${4:-}"

export target_workflow
export target_job
export destination
export filter

if [ "x${target_workflow}" = "x" ]; then
    echo "target workflow not specified"
    exit 1
fi

if [ "x${target_job}" = "x" ]; then
    echo "target job not specified"
    exit 1
fi

if [ "x${destination}" = "x" ]; then
    echo "destination not specified"
    exit 1
fi

section "called arguments"
echo "Target Workflow: ${target_workflow}"
echo "Target Job: ${target_job}"
echo "Destination: ${destination}"
echo "Filter: ${filter}"

section "fetching jobs for workflow: ${target_workflow}"
jobs_json="$(curl -fsSLH "Circle-Token: $CIRCLE_TOKEN" https://circleci.com/api/v2/workflow/$target_workflow/job)"
echo $jobs_json | jq .

section "fetching project slug"
project_slug="$(echo $jobs_json | jq -r '.items[0].project_slug')"
if [ "x${project_slug}" = "x" ]; then
    echo "error: failed to find project slug"
    exit 1
fi
echo $project_slug

section "fetching job number for job: ${target_job}"
job_number=$(echo $jobs_json | jq -r ".items[] | select(.name == \"$target_job\") | .job_number")
if [ "x${job_number}" = "x" ]; then
    echo "error: failed to find job: ${target_job}"
    exit 1
fi
echo "job number: ${job_number}"

section "fetching artifact urls with filter: $filter for job: $target_job"
job_url="https://circleci.com/api/v2/project/${project_slug}/${job_number}/artifacts"
artifact_json=$(mktemp)
echo "created tmp file: ${artifact_json}"
curl -fsSLH "Circle-Token: $CIRCLE_TOKEN" -o $artifact_json $job_url
cat $artifact_json | jq .
for row in $(cat $artifact_json | jq -r ".items[] | select(.path | contains(\"$filter\")) | @base64"); do
    output_path="${destination}/$(_jq $row '.path')"
    section "downloading artifact: $(_jq $row '.path') from job: $target_job"
    mkdir -p $(dirname $output_path)
    curl -fsSLH "Circle-Token: $CIRCLE_TOKEN" -o ${output_path} $(_jq $row '.url')
    echo "downloaded to: $output_path"
done
