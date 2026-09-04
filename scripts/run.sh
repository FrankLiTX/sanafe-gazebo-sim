#!/usr/bin/env bash
# Starts (or re-enters) the container. On Windows PowerShell use run.ps1.
#
#   ./scripts/run.sh                     # interactive shell
#   ./scripts/run.sh gazebo --verbose    # run one command
#   ./scripts/run.sh --fresh             # discard the container first
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_config.sh"

if [ "${1:-}" = "--fresh" ]; then
    shift
    if docker ps -aq --filter "name=^${CONTAINER_NAME}$" | grep -q .; then
        echo "Removing existing container ${CONTAINER_NAME} ..."
        docker rm -f "$CONTAINER_NAME" >/dev/null
    fi
fi

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Image ${IMAGE_NAME} not found. Run ./scripts/build.sh first." >&2
    exit 1
fi

# No-op under WSLg, needed on an ordinary Linux desktop.
command -v xhost >/dev/null 2>&1 && xhost +local:docker >/dev/null 2>&1 || true

# The container just holds the mounts; everything is exec'd into it.
if ! docker ps -aq --filter "name=^${CONTAINER_NAME}$" | grep -q .; then
    echo "Creating container ${CONTAINER_NAME} ..."
    # --init reaps orphaned processes.
    docker run -d --name "$CONTAINER_NAME" \
        --init \
        --shm-size=1g \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -e "DISPLAY=${DISPLAY:-:0}" \
        -v "${CATKIN_WS_HOST}:/root/catkin_ws" \
        "$IMAGE_NAME" sleep infinity >/dev/null
elif ! docker ps -q --filter "name=^${CONTAINER_NAME}$" | grep -q .; then
    docker start "$CONTAINER_NAME" >/dev/null
fi

# `docker exec` skips the entrypoint, so source the ROS environment here.
if [ "$#" -eq 0 ]; then
    exec docker exec -it "$CONTAINER_NAME" bash
fi

[ -t 0 ] && TTY=-it || TTY=-i
exec docker exec $TTY "$CONTAINER_NAME" bash -c ". /etc/ros_env.sh && $*"
