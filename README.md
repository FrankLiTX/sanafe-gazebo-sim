# ROS + Gazebo environment

ROS 1, Gazebo and ESIM in a container, ready to run. Your source lives on the
host in `catkin_ws/` and is mounted in, so the container itself is disposable.

Works on Windows 11 with Docker Desktop, and in WSL2 Ubuntu with Docker Desktop.
The GUI needs no extra setup on either. Native Linux should be fine but is
untested; Windows 10 and macOS are not supported. Headless (`gui:=false`) runs
anywhere.

## Setup

Docker is the only thing you need to install.

```bash
git clone <this repo>
cd sanafe-gazebo-sim
./scripts/build.sh      # ~25 min, mostly ESIM
./scripts/run.sh        # shell inside the container
```

Then inside:

```bash
catkin_make
roslaunch sanafe_buggy smoke_test.launch
```

Gazebo opens on your desktop. The first world load downloads Gazebo's models,
which takes a minute and needs network.

On Windows PowerShell, use the `.ps1` version of any script.

## Commands

```bash
./scripts/run.sh                    # shell; run again for a 2nd terminal
./scripts/run.sh rostopic list      # run one command
./scripts/run.sh sim-stop           # stop a running simulation
./scripts/run.sh --fresh            # discard the container, start clean
./scripts/build.sh --no-cache       # rebuild every layer
./scripts/verify.sh                 # check the whole stack works
```

## What's inside

ROS Kinetic, Gazebo 7, Ubuntu 16.04, Python 2.7, about 3.9 GB. Rendering is
CPU-only, so heavy meshes and simulated cameras will drag.

[ESIM](https://rpg.ifi.uzh.ch/esim.html) is prebuilt at `/opt/esim_ws` and
already on the ROS path:

```bash
roslaunch esim_ros esim.launch
rosrun esim_ros esim_node --help
```

ESIM is the reason for the old ROS version, since Ubuntu 16.04 is the only setup
its authors tested. Don't bump ROS without checking ESIM still builds. Its
dependencies are pinned in
[`docker/esim-dependencies.yaml`](docker/esim-dependencies.yaml).

Nothing beyond Gazebo, the ROS bridge and ESIM's dependencies is installed. Add
what you need to [`docker/Dockerfile`](docker/Dockerfile) rather than
`apt install`ing it in a running container, or it disappears on the next
`--fresh`.

## Troubleshooting

Stop simulations with `sim-stop` or Ctrl-C. Killing them harder (`docker kill`,
`pkill -9`) can strand an empty Gazebo window with no process behind it. To clear
one, list the windows and kill the orphan by id:

```bash
./scripts/run.sh "apt-get update -qq && apt-get install -y -qq x11-utils xdotool && xwininfo -root -children | tail -8"
./scripts/run.sh xdotool windowkill 0x1234567
```

Ubuntu 16.04 and ROS Kinetic are both end-of-life, so a build failure usually
means another upstream host has gone away. The Dockerfile already works around an
expired apt key and a dead model database URL.
