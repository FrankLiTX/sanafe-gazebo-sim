# Shared names. Sourced by the other scripts.

ROS_DISTRO_TAG="kinetic"
IMAGE_NAME="sanafe-gazebo:${ROS_DISTRO_TAG}"
CONTAINER_NAME="sanafe-gazebo-${ROS_DISTRO_TAG}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATKIN_WS_HOST="${PROJECT_ROOT}/catkin_ws"
