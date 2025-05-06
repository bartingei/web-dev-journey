#!/bin/sh
# Author: Daniel Starke
# Date: 2024-08-28
# Notes:
# Put this script in a clean folder and extract the needed
# sources to the sub directory ${SRC}. Execute it then from
# MSYS with an installed mingw compiler environment.
# Make sure the installed gcc compiler has the same version
# as the source for the cross compiler.
# The script was only tested on Windows 7 Professional x64
# to work with the gcc version 14.2.0. You need binutils 2.32 for gcc 14.2.0.
# Thread Local Storage is not supported.
# Link all x86_64-w64-mingw32-* to * for host gcc and make sure libstdc++*.dll is in path (see bottom).
### change "LDFLAGS = @LDFLAGS@" to "LDFLAGS := -s" in src/gcc-14.2.0/libstdc++-v3/Makefile.in
# Change the following configuration settings accordingly.
# configuration

ROOT="`pwd`"
PREFIX="/mingw64-64"
GMP="gmp-6.1.2"
MPFR="mpfr-3.1.6"
MPC="mpc-1.1.0"
WITH_CLOOG="isl" #none, isl
ISL="isl-0.18"
CLOOG_ISL="cloog-0.18.4"
BINUTILS="binutils-2.32"
MINGW="mingw-w64-v10.0.0"
MINGW_H="mingw-w64-headers"
MINGW_CRT="mingw-w64-crt"
MINGW_PTHREADS="mingw-w64-libraries/winpthreads"
GCC="gcc-14.2.0"
BUILD="bin64-64"
SRC="src"
#GCC_LANGS="c,c++,ada,fortran,objc,obj-c++"
GCC_LANGS="c,c++"
GCC_CONFIG="--enable-languages=${GCC_LANGS} --enable-seh-exceptions --enable-threads=posix --disable-nls --enable-shared=libstdc++ --enable-static --enable-fully-dynamic-string --enable-lto --enable-plugins --enable-libgomp --with-dwarf2 --enable-mingw-wildcard=platform --disable-win32-registry --enable-version-specific-runtime-libs --prefix=${PREFIX} --with-sysroot=${PREFIX} --target=x86_64-w64-mingw32 --enable-targets=all --enable-checking=release"
STATEFILE="${ROOT}/build-mingw64-64.state"
PREPROCESSOR_FLAGS="-D__USE_MINGW_ANSI_STDIO=0"
THREADS=1
export PATH="/mingw64/bin:/bin:${PREFIX}/bin"
export CFLAGS="-O2 -mtune=core2 -march=core2 -fno-lto -fno-ident -mstackrealign -fomit-frame-pointer -Wno-maybe-uninitialized"
export CXXFLAGS="-O2 -mtune=core2 -march=core2 -fno-lto -fno-ident -mstackrealign -fomit-frame-pointer -Wno-maybe-uninitialized"
export LDFLAGS="-s -Wl,-Bstatic"
# check configuration
echo "[1/14] check configuration" > "${STATEFILE}"
[ ! -e "${PREFIX}" ] && mkdir "${PREFIX}"
if [ ! -e ${SRC}/$GMP ]; then
	echo "${SRC}/${GMP} not found."
	echo "see http://gmplib.org/"
	exit
fi
if [ ! -e ${SRC}/$MPFR ]; then
	echo "${SRC}/${MPFR} not found."
	echo "see http://www.mpfr.org/"
	echo "or https://gforge.inria.fr/projects/mpfr/"
	exit
fi
if [ ! -e ${SRC}/$MPC ]; then
	echo "${SRC}/${MPC} not found."
	echo "see http://mpc.multiprecision.org/"
	exit
fi
case "${WITH_CLOOG}" in
	"isl")
	if [ ! -e ${SRC}/$ISL ]; then
		echo "${SRC}/${ISL} not found."
		echo "see ftp://gcc.gnu.org/pub/gcc/infrastructure/"
		exit
	fi
	if [ ! -e ${SRC}/$CLOOG_ISL ]; then
		echo "${SRC}/${CLOOG_ISL} not found."
		echo "see http://www.cloog.org/"
		exit
	fi
	;;
esac
if [ ! -e ${SRC}/$BINUTILS ]; then
	echo "${SRC}/${BINUTILS} not found."
	echo "see ftp://ftp.gnu.org/gnu/binutils/"
	exit
fi
if [ ! -e ${SRC}/$MINGW ]; then
	echo "${SRC}/${MINGW} not found."
	echo "see http://sourceforge.net/projects/mingw-w64/"
	exit
fi
type -P flex >/dev/null
if [ $? -ne 0 ]; then
	echo "flex wasn't found, install it to continue."
	echo "see ftp://ftp.gnu.org/gnu/flex/"
	exit
fi
if [ ! -e ${SRC}/$GCC ]; then
	echo "${SRC}/${GCC} not found."
	echo "see http://gcc.gnu.org/"
	exit
fi
## remove previous build
echo "[2/14] remove previous build" > "${STATEFILE}"
rm -r -f "${BUILD}"
rm -r -f lib
rm -r -f $PREFIX/*
# build gmp
echo "[3/14] build gmp" > "${STATEFILE}"
[ ! -e "${BUILD}" ] && mkdir "${BUILD}"
[ ! -e "${BUILD}/${GMP}" ] && mkdir "${BUILD}/${GMP}"
[ ! -e "lib" ] && mkdir "lib"
[ ! -e "lib/${GMP}" ] && mkdir "lib/${GMP}"
cd "${BUILD}/${GMP}"
CPPFLAGS="-fexceptions" ../../${SRC}/$GMP/configure --host=x86_64-w64-mingw32 --enable-static --disable-shared --disable-cxx "--prefix=${ROOT}/lib/${GMP}"
make -j $THREADS
if [ $? -ne 0 ]; then echo "Failed 'make' gmp."; exit; fi
make -j $THREADS install
if [ $? -ne 0 ]; then echo "Failed 'make install' gmp."; exit; fi
cd "../.."
# build mpfr
echo "[4/14] build mpfr" > "${STATEFILE}"
[ ! -e "${BUILD}" ] && mkdir "${BUILD}"
[ ! -e "${BUILD}/${MPFR}" ] && mkdir "${BUILD}/${MPFR}"
[ ! -e "lib" ] && mkdir "lib"
[ ! -e "lib/${MPFR}" ] && mkdir "lib/${MPFR}"
cd "${BUILD}/${MPFR}"
../../${SRC}/$MPFR/configure --host=x86_64-w64-mingw32 --enable-static --disable-shared "--with-gmp=${ROOT}/lib/${GMP}" "--prefix=${ROOT}/lib/${MPFR}"
make -j $THREADS
if [ $? -ne 0 ]; then echo "Failed 'make' mpfr."; exit; fi
make -j $THREADS install
if [ $? -ne 0 ]; then echo "Failed 'make install' mpfr."; exit; fi
cd "../.."
# build mpc
echo "[5/14] build mpc" > "${STATEFILE}"
[ ! -e "${BUILD}" ] && mkdir "${BUILD}"
[ ! -e "${BUILD}/${MPC}" ] && mkdir "${BUILD}/${MPC}"
[ ! -e "lib" ] && mkdir "lib"
[ ! -e "lib/${MPC}" ] && mkdir "lib/${MPC}"
cd "${BUILD}/${MPC}"
../../${SRC}/$MPC/configure --host=x86_64-w64-mingw32 --enable-static --disable-shared "--with-gmp=${ROOT}/lib/${GMP}" "--with-mpfr=${ROOT}/lib/${MPFR}" "--prefix=${ROOT}/lib/${MPC}"
make -j $THREADS
if [ $? -ne 0 ]; then echo "Failed 'make' mpc."; exit; fi
make -j $THREADS install
if [ $? -ne 0 ]; then echo "Failed 'make install' mpc."; exit; fi
cd "../.."
case "${WITH_CLOOG}" in
	"isl")
	# build isl
	echo "[6/14] build isl" > "${STATEFILE}"
	[ ! -e "${BUILD}" ] && mkdir "${BUILD}"
	[ ! -e "${BUILD}/${ISL}" ] && mkdir "${BUILD}/${ISL}"
	[ ! -e "lib" ] && mkdir "lib"
	[ ! -e "lib/${ISL}" ] && mkdir "lib/${ISL}"
	cd "${BUILD}/${ISL}"
	../../${SRC}/$ISL/configure --host=x86_64-w64-mingw32 --enable-static --disable-shared --enable-portable-binary "--with-gmp-prefix=${ROOT}/lib/${GMP}" "--prefix=${ROOT}/lib/${ISL}"
	make -j $THREADS
	if [ $? -ne 0 ]; then echo "Failed 'make' isl."; exit; fi
	make -j $THREADS install
	if [ $? -ne 0 ]; then echo "Failed 'make install' isl."; exit; fi
	cd "../.."
	# build cloog
	echo "[6/14] build cloog-isl" > "${STATEFILE}"
	[ ! -e "${BUILD}" ] && mkdir "${BUILD}"
	[ ! -e "${BUILD}/${CLOOG_ISL}" ] && mkdir "${BUILD}/${CLOOG_ISL}"
	[ ! -e "lib" ] && mkdir "lib"
	[ ! -e "lib/${CLOOG_ISL}" ] && mkdir "lib/${CLOOG_ISL}"
	cd "${BUILD}/${CLOOG_ISL}"
	../../${SRC}/$CLOOG_ISL/configure --host=x86_64-w64-mingw32 --enable-static --disable-shared "--with-gmp-prefix=${ROOT}/lib/${GMP}" "--with-isl-prefix=${ROOT}/lib/${ISL}" --with-osl=no --enable-portable-binary "--prefix=${ROOT}/lib/${CLOOG_ISL}"
	make -j $THREADS
	if [ $? -ne 0 ]; then echo "Failed 'make' cloog-isl."; exit; fi
	make -j $THREADS install
	if [ $? -ne 0 ]; then echo "Failed 'make install' cloog-isl."; exit; fi
	cd "../.."
	;;
esac
# build binutils
echo "[7/14] build binutils" > "${STATEFILE}"
[ ! -e "${BUILD}" ] && mkdir "${BUILD}"
[ ! -e "${BUILD}/${BINUTILS}" ] && mkdir "${BUILD}/${BINUTILS}"
cd "${BUILD}/${BINUTILS}"
case "${WITH_CLOOG}" in
	"isl")
	../../${SRC}/$BINUTILS/configure --host=x86_64-w64-mingw32 --enable-lto --enable-plugins --disable-nls --target=x86_64-w64-mingw32 --enable-targets=x86_64-w64-mingw32,i686-w64-mingw32 --with-sysroot=$PREFIX --prefix=$PREFIX "--with-gmp=${ROOT}/lib/${GMP}" "--with-mpfr=${ROOT}/lib/${MPFR}" "--with-mpc=${ROOT}/lib/${MPC}" "--with-isl=${ROOT}/lib/${ISL}" "--with-cloog=${ROOT}/lib/${CLOOG_ISL}" "--with-host-libstdcxx=-lstdc++ -lsupc++" --disable-isl-version-check --disable-cloog-version-check --enable-cloog-backend=isl
	;;
	*)
	../../${SRC}/$BINUTILS/configure --host=x86_64-w64-mingw32 --enable-lto --enable-plugins --disable-nls --target=x86_64-w64-mingw32 --enable-targets=x86_64-w64-mingw32,i686-w64-mingw32 --with-sysroot=$PREFIX --prefix=$PREFIX "--with-gmp=${ROOT}/lib/${GMP}" "--with-mpfr=${ROOT}/lib/${MPFR}" "--with-mpc=${ROOT}/lib/${MPC}"
	;;
esac
make -j $THREADS
if [ $? -ne 0 ]; then echo "Failed 'make' binuntils."; exit; fi
make -j $THREADS install
if [ $? -ne 0 ]; then echo "Failed 'make install' binuntils."; exit; fi
export PATH="$PATH:${PREFIX}/bin"
cd "../.."
# build libs/headers
echo "[8/14] build libs/headers" > "${STATEFILE}"
[ ! -e "${BUILD}/${MINGW_H}" ] && mkdir "${BUILD}/${MINGW_H}"
cd "${BUILD}/${MINGW_H}"
../../${SRC}/$MINGW/$MINGW_H/configure --build=mingw32 --host=x86_64-w64-mingw32 --prefix=$PREFIX
make -j $THREADS install
if [ $? -ne 0 ]; then echo "Failed 'make install' mingw-headers."; exit; fi
mkdir -p $PREFIX/x86_64-w64-mingw32/lib
cp -p -r $PREFIX/x86_64-w64-mingw32/lib $PREFIX/x86_64-w64-mingw32/lib64
cp -p -r $PREFIX/include $PREFIX/x86_64-w64-mingw32/include
cp -p -r $PREFIX/x86_64-w64-mingw32 $PREFIX/mingw
cd "../.."
# build gcc
echo "[9/14] build gcc for crt" > "${STATEFILE}"
[ ! -e "${BUILD}/${GCC}" ] && mkdir "${BUILD}/${GCC}"
cd "${BUILD}/${GCC}"
case "${WITH_CLOOG}" in
	"isl")
	../../${SRC}/$GCC/configure --host=x86_64-w64-mingw32 $GCC_CONFIG "--with-gmp=${ROOT}/lib/${GMP}" "--with-mpfr=${ROOT}/lib/${MPFR}" "--with-mpc=${ROOT}/lib/${MPC}" "--with-isl=${ROOT}/lib/${ISL}" "--with-host-libstdcxx=-lstdc++ -lsupc++"
	;;
	*)
	../../${SRC}/$GCC/configure --host=x86_64-w64-mingw32 $GCC_CONFIG "--with-gmp=${ROOT}/lib/${GMP}" "--with-mpfr=${ROOT}/lib/${MPFR}" "--with-mpc=${ROOT}/lib/${MPC}"
	;;
esac
make -j $THREADS all-gcc
if [ $? -ne 0 ]; then echo "Failed 'make all-gcc' gcc."; exit; fi
make -j $THREADS install-gcc
if [ $? -ne 0 ]; then echo "Failed 'make install-gcc' gcc."; exit; fi
cd "../.."
# build crt
echo "[10/14] build crt" > "${STATEFILE}"
[ ! -e "${BUILD}/${MINGW_CRT}" ] && mkdir "${BUILD}/${MINGW_CRT}"
cd "${BUILD}/${MINGW_CRT}"
../../${SRC}/$MINGW/$MINGW_CRT/configure --host=x86_64-w64-mingw32 --enable-lib32 --enable-lib64 --prefix=$PREFIX --with-sysroot=$PREFIX
make -j $THREADS
if [ $? -ne 0 ]; then echo "Failed 'make' mingw-crt."; exit; fi
make -j $THREADS install
if [ $? -ne 0 ]; then echo "Failed 'make install' mingw-crt."; exit; fi
cd "../.."
# refresh links
echo "[11/14] refresh links" > "${STATEFILE}"
# duplicate lib to lib64
cp -p -r $PREFIX/lib $PREFIX/lib64
if [ $? -ne 0 ]; then echo "Failed 'cp' lib."; exit; fi
# update mingw target
cp -p -r -u $PREFIX/lib $PREFIX/mingw/
if [ $? -ne 0 ]; then echo "Failed 'cp' lib."; exit; fi
cp -p -r -u $PREFIX/lib32 $PREFIX/mingw/
if [ $? -ne 0 ]; then echo "Failed 'cp' lib32."; exit; fi
cp -p -r -u $PREFIX/lib64 $PREFIX/mingw/
if [ $? -ne 0 ]; then echo "Failed 'cp' lib64."; exit; fi
# update x86_64 target
cp -p -r -u $PREFIX/lib $PREFIX/x86_64-w64-mingw32/
if [ $? -ne 0 ]; then echo "Failed 'cp' lib."; exit; fi
cp -p -r -u $PREFIX/lib32 $PREFIX/x86_64-w64-mingw32/
if [ $? -ne 0 ]; then echo "Failed 'cp' lib32."; exit; fi
cp -p -r -u $PREFIX/lib64 $PREFIX/x86_64-w64-mingw32/
if [ $? -ne 0 ]; then echo "Failed 'cp' lib64."; exit; fi
# build pthreads 32bit
echo "[12/14] build pthreads 32bit" > "${STATEFILE}"
[ ! -e "${BUILD}/${MINGW_PTHREADS}32" ] && mkdir -p "${BUILD}/${MINGW_PTHREADS}32"
_OLDPWD="${PWD}"
cd "${BUILD}/${MINGW_PTHREADS}32"
${_OLDPWD}/${SRC}/$MINGW/$MINGW_PTHREADS/configure --disable-shared --host=i686-w64-mingw32 "CC=x86_64-w64-mingw32-gcc -m32" "CXX=x86_64-w64-mingw32-g++ -m32" "STRIP=x86_64-w64-mingw32-strip" "AR=x86_64-w64-mingw32-ar" --prefix=$PREFIX/x86_64-w64-mingw32 --libdir=$PREFIX/x86_64-w64-mingw32/lib32 --with-sysroot=$PREFIX
make -j $THREADS
if [ $? -ne 0 ]; then echo "Failed 'make' mingw-pthreads-32."; exit; fi
make -j $THREADS install
if [ $? -ne 0 ]; then echo "Failed 'make install' mingw-pthreads-32."; exit; fi
make -j $THREADS install "includedir=${PREFIX}/mingw/include"
if [ $? -ne 0 ]; then echo "Failed 'make install' mingw-pthreads-32."; exit; fi
make -j $THREADS install "includedir=${PREFIX}/include"
if [ $? -ne 0 ]; then echo "Failed 'make install' mingw-pthreads-32."; exit; fi
cp -p -u $PREFIX/x86_64-w64-mingw32/lib32/libpthread.a $PREFIX/x86_64-w64-mingw32/lib32/libwinpthread.a $PREFIX/mingw/lib32
if [ $? -ne 0 ]; then echo "Failed 'cp' pthread."; exit; fi
cp -p -u $PREFIX/x86_64-w64-mingw32/lib32/libpthread.a $PREFIX/x86_64-w64-mingw32/lib32/libwinpthread.a $PREFIX/lib32
if [ $? -ne 0 ]; then echo "Failed 'cp' pthread."; exit; fi
cd "${_OLDPWD}"
# build pthreads 64bit
echo "[13/15] build pthreads 64bit" > "${STATEFILE}"
[ ! -e "${BUILD}/${MINGW_PTHREADS}64" ] && mkdir -p "${BUILD}/${MINGW_PTHREADS}64"
_OLDPWD="${PWD}"
cd "${BUILD}/${MINGW_PTHREADS}64"
${_OLDPWD}/${SRC}/$MINGW/$MINGW_PTHREADS/configure --disable-shared --host=x86_64-w64-mingw32 --prefix=$PREFIX/x86_64-w64-mingw32 --libdir=$PREFIX/x86_64-w64-mingw32/lib --with-sysroot=$PREFIX
make -j $THREADS
if [ $? -ne 0 ]; then echo "Failed 'make' mingw-pthreads-64."; exit; fi
make -j $THREADS install
if [ $? -ne 0 ]; then echo "Failed 'make install' mingw-pthreads-64."; exit; fi
make -j $THREADS install "includedir=${PREFIX}/mingw/include"
if [ $? -ne 0 ]; then echo "Failed 'make install' mingw-pthreads-64."; exit; fi
make -j $THREADS install "includedir=${PREFIX}/mingw/include"
if [ $? -ne 0 ]; then echo "Failed 'make install' mingw-pthreads-64."; exit; fi
make -j $THREADS install "includedir=${PREFIX}/include"
if [ $? -ne 0 ]; then echo "Failed 'make install' mingw-pthreads-64."; exit; fi
make -j $THREADS install "includedir=${PREFIX}/include"
if [ $? -ne 0 ]; then echo "Failed 'make install' mingw-pthreads-64."; exit; fi
cp -p -u $PREFIX/x86_64-w64-mingw32/lib/libpthread.a $PREFIX/x86_64-w64-mingw32/lib/libwinpthread.a $PREFIX/mingw/lib
if [ $? -ne 0 ]; then echo "Failed 'cp' pthread."; exit; fi
cp -p -u $PREFIX/x86_64-w64-mingw32/lib/libpthread.a $PREFIX/x86_64-w64-mingw32/lib/libwinpthread.a $PREFIX/lib
if [ $? -ne 0 ]; then echo "Failed 'cp' pthread."; exit; fi
cp -p -u $PREFIX/x86_64-w64-mingw32/lib/libpthread.a $PREFIX/x86_64-w64-mingw32/lib/libwinpthread.a $PREFIX/lib64
if [ $? -ne 0 ]; then echo "Failed 'cp' pthread."; exit; fi
cp -p -u $PREFIX/x86_64-w64-mingw32/lib/libpthread.a $PREFIX/x86_64-w64-mingw32/lib/libwinpthread.a $PREFIX/x86_64-w64-mingw32/lib64
if [ $? -ne 0 ]; then echo "Failed 'cp' pthread."; exit; fi
cd "${_OLDPWD}"
find $PREFIX -type f -name "pthread.h" -exec sed -i 's| DLL_EXPORT| WINPTHREAD_DLL_EXPORT|g' "{}" ";" # because of static build
# build gcc finishing
echo "[14/14] build gcc finishing" > "${STATEFILE}"
if [ -n "${PREPROCESSOR_FLAGS}" ]; then
	export CPPFLAGS="${PREPROCESSOR_FLAGS}"
	export BOOT_CPPFLAGS="${PREPROCESSOR_FLAGS}"
	export CPPFLAGS_FOR_BUILD="${PREPROCESSOR_FLAGS}"
	export CPPFLAGS_FOR_TARGET="${PREPROCESSOR_FLAGS}"
fi
cd "${BUILD}/${GCC}"
rm -r -f *
case "${WITH_CLOOG}" in
	"isl")
	../../${SRC}/$GCC/configure --host=x86_64-w64-mingw32 $GCC_CONFIG "--with-gmp=${ROOT}/lib/${GMP}" "--with-mpfr=${ROOT}/lib/${MPFR}" "--with-mpc=${ROOT}/lib/${MPC}" "--with-isl=${ROOT}/lib/${ISL}" "--with-cloog=${ROOT}/lib/${CLOOG_ISL}" "--with-host-libstdcxx=-lstdc++ -lsupc++" --disable-cloog-version-check --enable-cloog-backend=isl
	;;
	*)
	../../${SRC}/$GCC/configure --host=x86_64-w64-mingw32 $GCC_CONFIG "--with-gmp=${ROOT}/lib/${GMP}" "--with-mpfr=${ROOT}/lib/${MPFR}" "--with-mpc=${ROOT}/lib/${MPC}"
	;;
esac
make -j $THREADS
if [ $? -ne 0 ]; then echo "Failed 'make' gcc."; exit; fi
make -j $THREADS install
if [ $? -ne 0 ]; then echo "Failed 'make install' gcc."; exit; fi
if [ ! -e "${PREFIX}/bin/liblto_plugin.dll" ]; then
	cp "${PREFIX}/libexec/gcc/x86_64-w64-mingw32/${GCC#gcc-}/liblto_plugin.dll" "${PREFIX}/bin/"
fi
if [ -e "${PREFIX}/libexec/gcc/x86_64-w64-mingw32/${GCC#gcc-}/liblto_plugin.dll" ]; then
	mkdir -p "${PREFIX}/mingw/lib/bfd-plugins"
	cp "${PREFIX}/libexec/gcc/x86_64-w64-mingw32/${GCC#gcc-}/liblto_plugin.dll" "${PREFIX}/mingw/lib/bfd-plugins"
	mkdir -p "${PREFIX}/x86_64-w64-mingw32/lib/bfd-plugins"
	cp "${PREFIX}/libexec/gcc/x86_64-w64-mingw32/${GCC#gcc-}/liblto_plugin.dll" "${PREFIX}/x86_64-w64-mingw32/lib/bfd-plugins"
fi
cd "${PREFIX}/bin" && for i in *.exe; do a="${i#x86_64-w64-mingw32-}"; [ ! -e $a ] && cmd /c "mklink $a $i"; done; cd $OLDPWD
echo "done" > "${STATEFILE}"
cat << _INFOTEXT

Finished building gcc cross compiler for x86/x64 windows.
Update paths to use the new compiler.
_INFOTEXT
