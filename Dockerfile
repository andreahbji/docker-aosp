#
# Minimum Docker image to build Android AOSP
# Copyright (C) 2014-2019 Kyle Manna <kyle@kylemanna.com>
# Copyright (C) 2019 Andrea Ji <andrea.hb.ji@outlook.com>
#
FROM ubuntu:16.04

LABEL maintainer="andrea.hb.ji@outlook.com"

# /bin/sh points to Dash by default, reconfigure to use bash until Android
# build becomes POSIX compliant
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    dpkg-reconfigure -p critical dash

# Replace apt source with aliyun mirror
ADD sources.list /etc/apt/

# Keep the dependency list as short as reasonable
RUN apt-get update && \
    apt-get install -y bc bison bsdmainutils build-essential ccache curl \
        flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev \
        lib32readline-dev lib32z1-dev liblz4-tool libesd0-dev libncurses5-dev \
        libsdl1.2-dev libssl-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop sudo \
        openjdk-8-jdk \
        pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev graphviz && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD https://mirrors.tuna.tsinghua.edu.cn/git/git-repo /usr/local/bin/repo
RUN chmod 755 /usr/local/bin/*

# Install latest version of JDK
# See http://source.android.com/source/initializing.html#setting-up-a-linux-build-environment
WORKDIR /tmp

# All builds will be done by user aosp
COPY gitconfig /root/.gitconfig
COPY ssh_config /root/.ssh/config

# The persistent data will be in these two directories, everything else is
# considered to be ephemeral
VOLUME ["/tmp/ccache", "/aosp"]

# Improve rebuild performance by enabling compiler cache
ENV USE_CCACHE 1
ENV CCACHE_DIR /tmp/ccache

# Work in the build directory, repo is expected to be init'd here
WORKDIR /aosp

COPY utils/docker_entrypoint.sh /root/docker_entrypoint.sh
ENTRYPOINT ["/root/docker_entrypoint.sh"]
