#!/bin/bash
# Stops a running simulation. SIGINT first, since Gazebo only tears down its
# window on SIGINT; anything harsher strands an orphaned window on the desktop.
set -u

# Bracketed so pkill does not match the shell running this script.
PATTERN='[g]zclient|[g]zserver|[r]oslaunch|[r]osmaster'

still_running() { pgrep -f "$PATTERN" >/dev/null 2>&1; }

signal_all() {
    for p in '[g]zclient' '[g]zserver' '[r]oslaunch' '[r]osmaster'; do
        pkill -"$1" -f "$p" 2>/dev/null || true
    done
}

wait_for_exit() {
    local tries="$1"
    while [ "$tries" -gt 0 ]; do
        still_running || return 0
        sleep 1
        tries=$((tries - 1))
    done
    return 1
}

still_running || { echo "sim-stop: nothing running"; exit 0; }

signal_all INT  && wait_for_exit 8
still_running && { signal_all TERM; wait_for_exit 4; }
still_running && { signal_all KILL; wait_for_exit 3; }

if still_running; then
    echo "sim-stop: these survived SIGKILL:" >&2
    ps -ef | grep -aE "$PATTERN" >&2
    exit 1
fi

echo "sim-stop: simulation stopped"
