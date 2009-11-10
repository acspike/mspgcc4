#!/bin/bash

# This work is partially financed by the European Commission under the
# Framework 6 Information Society Technologies Project
#  "Wirelessly Accessible Sensor Populations (WASP)".

#The following versions of BINUTILS have been tested:
# 6.8
# 7.0
# insight 6.8-1


set -eu

# source utilities
. ./buildgcc.subr

PKG_VERSION=7.0
PKG_NAME=gdb	#can also be insight
GNU_MIRROR=ftp.uni-kl.de
BUILD_DIR=build
INITIAL_DIR="$(pwd)"
FETCH_ONLY=0

if [ $# -lt 1 ]; then
	echo "Usage:   do-gdb.sh <toolchain target dir> [<gdb_version>] [<GNU mirror site>] [<build dir>] [gdb/insight] [--fetch-only]"
	echo "Example: do-gdb.sh /opt/msp430-gcc-latest $PKG_VERSION $GNU_MIRROR build"
	exit 1
fi

TARGET_LOCATION="$1"
shift

if [ $# -ge 1 ] && [ -n "$1" ]; then PKG_VERSION="$1" ; shift ; fi
if [ $# -ge 1 ] && [ -n "$1" ]; then GNU_MIRROR="$1" ; shift ; fi
if [ $# -ge 1 ] && [ -n "$1" ]; then BUILD_DIR="$1" ; shift ; fi
if [ $# -ge 1 ] && [ -n "$1" ]; then PKG_NAME="$1" ; shift ; fi

while [ $# -ge 1 ] ; do
	case "$1" in
		--fetch-only)	FETCH_ONLY=1 ;;
		*)		echo >&2 "Ambiguous options $@." ; exit 1 ;;
	esac
	shift
done

case "$PKG_NAME" in
gdb)
	PKG_SRC_URL="ftp://$GNU_MIRROR/pub/gnu/gdb/gdb-$PKG_VERSION.tar.bz2"
	;;
insight)
	PKG_SRC_URL="ftp://sourceware.org/pub/insight/releases/insight-$PKG_VERSION.tar.bz2"
	;;
*)
	echo "Package name must be either gdb or insight."
	exit 1
	;;
esac

INSTALL_LAUNCHER=$(sh do-detect-sudo.sh "$TARGET_LOCATION")

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

export PATH="$PATH:$TARGET_LOCATION/bin"

wget -c "$PKG_SRC_URL" -O "$PKG_NAME-$PKG_VERSION.tar.bz2"
echo "Unpacking $PKG_NAME..."
tar xjf "$PKG_NAME-$PKG_VERSION.tar.bz2"

cd "$PKG_NAME-$PKG_VERSION"
cp -rf "$INITIAL_DIR"/ports/gdb-6-and-7/* .

if [ $FETCH_ONLY = 1 ]; then
	echo "$PKG_NAME $PKG_VERSION downloaded successfully"
	exit 0
fi

if test -e "$INITIAL_DIR/$PKG_NAME-$PKG_VERSION.patch" ; then
       patch -p1 < "$INITIAL_DIR/$PKG_NAME-$PKG_VERSION.patch"
fi

cd ..
mkdir -p "$PKG_NAME-$PKG_VERSION-build"
cd "$PKG_NAME-$PKG_VERSION-build"

"$(pwd)/../$PKG_NAME-$PKG_VERSION/configure" "--prefix=$TARGET_LOCATION" --target=msp430
make -j$(num_cpus)
$INSTALL_LAUNCHER make install

cd "$INITIAL_DIR"
