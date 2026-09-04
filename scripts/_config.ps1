# Shared names. Dot-sourced by the other scripts.

$RosDistro     = "kinetic"
$ImageName     = "sanafe-gazebo:$RosDistro"
$ContainerName = "sanafe-gazebo-$RosDistro"
$ProjectRoot   = Split-Path -Parent $PSScriptRoot
$CatkinWs      = Join-Path $ProjectRoot "catkin_ws"
