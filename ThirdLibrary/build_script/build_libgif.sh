#!/bin/bash

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBITIM_BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix)
#   RABBITIM_BUILD_PREFIX=`pwd`/../${RABBITIM_BUILD_TARGERT}  #修改这里为安装前缀
#   RABBITIM_BUILD_SOURCE_CODE    #源码目录
#   RABBITIM_BUILD_CROSS_PREFIX   #交叉编译前缀
#   RABBITIM_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

set -e
HELP_STRING="Usage $0 PLATFORM (android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"

case $1 in
    android|windows_msvc|windows_mingw|unix)
    RABBITIM_BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    exit 1
    ;;
esac

if [ -z "${RABBITIM_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_envsetup_${RABBITIM_BUILD_TARGERT}.sh"
    . `pwd`/build_envsetup_${RABBITIM_BUILD_TARGERT}.sh
fi

if [ -n "$2" ]; then
    RABBITIM_BUILD_SOURCE_CODE=$2
else
    RABBITIM_BUILD_SOURCE_CODE=${RABBITIM_BUILD_PREFIX}/../src/libgif
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBITIM_BUILD_SOURCE_CODE} ]; then
    VERSION=master
    #if [ "TRUE" = "${RABBITIM_USE_REPOSITORIES}" ]; then
        echo "git clone -q --branch=${VERSION} http://kl222@git.code.sf.net/u/kl222/giflib ${RABBITIM_BUILD_SOURCE_CODE}"
        git clone -q --branch=$VERSION http://kl222@git.code.sf.net/u/kl222/giflib ${RABBITIM_BUILD_SOURCE_CODE}
    #else
    #    mkdir -p ${RABBITIM_BUILD_SOURCE_CODE}
    #    cd ${RABBITIM_BUILD_SOURCE_CODE}
    #    echo "wget -nv -c https://sourceforge.net/projects/giflib/files/giflib-${VERSION}.tar.gz/download"
    #    wget -nv -c -O giflib-${VERSION}.tar.gz https://sourceforge.net/projects/giflib/files/giflib-${VERSION}.tar.gz/download 
    #    tar xvzf giflib-${VERSION}.tar.gz
    #    mv giflib-${VERSION} ..
    #    rm -fr giflib-${VERSION}.tar.gz ${RABBITIM_BUILD_SOURCE_CODE}
    #    cd ..
    #    mv giflib-${VERSION} ${RABBITIM_BUILD_SOURCE_CODE} 
    #fi
fi

cd ${RABBITIM_BUILD_SOURCE_CODE}

echo ""
echo "RABBITIM_BUILD_TARGERT:${RABBITIM_BUILD_TARGERT}"
echo "RABBITIM_BUILD_SOURCE_CODE:$RABBITIM_BUILD_SOURCE_CODE"
echo "CUR_DIR:`pwd`"
echo "RABBITIM_BUILD_PREFIX:$RABBITIM_BUILD_PREFIX"
echo "RABBITIM_BUILD_HOST:$RABBITIM_BUILD_HOST"
echo "RABBITIM_BUILD_CROSS_HOST:$RABBITIM_BUILD_CROSS_HOST"
echo "RABBITIM_BUILD_CROSS_PREFIX:$RABBITIM_BUILD_CROSS_PREFIX"
echo "RABBITIM_BUILD_CROSS_SYSROOT:$RABBITIM_BUILD_CROSS_SYSROOT"
echo "RABBITIM_BUILD_STATIC:$RABBITIM_BUILD_STATIC"
echo "PKG_CONFIG_PATH:${PKG_CONFIG_PATH}"
echo "PKG_CONFIG_LIBDIR:${PKG_CONFIG_LIBDIR}"
echo ""

if [ ! -f configure -a "windows_msvc" != "${RABBITIM_BUILD_TARGERT}" ]; then
    echo "sh autogen.sh"
    sh autogen.sh
    make distclean
fi

mkdir -p build_${RABBITIM_BUILD_TARGERT}
cd build_${RABBITIM_BUILD_TARGERT}
if [ -n "$RABBITIM_CLEAN" ]; then
    rm -fr *
fi

#需要设置 CMAKE_MAKE_PROGRAM 为 make 程序路径。
if [ "$RABBITIM_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
case ${RABBITIM_BUILD_TARGERT} in
    android)
        export CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc 
        export CXX=${RABBITIM_BUILD_CROSS_PREFIX}g++
        export AR=${RABBITIM_BUILD_CROSS_PREFIX}ar
        export LD=${RABBITIM_BUILD_CROSS_PREFIX}ld
        export AS=${RABBITIM_BUILD_CROSS_PREFIX}as
        export STRIP=${RABBITIM_BUILD_CROSS_PREFIX}strip
        export NM=${RABBITIM_BUILD_CROSS_PREFIX}nm
        #CONFIG_PARA="CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc LD=${RABBITIM_BUILD_CROSS_PREFIX}ld"
        CONFIG_PARA="${CONFIG_PARA} --disable-shared -enable-static --host=$RABBITIM_BUILD_CROSS_HOST"
        CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        ;;   
    unix)
        ;;
    windows_msvc)
        cd ${RABBITIM_BUILD_SOURCE_CODE}/lib
        echo "" > unistd.h
        cp ../util/qprintf.c ../util/getarg.* . 
        nmake -f Makefile.ms clean
        nmake -f Makefile.ms
        cp -f gif_lib.h $RABBITIM_BUILD_PREFIX/include
        cp -f giflib.lib $RABBITIM_BUILD_PREFIX/lib/libgif.lib
        rm -f qprintf.c getarg.* unistd.h
        cd $CUR_DIR
        exit 0
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                export CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc 
                export CXX=${RABBITIM_BUILD_CROSS_PREFIX}g++
                export AR=${RABBITIM_BUILD_CROSS_PREFIX}ar
                export LD=${RABBITIM_BUILD_CROSS_PREFIX}ld
                export AS=${RABBITIM_BUILD_CROSS_PREFIX}as
                export STRIP=${RABBITIM_BUILD_CROSS_PREFIX}strip
                export NM=${RABBITIM_BUILD_CROSS_PREFIX}nm
                CONFIG_PARA="${CONFIG_PARA} CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc"
                CONFIG_PARA="${CONFIG_PARA} --host=${RABBITIM_BUILD_CROSS_HOST}"
                ;;
            *)
            ;;
        esac
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 2
    ;;
esac

CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBITIM_BUILD_PREFIX" #--with-zlib-prefix=$RABBITIM_BUILD_PREFIX "
echo "../configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" CPPFLAGS=\"${CPPFLAGS}\""
../configure ${CONFIG_PARA} CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}"

echo "make install"
make ${RABBITIM_MAKE_JOB_PARA} V=1
make install

cd $CUR_DIR
