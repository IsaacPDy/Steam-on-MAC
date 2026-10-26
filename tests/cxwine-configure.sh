#!/bin/bash
# Run under Rosetta so Wine's configure sees an x86_64 host.
export PATH="/opt/homebrew/opt/bison/bin:/opt/homebrew/opt/flex/bin:/opt/homebrew/opt/mingw-w64/bin:/opt/homebrew/bin:$PATH"
export CC="clang -arch x86_64" CXX="clang++ -arch x86_64"
export CFLAGS="-O2 -I/opt/homebrew/include -I/opt/homebrew/include/freetype2"
export CROSSCFLAGS="-O2"
export LDFLAGS="-Wl,-headerpad_max_install_names -Wl,-rpath,@loader_path/../../ -Wl,-rpath,@loader_path/"
export ac_cv_lib_soname_freetype=libfreetype.6.dylib
export ac_cv_lib_soname_gnutls=libgnutls.30.dylib
export ac_cv_lib_soname_MoltenVK=libMoltenVK.dylib
exec ../sources/wine/configure --enable-archs=i386,x86_64 --disable-tests \
  --without-x --without-gstreamer --without-sdl --without-cups --without-pcap --without-gphoto --without-sane --without-krb5 --without-v4l2 --without-usb --without-pulse --without-oss --without-alsa --without-capi --without-unwind \
  --prefix=$HOME/cxwine/install
