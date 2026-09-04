# Sets up ROS for any shell in this container. Sourced, never executed.

# shellcheck disable=SC1090
. "/opt/ros/${ROS_DISTRO}/setup.bash"

# ESIM, built into the image.
if [ -f /opt/esim_ws/devel/setup.bash ]; then
    . /opt/esim_ws/devel/setup.bash
fi

# The workspace overlay, once catkin_make has been run.
if [ -f "${CATKIN_WS}/devel/setup.bash" ]; then
    . "${CATKIN_WS}/devel/setup.bash"
fi
