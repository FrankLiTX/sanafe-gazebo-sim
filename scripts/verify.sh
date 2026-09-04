#!/usr/bin/env bash
# Checks the environment works, end to end, from a clean container.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_config.sh"
RUN="${PROJECT_ROOT}/scripts/run.sh"
failures=0

check() {
    local name="$1" script="$2" expect="$3" out
    printf '  %-26s ... ' "$name"
    out="$("$RUN" "$script" 2>&1)"
    if printf '%s' "$out" | grep -qE "$expect"; then
        echo "ok"
    else
        echo "FAILED"
        printf '%s\n' "$out" | tail -6 | sed 's/^/      /'
        failures=$((failures + 1))
    fi
}

echo "Starting from a clean container ..."
"$RUN" --fresh true >/dev/null 2>&1

check "ROS Kinetic present" 'rosversion -d'                                'kinetic'
check "Gazebo 7 present"    'gzserver --version 2>&1 | head -1'            'version 7'
check "OpenGL reaches host" 'glxinfo -B 2>&1 | grep -i "direct rendering"' 'Yes'
check "catkin_make builds"  'cd /root/catkin_ws && catkin_make > /tmp/cm.log 2>&1 && echo BUILT' 'BUILT'
check "workspace overlay"   'cd /root/catkin_ws && . devel/setup.bash && rospack find sanafe_buggy' 'sanafe_buggy'
check "ESIM built"          'test -x /opt/esim_ws/devel/lib/esim_ros/esim_node && rospack find esim_ros' 'esim_ros'

# Poll rather than sleep: a fresh container downloads Gazebo models first.
printf '  %-26s ... ' "Gazebo + ROS integration"
"$RUN" "roslaunch sanafe_buggy smoke_test.launch gui:=false > /tmp/rl.log 2>&1 &" >/dev/null 2>&1

world=""
deadline=$(( $(date +%s) + 180 ))
while [ "$(date +%s)" -lt "$deadline" ]; do
    sleep 5
    world="$("$RUN" 'rosservice call /gazebo/get_world_properties 2>&1')"
    printf '%s' "$world" | grep -q 'success: True' && break
done

"$RUN" "sim-stop" >/dev/null 2>&1
if printf '%s' "$world" | grep -q ground_plane && printf '%s' "$world" | grep -q 'success: True'; then
    echo "ok"
else
    echo "FAILED"
    "$RUN" 'tail -6 /tmp/rl.log' 2>&1 | sed 's/^/      /'
    failures=$((failures + 1))
fi

echo
if [ "$failures" -eq 0 ]; then
    echo "All checks passed. The environment is sound."
else
    echo "$failures check(s) failed."
    exit 1
fi
