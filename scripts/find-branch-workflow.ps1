#!/usr/bin/env pwsh

function CircleCI-Request {
    param(
        [string]
        $Path,

        [string]
        $Uri,

        [string]
        $OutputPath
    )

    # create uri from api address & resource path, otherwise
    # ignore $Path and only use $Uri
    If ([string]::IsNullOrEmpty($Uri)) {
        $Uri = "https://circleci.com/api/v2/$($Path)"
    }

    $headers = @{
        "Circle-Token" = $env:CIRCLE_TOKEN;
    };

    try {
        $ProgressPreference = 'SilentlyContinue'
        return Invoke-WebRequest -Uri $uri -Headers $headers -OutFile $OutputPath
    }
    catch {
        Write-Output "error: failed to request uri"
        $err = @{
            "URI" = $uri;
            "Status Code" = $_.Exception.Response.StatusCode.value__;
            "Reason" = $_.Exception.Response.ReasonPhrase.value__;
            "Content" = $_.Exception.Response.Content.value__;
        };
        Write-Output $err
        exit 1
    }
}

$debug = $env:DEBUG
$circleToken = $env:CIRCLE_TOKEN
$targetBranch = $env:TARGET_BRANCH

If ([string]::IsNullOrEmpty($circleToken)) {
    Write-Error "CIRCLE_TOKEN must be set"
    exit 1
}

If ([string]::IsNullOrEmpty($targetBranch)) {
    Write-Error "TARGET_BRANCH must be set" -Category InvalidArgument
    exit 1
}

$apiUrl = "https://circleci.com/api/v2"
$slug = "gh/sensu/sensu-enterprise-go"
$targetWorkflow = ""
$nextPageToken = ""
$page = 1

While ($True) {
    $queryParams = "branch=$($targetBranch)"

    If (! [string]::IsNullOrEmpty($nextPageToken)) {
        $queryParams += "&page-token=$($nextPageToken)"
    }

    $pipelinesUrl = "$($apiUrl)/project/$($slug)/pipeline?$($queryParams)"
    If (! [string]::IsNullOrEmpty($debug)) {
        Write-Output "fetching pipelines for branch: $($targetBranch), page: $($page))"
        Write-Output "url: $($pipelinesUrl)"
    }

    $pipelines = (CircleCI-Request -Uri $pipelinesUrl).Content
    $nextPageToken = (Write-Output $pipelines | jq -r .next_page_token)
    $items = (Write-Output $pipelines | jq -r .items)

    $page++;

    If ($items -Eq "[]") {
        If ($nextPageToken -Eq "null") {
            break
        }
        continue
    }

    $createdPipelines = (Write-Output $pipelines | jq -r `
      "[.items[] | select(.state == \`"created\`")]")

    If ($createdPipelines -Eq "[]") {
        If ([string]::IsNullOrEmpty($nextPageToken)) {
            break
        }
        continue
    }

    $pipelineIds = (Write-Output $createdPipelines | jq -r '.[].id')
    ForEach ($pipelineId in $pipelineIds) {
        $pipelineId = ($pipelineId -replace "\r", "")
        $wNextPageToken = ""
        $wPage = 1

        While ($True) {
            $wQueryParams = ""
            If (! [string]::IsNullOrEmpty($wNextPageToken)) {
                $wQueryParams += "page-token-$($wNextPageToken)"
            }

            $workflowsUrl = "$($apiUrl)/pipeline/$($pipelineId)/workflow?$($wQueryParams)"
            If (! [string]::IsNullOrEmpty($debug)) {
                Write-Output "fetching workflows for pipeline: $($pipelineId), page: $($wPage)"
                Write-Output "url: $($workflowsUrl)"
            }

            $workflows = (CircleCI-Request -Uri $workflowsUrl).Content
            $wNextPageToken = (Write-Output $workflows | jq -r .next_page_token)

            $wPage++

            $buildWorkflows = (Write-Output $workflows | jq -r `
              "[.items[] | select(.name == \`"build\`") | select(.status == \`"success\`")]")
            If ($buildWorkflows -Eq "[]") {
                If ($wNextPageToken -Eq "null") {
                    break
                }
                continue
            }

            $targetWorkflow = (Write-Output $buildWorkflows | jq -r '.[0].id')
            break
        }

        If (! [string]::IsNullorEmpty($targetWorkflow)) {
            break
        }
    }

    break
}

If ([string]::IsNullOrEmpty($targetWorkflow)) {
    Write-Error "no workflow was found for branch: $($targetBranch)"
    exit 1
}

If (! [string]::IsNullOrEmpty($debug)) {
    Write-Output "found workflow: $($targetWorkflow) for branch: $($targetBranch)"
} Else {
    Write-Output $targetWorkflow
}
