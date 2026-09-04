#!/bin/bash
# Sets up ROS, then runs the requested command.
set -e

. /etc/ros_env.sh

exec "$@"
