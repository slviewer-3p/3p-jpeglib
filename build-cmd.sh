#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

JPEGLIB_VERSION="8c"
JPEGLIB_SOURCE_DIR=""

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

stage="$(pwd)/stage"
pushd "$JPEGLIB_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            load_vsvars
            
            nmake -f makefile.vc setup-v10
            
            build_sln "jpeg.sln" "Release|Win32" 

            mkdir -p "$stage/lib/debug"
            mkdir -p "$stage/lib/release"
            cp "Release\jpeg.lib" \
                "$stage/lib/release/jpeglib.lib"
                
            mkdir -p "$stage/include/jpeglib"
            cp {jconfig.h,jerror.h,jinclude.h,jmorecfg.h,jpeglib.h} "$stage/include/jpeglib"
        ;;
        "darwin")
            ./configure --prefix="$stage"
            make
            make install
			mkdir -p "$stage/include/jpeglib"
			mv "$stage/include/"*.h "$stage/include/jpeglib/"
        ;;
        "linux")
            CFLAGS="-m32" CXXFLAGS="-m32" ./configure --prefix="$stage"
            make
            make install
			mkdir -p "$stage/include/jpeglib"
			mv "$stage/include/"*.h "$stage/include/jpeglib/"
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp README "$stage/LICENSES/jpeglib.txt"
popd

pass

