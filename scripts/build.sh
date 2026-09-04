#!/usr/bin/env bash
# Builds the ROS + Gazebo + ESIM image. Takes about 25 minutes.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_config.sh"

echo "Building ${IMAGE_NAME} ..."
docker build -t "$IMAGE_NAME" -f "${PROJECT_ROOT}/docker/Dockerfile" "$@" "${PROJECT_ROOT}/docker"
echo
echo "Built ${IMAGE_NAME}. Start it with ./scripts/run.sh"
