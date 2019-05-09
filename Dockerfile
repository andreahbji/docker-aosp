#
# Minimum Docker image to build Android AOSP
# Copyright (C) 2014-2019 Kyle Manna <kyle@kylemanna.com>
# Copyright (C) 2019 Andrea Ji <andrea.hb.ji@outlook.com>
#

FROM ubuntu:14.04

LABEL maintainer="andrea.hb.ji@outlook.com"

# Setup for Oracle Java 6
ADD http://85-207-0-21.static.bluetone.cz/java/1.6.0_45/jdk-6u45-linux-x64.bin /usr/local/
WORKDIR /usr/local/
RUN chmod a+x ./jdk-6u45-linux-x64.bin && ./jdk-6u45-linux-x64.bin && rm -rf ./jdk-6u45-linux-x64.bin
ENV JAVA_HOME=/usr/local/jdk1.6.0_45
ENV CLASS_PATH=.:$JAVA_HOME/lib
ENV PATH=$PATH:$JAVA_HOME/bin
WORKDIR /

# /bin/sh points to Dash by default, reconfigure to use bash until Android
# build becomes POSIX compliant
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    dpkg-reconfigure -p critical dash

# Replace apt source to aliyun mirror
ADD sources.list /etc/apt/

# Keep the dependency list as short as reasonable
RUN apt-get update && \
    apt-get install -y bc bison bsdmainutils build-essential curl \
        flex g++-multilib gcc-multilib git gnupg gperf lib32ncurses5-dev \
        lib32readline-gplv2-dev lib32z1-dev libesd0-dev libncurses5-dev \
        libsdl1.2-dev libwxgtk2.8-dev libxml2-utils lzop \
        genisoimage \
        pngcrush schedtool xsltproc zip zlib1g-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD https://mirrors.tuna.tsinghua.edu.cn/git/git-repo /usr/local/bin/repo
RUN chmod 755 /usr/local/bin/*

# All builds will be done by user aosp
RUN useradd --create-home aosp
ADD gitconfig /home/aosp/.gitconfig
ADD ssh_config /home/aosp/.ssh/config
RUN chown aosp:aosp /home/aosp/.gitconfig

# The persistent data will be in these two directories, everything else is
# considered to be ephemeral
VOLUME ["/tmp/ccache", "/aosp"]

# Improve rebuild performance by enabling compiler cache
ENV USE_CCACHE 1
ENV CCACHE_DIR /tmp/ccache

# Work in the build directory, repo is expected to be init'd here
USER aosp
WORKDIR /aosp
