# Sensu Docker

This repository contains the code required to build Docker images.

## Manually Triggered Builds
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

## Build Parameters

### target_workflow

**Type:** `string`
**Default:** `""`

The remote workflow id of the desired build. It is used to fetch the build
artifacts from each of the required jobs in the remote workflow.

When value is set to an empty string the `circleci-fetch-artifacts.sh` script
uses the workflow id of the latest successful build for the main branch in
our internal commercial repository.
