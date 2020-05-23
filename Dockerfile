FROM ubuntu:precise

# This is probably not needed
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]

# Install things needed to add ROS repository
RUN apt-get update && apt-get install -y \
    apt-utils \
    wget \
    build-essential\
    python\
    git\
    nano\
    liblapack-dev\
    libblas-dev\
    f2c\
    ca-certificates

# Install ROS Packages
RUN find /etc/apt/ -name *.list -exec sed -i -e 's/archive.ubuntu.com\|security.ubuntu.com/old-releases.ubuntu.com/g' {} \;

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4B63CF8FDE49746E98FA01DDAD19BAB3CBF125EA

# setup sources.list
RUN echo "deb http://snapshots.ros.org/hydro/final/ubuntu precise main" > /etc/apt/sources.list.d/ros1-snapshots.list

# setup environment
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# install ros packages
ENV ROS_DISTRO hydro
RUN apt-get update && apt-get dist-upgrade && apt-get install -y \
    ros-hydro-desktop-full \
    ros-hydro-catkin\ 
    python-catkin-tools\
    python-catkin-pkg\
    python-wstool\
    python-rosinstall\
    ros-hydro-pr2-mechanism-msgs\
    ros-hydro-moveit-full\
    ros-hydro-ecl-geometry\
    ros-hydro-pluginlib

#Setup user ros
RUN useradd -ms /bin/bash ros
WORKDIR /home/ros
RUN chown -R ros ./
USER ros
RUN echo "source /opt/ros/hydro/setup.bash" >> ~/.bashrcd
RUN mkdir catkin_ws
ARG WS=/home/ros/catkin_ws
WORKDIR ${WS}
RUN source /opt/ros/hydro/setup.bash

#Here we install moveit
RUN mkdir src
WORKDIR ${WS}/src

RUN wstool init .
RUN wstool merge https://raw.github.com/ros-planning/moveit_docs/hydro-devel/moveit.rosinstall
RUN wstool update 

#build moveit and catkin build
WORKDIR ${WS}
USER root
RUN rosdep init
RUN rosdep update
RUN rosdep install --from-paths src --ignore-src --rosdistro hydro -y

USER ros
RUN ["/bin/bash", "-c", ". /opt/ros/hydro/setup.bash; catkin build"]
RUN source devel/setup.bash

#GUI
USER root
RUN apt-get install -y x11-apps

#Create ROS workspace according to Chpark
RUN rosws init ~/{WS} /opt/ros/hydro
WORKDIR ${WS}
RUN git clone https://github.com/Chpark/itomp.git
WORKDIR ${WS}/itomp
RUN ["/bin/bash", "-c", ". /opt/ros/hydro/setup.bash"]
RUN echo "source /opt/ros/hydro/setup.bash" >> ~/.bashrc
#ENV ROS_PACKAGE_PATH "$ROS_PACKAGE_PATH:/home/ros/catkin_ws"
RUN echo "export ROS_PACKAGE_PATH=/home/ros/catkin_ws:/opt/ros/hydro/share:/opt/ros/hydro/stacks" >> ~/.bashrc
WORKDIR ${WS}/itomp/move_itomp





#ENV export ROS_PACKAGE_PATH=/home/ros/catkin_ws:$ROS_PACKAGE_PATH
#RUN export PKG_CONFIG_PATH=/home/ros/catkin_ws/src/moveit_core:/usr/local/lib/pkgconfig
#important
#PKG_CONFIG_PATH=/home/ros/catkin_ws/src/moveit_core:$PKG_CONFIG_PATH






#COPY ./ros_entrypoint.sh /ros_entrypoint.sh
#ENTRYPOINT ["/ros_entrypoint.sh"]
#CMD ["bash"]


