# Sensu Docker

This repository contains the code required to build Docker images.

## Building Images

This repository requires the [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
feature to be installed & enabled.

The Alpine and RHEL 7 Dockerfiles build `etcdctl` from the pinned Sensu etcd
source. Builds require `GO_VERSION`, `ALPINE_VERSION`, `ETCD_VERSION`,
`ETCD_SOURCE_REVISION`, and `ETCD_SOURCE_SHA256` build arguments. CircleCI
provides these from the pipeline parameters in `.circleci/config.yml`; use the
same values for local builds.

1. Clone this repository.

2. Create target directories for each of the platforms you wish to build Docker images
for. E.g.

``` sh
mkdir -p target/linux/amd64 target/linux/arm64 target/linux/arm/v6
```

3. Download the [Binary archives](https://sensu.io/downloads) for each of the platforms
that directories were created for in the previous step and extract them to their
respective target directories.

4. Use `docker buildx build` with the path of the Dockerfile to use and with the `--platform`
flag to build the images.

For local builds, use the same values as the pipeline parameters in
`.circleci/config.yml`:

```sh
build_args=(
  --build-arg GO_VERSION=1.27.4
  --build-arg ALPINE_VERSION=3.24
  --build-arg ETCD_VERSION=3.6.13
  --build-arg ETCD_SOURCE_REVISION=607cf99bfe15fac97980ac560371ed5008779109
  --build-arg ETCD_SOURCE_SHA256=b5a23bf0483bde45ff737a1e77df848909415ce68d2cb191927dd5413c283188
)
docker buildx build . --file dockerfiles/alpine/Dockerfile --platform linux/amd64,linux/arm64,linux/arm/v6 "${build_args[@]}"
docker buildx build . --file dockerfiles/redhat7/Dockerfile --platform linux/amd64 "${build_args[@]}"
```


## Manually Triggered Builds (for internal use only)

The following instructions are for internal use only, for generating builds with the Sensu Go commercial distribution.

Builds can be triggered using the `scripts/trigger-build.sh` script for a given
CircleCI workflow ID or git branch.

Both `curl` and `jq` must be installed for this script to work.

#### Environment Variables

**Note:** If both `TARGET_WORKFLOW` and `TARGET_BRANCH` are set then
`TARGET_WORKFLOW` will take precedence.

Environment Variable | Default Value | Description
-------------------- | ------------- | -----------
`CIRCLE_TOKEN` | | Your CircleCI API Token.
`TARGET_WORKFLOW` | | The CircleCI workflow ID of the [sensu-enterprise-go][2] build to build packages for.
`TARGET_BRANCH` | | The git branch of [sensu-enterprise-go][1] to build packages for.
`BRANCH` | `main` | The branch of this repository to trigger the CI build with.

### Trigger a build for a workflow

Simply replace `REPLACEME` with the CircleCI workflow ID of the
[sensu-enterprise-go][2]
build that you would like to package.

```sh
TARGET_WORKFLOW="REPLACEME" ./scripts/trigger-build.sh
```

### Trigger a build for a git branch

Simply replace `REPLACEME` with the git branch of the
[sensu-enterprise-go][1]
build that you would like to package.

```sh
TARGET_BRANCH="REPLACEME" ./scripts/trigger-build.sh
```

## Build Parameters (for internal use only)

The following instructions are for internal use only, for generating builds with the Sensu Go commercial distribution.

### target_workflow

**Type:** `string`
**Default:** `""`

The remote workflow id of the desired build. It is used to fetch the build
artifacts from each of the required jobs in the remote workflow.

When value is set to an empty string, the latest successful Enterprise build
workflow is selected by branch: `develop/*` and `release/*` Docker branches use
the same Enterprise branch, `main` uses Enterprise `main`, and other branches
use Enterprise `develop/6`.

## Publishing CircleCI Orbs (for internal use only)

The following instructions are for internal use only, for generating builds with the Sensu Go commercial distribution.

### Development Versions

Anyone in the GitHub organization can publish development versions of orbs.
These versions will expire after 90 days and should not be used in the `main` or
`release/` branches. A dev version can be published by running the following,
specifying the orb name & dev version:

``` sh
circleci orb pack src | circleci orb publish - sensu/orb@dev:version
```

### Stable Versions

For now, CircleCI limits the publishing of CircleCI orbs to GitHub Organization
administrators. If a new release of any of our CircleCI orbs is needed, please
contact one of the GitHub Organization admins.

Orbs can be published by checking out the latest code from the orb repository
and then running the following, specifying the orb name & dev version & whether
or not to use a major, minor, or patch level version bump:

``` sh
circleci orb pack src | circleci orb publish promote sensu/orb@dev:version bump-type
```

[1]: https://github.com/sensu/sensu-enterprise-go/branches
[2]: https://app.circleci.com/pipelines/github/sensu/sensu-enterprise-go
