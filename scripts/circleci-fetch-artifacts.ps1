#!/usr/bin/env pwsh

function _jq {
    $decoded = [System.Convert]::FromBase64String($args[0])
    $utf8 = [System.Text.Encoding]::UTF8.GetString($decoded)
    return ($utf8 | jq -r $args[1])
}

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

function New-Section {
    Write-Output ""
    Write-Output "============================================================================================================================================"
    Write-Output " $($args[0])"
    Write-Output "============================================================================================================================================"
}

$target_workflow = $args[0]
$target_job = $args[1]
$destination = $args[2]
$filter = $args[3]

If ([string]::IsNullOrEmpty($target_workflow)) {
    Write-Output "target workflow not specified"
    exit 1
}

If ([string]::IsNullOrEmpty($target_job)) {
    Write-Output "target job not specified"
    exit 1
}

If ([string]::IsNullOrEmpty($destination)) {
    Write-Output "destination not specified"
    exit 1
}

If ([string]::IsNullOrEmpty($env:CIRCLE_TOKEN)) {
    Write-Output "CIRCLE_TOKEN environment variable must be set"
    exit 1
}

New-Section "called arguments"
Write-Output "Target Workflow: $($target_workflow)"
Write-Output "Target Job: $($target_job)"
Write-Output "Destination: $($destination)"
Write-Output "Filter: $($filter)"

New-Section "fetching jobs for workflow: $($target_workflow)"
$jobs_json = (CircleCI-Request "workflow/$($target_workflow)/job").Content
Write-Output $jobs_json | jq .

New-Section "fetching project slug"
$project_slug = (Write-Output $jobs_json | jq -r '.items[0].project_slug')
If ([string]::IsNullOrEmpty($project_slug)) {
    Write-Output "error: failed to find project slug"
    exit 1
}
Write-Output $project_slug

New-Section "fetching job number for job: $($target_job)"
$job_number = (Write-Output $jobs_json | jq -r ".items[] | select(.name == \`"$($target_job)\`") | .job_number")
If ([string]::IsNullOrEmpty($job_number)) {
    Write-Output "error: failed to find job: $($target_job)"
    exit 1
}
Write-Output "job number: $($job_number)"

New-Section "fetching artifact urls with filter: $($filter) for job: $($target_job)"
$artifact_json = New-TemporaryFile
Write-Output "created tmp file: $($artifact_json)"
CircleCI-Request "project/$($project_slug)/$($job_number)/artifacts" -OutputPath $artifact_json
Get-Content $artifact_json | jq .

ForEach ($row in (Get-Content $artifact_json | jq -r ".items[] | select(.path | contains(\`"$($filter)\`")) | @base64")) {
    $path = (_jq $row ".path")
    $output_path = (Join-Path -Path $destination -ChildPath $path)
    New-Section "downloading artifact: $($path) from job: $($target_job)"
    New-Item -Path (Split-Path $output_path) -ItemType "directory" -Force
    CircleCI-Request -Uri (_jq $row ".url") -OutputPath $output_path
    Write-Output "downloaded to: $($output_path)"
}
