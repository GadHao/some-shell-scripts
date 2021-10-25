# This script is used to deploy dotnet framework site in IIS
# The $Env:PUBLISH_PATH should be set before run this script

msbuild /t:Build /p:Configuration=Release # use msbuild to build project
if (!$?) { exit $LASTEXITCODE } # if there are any errors during build, exit the script

# The $ErrorActionPreference only works with the cmdlet flow, but can't tell user the script's result
# $ErrorActionPreference = "Stop"
Set-Location .\WebApp\
Write-Output 'deploying...'
[cultureinfo]::CurrentUICulture = 'en-US';
$projectName = 'projectName'
if ($Env:PUBLISH_PATH) {
    $deployPath = Join-Path $Env:PUBLISH_PATH $projectName
    if (!(Test-Path $deployPath)) {
        mkdir $deployPath
        Write-Output "create $deployPath successed"
    }

    Copy-Item .\bin\ $deployPath -Recurse -Force
    if (!$?) { exit 2 }
    Write-Output 'deploy bin successed'
    Copy-Item .\Views\ $deployPath -Recurse -Force
    if (!$?) { exit 3 }
    Write-Output 'deploy Views successed'
}
else {
    Write-Output 'deploy fail code 1'
    exit 1
}

Write-Output "$projectName deploy successed"