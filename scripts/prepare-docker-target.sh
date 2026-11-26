#!/usr/bin/env bash
# Prepares the target/ directory for a Docker image build. This mirrors the
# CircleCI pre-steps of the build-docker jobs in .circleci/config.yml:
#   - fetches build metadata (commit-date, version, build-number, git-revision,
#     git-branch) and exports them as the same variables CircleCI uses
#   - fetches the store-licenses artifacts into target/licenses
#   - fetches and verifies the sensu binaries into target/<platform>
#
# Usage: prepare-docker-target.sh <all|amd64>
#   all   - every platform used by the Alpine image
#   amd64 - linux/amd64 only (RHEL/UBI images)
#
# Required environment (same names as CircleCI):
#   CIRCLE_TOKEN     CircleCI API token
#   TARGET_WORKFLOW  CircleCI workflow ID of the Enterprise build
#   CIRCLE_BRANCH    branch of this repository (optional, for tag names)
#
# If GITHUB_ENV is set, the exported variables are appended to it.
set -euo pipefail

mode="${1:-}"
scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fetch="${scripts_dir}/circleci-fetch-artifacts.sh"

case "${mode}" in
    all | amd64) ;;
    *)
        echo "usage: $0 <all|amd64>" >&2
        exit 1
        ;;
esac

: "${CIRCLE_TOKEN:?CIRCLE_TOKEN must be set}"
: "${TARGET_WORKFLOW:?TARGET_WORKFLOW must be set}"

mkdir -pv target

# setup-metadata
for filter in commit-date version build-number git-revision git-branch; do
    "${fetch}" "${TARGET_WORKFLOW}" build-linux_amd64 target "${filter}"
done

read_meta() {
    tr -d '\n' <"target/$1"
}

COMMIT_DATE="$(read_meta commit-date)"
SENSU_VERSION="$(read_meta version)"
BUILD_NUMBER="$(read_meta build-number)"
TARGET_REVISION="$(read_meta git-revision)"
TARGET_BRANCH="$(read_meta git-branch)"
TARGET_BRANCH_NO_SLASHES="${TARGET_BRANCH//\//_}"
CIRCLE_BRANCH="${CIRCLE_BRANCH:-}"
CIRCLE_BRANCH_NO_SLASHES="${CIRCLE_BRANCH//\//_}"

for var in COMMIT_DATE SENSU_VERSION BUILD_NUMBER TARGET_REVISION TARGET_BRANCH; do
    if [ -z "${!var}" ]; then
        echo "${var} is empty" >&2
        exit 1
    fi
done

export COMMIT_DATE SENSU_VERSION BUILD_NUMBER TARGET_REVISION TARGET_BRANCH
export TARGET_BRANCH_NO_SLASHES CIRCLE_BRANCH CIRCLE_BRANCH_NO_SLASHES

if [ -n "${GITHUB_ENV:-}" ]; then
    for var in COMMIT_DATE SENSU_VERSION BUILD_NUMBER TARGET_REVISION TARGET_BRANCH \
        TARGET_BRANCH_NO_SLASHES CIRCLE_BRANCH CIRCLE_BRANCH_NO_SLASHES; do
        echo "${var}=${!var}" >>"${GITHUB_ENV}"
    done
fi

echo "SENSU_VERSION=${SENSU_VERSION} BUILD_NUMBER=${BUILD_NUMBER} TARGET_REVISION=${TARGET_REVISION}"

# fetch-licenses
"${fetch}" "${TARGET_WORKFLOW}" store-licenses target/licenses ""

# verify-or-unsupported: a stub is created for platforms without a binary, so
# the Dockerfile COPY instructions still succeed (matches CircleCI behaviour).
verify_or_stub() {
    local dir="$1" bin="$2" supported="$3"
    if [ "${supported}" = "true" ]; then
        verify_binary "${dir}" "${bin}"
    else
        printf '#!/bin/sh\necho "%s is not available for this platform"\nexit 1\n' "${bin}" >"${dir}/${bin}"
        chmod a+x "${dir}/${bin}"
    fi
}

verify_binary() {
    local dir="$1" bin="$2"
    if ! (cd "${dir}" && file "${bin}" | grep -q executable); then
        (cd "${dir}" && file "${bin}")
        echo "${dir}/${bin} is not an executable" >&2
        exit 1
    fi
    # Same as CircleCI verify-binary: run "version" everywhere except s390x.
    if [ "${dir}" != "target/linux/s390x" ]; then
        (cd "${dir}" && "./${bin}" version)
    fi
}

# fetch-and-verify-binaries <job> <destination> <supports_agent> <supports_backend> <supports_cli>
fetch_and_verify() {
    local job="$1" dest="$2" agent="$3" backend="$4" cli="$5"

    "${fetch}" "${TARGET_WORKFLOW}" "${job}" "${dest}" ".tar.gz"
    (cd "${dest}" && find . -type f -name '*.tar.gz' -exec echo "extracting: {}" \; -exec tar -zxf {} \;)

    verify_or_stub "${dest}" sensu-agent "${agent}"
    verify_or_stub "${dest}" sensu-backend "${backend}"
    verify_or_stub "${dest}" sensuctl "${cli}"
    verify_binary "${dest}" sensu-agent
}

if [ "${mode}" = "all" ]; then
    fetch_and_verify build-linux_386 target/linux/386 true false true
    fetch_and_verify build-linux_amd64 target/linux/amd64 true true true
    fetch_and_verify build-linux_arm_6 target/linux/arm/v6 true false true
    fetch_and_verify build-linux_arm_7 target/linux/arm/v7 true false true
    fetch_and_verify build-linux_arm64 target/linux/arm64 true true true
    fetch_and_verify build-linux_ppc64le target/linux/ppc64le true true true
    fetch_and_verify build-linux_s390x target/linux/s390x true false true
else
    fetch_and_verify build-linux_amd64 target/linux/amd64 true true true
fi

echo "target/ prepared (mode: ${mode})"
