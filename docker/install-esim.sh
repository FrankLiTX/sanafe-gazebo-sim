#!/bin/bash
# Builds ESIM into /opt/esim_ws.

# No `set -u`: ROS's profile scripts reference unbound variables.
set -exo pipefail

ESIM_COMMIT=4cf0b8952e9f58f674c3098f1b027a4b6db53427

. /opt/ros/kinetic/setup.bash

mkdir -p /opt/esim_ws/src
cd /opt/esim_ws
catkin init
catkin config --extend /opt/ros/kinetic --cmake-args -DCMAKE_BUILD_TYPE=Release

cd /opt/esim_ws/src
git clone https://github.com/uzh-rpg/rpg_esim.git
git -C rpg_esim checkout --quiet "$ESIM_COMMIT"

# Pinned copy of ESIM's dependencies.yaml.
vcs import < /tmp/esim-dependencies.yaml

# Packages requiring CUDA or Pangolin.
cd /opt/esim_ws/src/ze_oss
touch imp_3rdparty_cuda_toolkit/CATKIN_IGNORE \
      imp_app_pangolin_example/CATKIN_IGNORE \
      imp_benchmark_aligned_allocator/CATKIN_IGNORE \
      imp_bridge_pangolin/CATKIN_IGNORE \
      imp_cu_core/CATKIN_IGNORE \
      imp_cu_correspondence/CATKIN_IGNORE \
      imp_cu_imgproc/CATKIN_IGNORE \
      imp_ros_rof_denoising/CATKIN_IGNORE \
      imp_tools_cmd/CATKIN_IGNORE \
      ze_data_provider/CATKIN_IGNORE \
      ze_geometry/CATKIN_IGNORE \
      ze_imu/CATKIN_IGNORE \
      ze_trajectory_analysis/CATKIN_IGNORE

# yaml-cpp's sample tools link a target name its own patch renamed.
sed -i 's|-DBUILD_SHARED_LIBS=ON|-DBUILD_SHARED_LIBS=ON -DYAML_CPP_BUILD_TOOLS=OFF|' \
    /opt/esim_ws/src/yaml_cpp_catkin/CMakeLists.txt

# imp_opengl_renderer links `assimp`, which lives in the devel space.
export LIBRARY_PATH=/opt/esim_ws/devel/lib:${LIBRARY_PATH:-}

cd /opt/esim_ws
catkin build esim_ros --no-status

# gflags exits non-zero on --help, so check linkage instead.
test -x /opt/esim_ws/devel/lib/esim_ros/esim_node
ldd /opt/esim_ws/devel/lib/esim_ros/esim_node | grep -q "not found" \
    && { echo "esim_node has unresolved libraries"; exit 1; }
echo "ESIM built OK"
