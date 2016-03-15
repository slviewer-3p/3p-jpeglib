#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

JPEGLIB_VERSION="8c"
JPEGLIB_SOURCE_DIR="jpeg-$JPEGLIB_VERSION"

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

# load autbuild provided shell functions and variables
set +x
eval "$("$autobuild" source_environment)"
set -x

# set LL_BUILD and friends
set_build_variables convenience Release

stage="$(pwd)/stage"

build=${AUTOBUILD_BUILD_ID:=0}
echo "${JPEGLIB_VERSION}.${build}" > "${stage}/VERSION.txt"

pushd "$JPEGLIB_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        windows*)
            load_vsvars

            case "${AUTOBUILD_VSVER:-}" in
                "120")
                    target="setup-v12"
                    ;;
                *)
                    fail "Unrecognized AUTOBUILD_VSVER = '${AUTOBUILD_VSVER:-}'"
                    ;;
            esac

            nmake -f makefile.vc "$target"

            build_sln "jpeg.sln" "Release|$AUTOBUILD_WIN_VSPLATFORM" "jpeg"

            mkdir -p "$stage/lib/release"

            if [ "$AUTOBUILD_ADDRSIZE" = 32 ]
            then cp "Release\jpeg.lib" "$stage/lib/release/jpeglib.lib"
            else cp "x64\Release\jpeg.lib" "$stage/lib/release/jpeglib.lib"
            fi

            mkdir -p "$stage/include/jpeglib"
            cp {jconfig.h,jerror.h,jinclude.h,jmorecfg.h,jpeglib.h} "$stage/include/jpeglib"
        ;;
        darwin*)
            opts="-arch $AUTOBUILD_CONFIGURE_ARCH $LL_BUILD"
            export CFLAGS="$opts" 
            export CPPFLAGS="$opts" 
            export LDFLAGS="$opts"
            ./configure --prefix="$stage"
            make
            make install
            mv "$stage/lib" "$stage/release"
            mkdir -p "$stage/lib"
            mv "$stage/release" "$stage/lib"
            mkdir -p "$stage/include/jpeglib"
            mv "$stage/include/"*.h "$stage/include/jpeglib/"
        ;;
        linux*)
            opts="-m$AUTOBUILD_ADDRSIZE $LL_BUILD"
            CFLAGS="$opts" CXXFLAGS="$opts" ./configure --prefix="$stage"
            make
            make install
            mv "$stage/lib" "$stage/release"
            mkdir -p "$stage/lib"
            mv "$stage/release" "$stage/lib"
            mkdir -p "$stage/include/jpeglib"
            mv "$stage/include/"*.h "$stage/include/jpeglib/"
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp README "$stage/LICENSES/jpeglib.txt"
popd

pass

