#syntax=docker/dockerfile:1
FROM arm64v8/ubuntu:24.04
# By Ruhila
LABEL maintainer="Ruhila"
LABEL name="pySeamsDev"
# Kanging parts from https://github.com/HaoZeke/docker_platoBuilder/blob/4bd67339c3c53eb10a929287ddef126ad2562c26/Dockerfile#L4

# Suppress debconf errors [from https://github.com/phusion/baseimage-docker/issues/58]
ENV DEBIAN_FRONTEND noninteractive

# Suppress policy restart errors [from https://forums.docker.com/t/error-in-docker-image-creation-invoke-rc-d-policy-rc-d-denied-execution-of-restart-start/880]
RUN echo exit 0 > /usr/sbin/policy-rc.d

# Add a clean step to every run [from https://medium.com/unbabel-dev/the-need-for-speed-optimizing-dockerfiles-at-unbabel-70102f6d6745]
# The clean step is from Phusion

# Grab faster mirrors [from https://linuxconfig.org/how-to-select-the-fastest-apt-mirror-on-ubuntu-linux]
RUN apt-get update && apt-get install --yes wget; \
wget http://ftp.au.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-26_amd64.deb; \
dpkg -i netselect_0.3.ds1-26_amd64.deb; \
rm -rf netselect_*; \
netselect -s 20 -t 40 $(wget -qO - mirrors.ubuntu.com/mirrors.txt); \
sed -i 's/http:\/\/us.archive.ubuntu.com\/ubuntu\//http:\/\/ubuntu.uberglobalmirror.com\/archive\//' /etc/apt/sources.list; apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Get package names from https://launchpad.net/ubuntu/noble/+package/build-essential
# Read manpages and get "where is this from" here : https://manpages.ubuntu.com/
RUN apt update && apt install -y python3-pip \
# Essentials
texinfo libtool m4 build-essential \
gettext ccache git sudo pkgconf zsh \
# User packages
gh silversearcher-ag \
# d-SEAMS deps
meson cmake gfortran \
libeigen3-dev libfmt-dev libyaml-cpp-dev \
libboost-all-dev pybind11-dev; \
# Cleanup to reduce image size
apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Add the minion user, update password to minion and add to sudo group
ENV USER minion
RUN useradd --create-home ${USER} && \
 echo "${USER}:${USER}" chpasswd && \
 adduser ${USER} sudo

# Switch to the new user by default and make ~/ the working dir
WORKDIR /home/${USER}/

# Fix permissions on home
RUN sudo chown -R ${USER}:${USER} /home/${USER}

USER ${USER}

# Switch back to interactive shells
ENV DEBIAN_FRONTEND teletype

# Switch to zsh
SHELL ["/bin/zsh", "-c"]

# Setup dummy git config
RUN git config --global user.name "${USER}" && git config --global user.email "${USER}@localhost"