<#
.SYNOPSIS
    Builds the ROS + Gazebo + ESIM image. Takes about 25 minutes.

.PARAMETER NoCache
    Rebuild every layer from scratch.
#>
param([switch]$NoCache)

# Docker logs progress to stderr, which "Stop" would treat as fatal.
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\_config.ps1"

$buildArgs = @("build", "-t", $ImageName, "-f", "$ProjectRoot\docker\Dockerfile")
if ($NoCache) { $buildArgs += "--no-cache" }
$buildArgs += "$ProjectRoot\docker"

Write-Host "Building $ImageName ..." -ForegroundColor Cyan
& docker @buildArgs
if ($LASTEXITCODE -ne 0) { throw "docker build failed with exit code $LASTEXITCODE" }

Write-Host "`nBuilt $ImageName. Start it with .\scripts\run.ps1" -ForegroundColor Green
