#!/bin/bash
#
# Test script file that maps itself into a docker container and runs
#
# Example invocation:
#
# $ AOSP_VOL=$PWD/build ./build-kitkat.sh
#
set -ex

if [ "$1" = "docker" ]; then
    TEST_MODEL=${TEST_MODEL:-msm8916_32-userdebug}

    cpus=$(grep ^processor /proc/cpuinfo | wc -l)

    prebuilts/misc/linux-x86/ccache/ccache -M 10G

    source build/envsetup.sh
    lunch "$TEST_MODEL"
    make -j$cpus
else
    aosp_url="https://raw.githubusercontent.com/kylemanna/docker-aosp/master/utils/aosp"
    args="bash run.sh docker"
    export AOSP_EXTRA_ARGS="-v $(cd $(dirname $0) && pwd -P)/$(basename $0):/usr/local/bin/run.sh:ro"
    export AOSP_VOL="/home/andrea/android/codeaurora"
    export AOSP_IMAGE="andreaji/android:4.4-kitkat"

    #
    # Try to invoke the aosp wrapper with the following priority:
    #
    # 1. If AOSP_BIN is set, use that
    # 2. If aosp is found in the shell $PATH
    # 3. Grab it from the web
    #
    if [ -n "$AOSP_BIN" ]; then
        $AOSP_BIN $args
    elif [ -x "../utils/aosp" ]; then
        ../utils/aosp $args
    elif [ -n "$(type -P aosp)" ]; then
        aosp $args
    else
        if [ -n "$(type -P curl)" ]; then
            bash <(curl -s $aosp_url) $args
        elif [ -n "$(type -P wget)" ]; then
            bash <(wget -q $aosp_url -O -) $args
        else
            echo "Unable to run the aosp binary"
        fi
    fi
fi
