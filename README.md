# Sensu Docker

This repository contains the code required to build Docker images.

## Manually Triggering Builds
Builds can be triggered via the CircleCI API using tools such as `curl`. To
trigger a build replace the values in the following example and run it:

```sh
jsonParams='{"target_workflow":"",'
jsonParams+='"sensu_version":"6.0.0",'
jsonParams+='"build_number":1}'

curl -fL -X POST -H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H "Circle-Token: ${CIRCLE_TOKEN}" \
-d $jsonData \
https://circleci.com/api/v2/project/gh/sensu/sensu-docker/pipeline
```

## Build Parameters

### target_workflow

**Type:** `string`
**Default:** `""`

The remote workflow id of the desired build. It is used to fetch the build
artifacts from each of the required jobs in the remote workflow.

When value is set to an empty string the `circleci-fetch-artifacts.sh` script
uses the workflow id of the latest successful build for the master branch in
our internal commercial repository.

### sensu_version

**Type:** `string`
**Default:** `6.0.0`

The version of the local or remote build. This is used to set the version
number of the package.

### build_number

**Type:** `integer`
**Default:** `<< pipeline.number >>`

The build number of the local or remote build. This is used to set the revision
number of the package.
