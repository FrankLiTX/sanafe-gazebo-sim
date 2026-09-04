<#
.SYNOPSIS
    Starts (or re-enters) the container.

.PARAMETER Fresh
    Discard the existing container first.

.PARAMETER Exec
    A command to run instead of opening a shell. Avoid double quotes inside it;
    they are lost crossing into the container.

.PARAMETER Detach
    With -Exec, run in the background and return immediately.

.EXAMPLE
    .\scripts\run.ps1 -Exec "roslaunch sanafe_buggy smoke_test.launch"
#>
param(
    [switch]$Fresh,
    [string]$Exec,
    [switch]$Detach
)

# Docker logs progress to stderr, which "Stop" would treat as fatal.
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\_config.ps1"

docker image inspect $ImageName *>$null
if ($LASTEXITCODE -ne 0) {
    throw "Image $ImageName not found. Run .\scripts\build.ps1 first."
}

if ($Fresh -and (docker ps -aq --filter "name=^$ContainerName$")) {
    Write-Host "Removing existing container $ContainerName ..." -ForegroundColor Yellow
    docker rm -f $ContainerName | Out-Null
}

# The container just holds the mounts; everything is exec'd into it.
if (-not (docker ps -aq --filter "name=^$ContainerName$")) {
    Write-Host "Creating container $ContainerName ..." -ForegroundColor Cyan
    # --init reaps orphaned processes.
    docker run -d --name $ContainerName `
        --init `
        --shm-size=1g `
        -v /run/desktop/mnt/host/wslg/.X11-unix:/tmp/.X11-unix `
        -v /run/desktop/mnt/host/wslg:/mnt/wslg `
        -e DISPLAY=:0 `
        -e WAYLAND_DISPLAY=wayland-0 `
        -e XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir `
        -e PULSE_SERVER=/mnt/wslg/PulseServer `
        -v "${CatkinWs}:/root/catkin_ws" `
        $ImageName sleep infinity | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "docker run failed with exit code $LASTEXITCODE" }
}
elseif (-not (docker ps -q --filter "name=^$ContainerName$")) {
    docker start $ContainerName | Out-Null
}

# `docker exec` skips the entrypoint, so source the ROS environment here.
$Wrapped = ". /etc/ros_env.sh && $Exec"
if ($Exec -and $Detach) {
    docker exec -d $ContainerName bash -c $Wrapped
    Write-Host "Started in background inside $ContainerName." -ForegroundColor Cyan
} elseif ($Exec) {
    docker exec -i $ContainerName bash -c $Wrapped
} else {
    docker exec -it $ContainerName bash
}
exit $LASTEXITCODE
