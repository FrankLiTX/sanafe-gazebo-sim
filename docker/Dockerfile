# ROS Kinetic + Gazebo 7 + ESIM on Ubuntu 16.04.
FROM ros:kinetic-ros-base

# Kinetic's apt signing key expired 2025-06-01.
RUN echo "deb [trusted=yes] http://snapshots.ros.org/kinetic/final/ubuntu xenial main" \
      > /etc/apt/sources.list.d/ros1-snapshots.list

# Simulator, ROS bridge, and glxinfo for diagnosing display problems.
RUN apt-get update && apt-get install -y --no-install-recommends \
        gazebo7 \
        ros-kinetic-gazebo-ros \
        mesa-utils \
    && rm -rf /var/lib/apt/lists/*

# The database URL gazebo7 ships with no longer resolves.
ENV GAZEBO_MODEL_DATABASE_URI=http://models.gazebosim.org

# Software rendering, since the container has no GPU passthrough.
ENV DISPLAY=:0 \
    QT_X11_NO_MITSHM=1 \
    LIBGL_ALWAYS_SOFTWARE=1

# ESIM build dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
        python-catkin-tools python-vcstool git \
        ros-kinetic-pcl-ros libproj-dev libglfw3 libglfw3-dev libglm-dev \
        ros-kinetic-hector-trajectory-server \
        autoconf automake libtool pkg-config \
        ros-kinetic-cv-bridge ros-kinetic-image-transport \
        ros-kinetic-camera-info-manager ros-kinetic-image-geometry \
        ros-kinetic-eigen-conversions ros-kinetic-tf-conversions ros-kinetic-tf \
    && rm -rf /var/lib/apt/lists/*

# Builds ESIM into /opt/esim_ws. Takes about 20 minutes.
COPY esim-dependencies.yaml /tmp/esim-dependencies.yaml
COPY install-esim.sh /tmp/install-esim.sh
RUN chmod +x /tmp/install-esim.sh && /tmp/install-esim.sh && rm -rf /opt/esim_ws/logs

# The catkin workspace is bind-mounted here from the host.
ENV CATKIN_WS=/root/catkin_ws
WORKDIR /root/catkin_ws

# Sourced by the entrypoint, interactive shells, and `docker exec`.
COPY ros_env.sh /etc/ros_env.sh
RUN chmod +x /etc/ros_env.sh \
 && echo '. /etc/ros_env.sh' >> /root/.bashrc

COPY sim-stop.sh /usr/local/bin/sim-stop
RUN chmod +x /usr/local/bin/sim-stop

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
