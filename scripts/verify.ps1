<#
.SYNOPSIS
    Checks the environment works, end to end, from a clean container.
#>
# Docker logs progress to stderr, which "Stop" would treat as fatal.
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\_config.ps1"
$Run = Join-Path $PSScriptRoot "run.ps1"
$failures = @()

function Check($name, $script, $expect) {
    Write-Host ("  {0,-26} ... " -f $name) -NoNewline
    $out = & $Run -Exec $script 2>&1 | Out-String
    if ($out -match $expect) {
        Write-Host "ok" -ForegroundColor Green
    } else {
        Write-Host "FAILED" -ForegroundColor Red
        ($out.Trim() -split "`n" | Select-Object -Last 6) | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
        $script:failures += $name
    }
}

Write-Host "Starting from a clean container ..." -ForegroundColor Cyan
& $Run -Fresh -Exec "true" 6>$null | Out-Null

Check "ROS Kinetic present"  'rosversion -d'                                            'kinetic'
Check "Gazebo 7 present"     'gzserver --version 2>&1 | head -1'                        'version 7'
Check "OpenGL reaches host"  'glxinfo -B 2>&1 | grep -i "direct rendering"'             'Yes'
Check "catkin_make builds"   'cd /root/catkin_ws && catkin_make > /tmp/cm.log 2>&1 && echo BUILT' 'BUILT'
Check "workspace overlay"    'cd /root/catkin_ws && . devel/setup.bash && rospack find sanafe_buggy' 'sanafe_buggy'
Check "ESIM built"           'test -x /opt/esim_ws/devel/lib/esim_ros/esim_node && rospack find esim_ros' 'esim_ros'

# Poll rather than sleep: a fresh container downloads Gazebo models first.
Write-Host ("  {0,-26} ... " -f "Gazebo + ROS integration") -NoNewline
& $Run -Exec "roslaunch sanafe_buggy smoke_test.launch gui:=false > /tmp/rl.log 2>&1" -Detach 6>$null | Out-Null

$deadline = (Get-Date).AddSeconds(180)
$world = ""
do {
    Start-Sleep -Seconds 5
    $world = & $Run -Exec "rosservice call /gazebo/get_world_properties 2>&1" | Out-String
} while ($world -notmatch "success: True" -and (Get-Date) -lt $deadline)

& $Run -Exec "sim-stop" 2>&1 | Out-Null
if ($world -match "ground_plane" -and $world -match "success: True") {
    Write-Host "ok" -ForegroundColor Green
} else {
    Write-Host "FAILED" -ForegroundColor Red
    $log = & $Run -Exec "tail -6 /tmp/rl.log" 2>&1 | Out-String
    ($log.Trim() -split "`n") | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
    $failures += "Gazebo + ROS integration"
}

Write-Host ""
if ($failures.Count -eq 0) {
    Write-Host "All checks passed. The environment is sound." -ForegroundColor Green
    exit 0
} else {
    Write-Host "$($failures.Count) check(s) failed: $($failures -join ', ')" -ForegroundColor Red
    exit 1
}
