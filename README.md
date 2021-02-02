# Sensu Docker

This repository contains the code required to build Docker images.

## Building Images

This repository requires the [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
feature to be installed & enabled.

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

### Alpine Example

``` sh
docker buildx build --file dockerfiles/alpine/Dockerfile --platform linux/amd64,linux/arm64,linux/arm/v6
```

### RHEL 7 Example

``` sh
docker buildx build --file dockerfiles/redhat7/Dockerfile --platform linux/amd64,linux/arm64,linux/arm/v6
```


## Manually Triggered Builds (Sensu, Inc. only)
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

When value is set to an empty string the `circleci-fetch-artifacts.sh` script
uses the workflow id of the latest successful build for the main branch in
our internal commercial repository.

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
contact one of the GitHub Organization admins:
* [Justin][justin-slack]
* [Sean][sean-slack]
* [Cameron][cameron-slack]
* [Anthony][anthony-slack]
* [Caleb][caleb-slack]

**NOTE:** If an orb needs to be published and the GitHub Organization admins
cannot be reached via Slack, contact [Justin][justin-slack] via SMS/Phone.

Orbs can be published by checking out the latest code from the orb repository
and then running the following, specifying the orb name & dev version & whether
or not to use a major, minor, or patch level version bump:

``` sh
circleci orb pack src | circleci orb publish promote sensu/orb@dev:version bump-type
```

[justin-slack]: https://sensu.slack.com/team/U053FL3SK
[sean-slack]: https://sensu.slack.com/team/U051E44V1
[cameron-slack]: https://sensu.slack.com/team/U0562RSF2
[anthony-slack]: https://sensu.slack.com/team/U054A5JD7
[caleb-slack]: https://sensu.slack.com/team/U02L65BU5
