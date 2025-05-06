#!/bin/sh

SRC="."
DST="/mingw64-64"

function ExitError() {
	echo "Error: $1" >&2
	cd "${_OLDPWD}"
	exit 1
}

export _OLDPWD="${PWD}"

[ ! -d "${SRC}" ] && ExitError "Source path \"${SRC}\" not found."
[ ! -d "${DST}" ] && ExitError "Destination path \"${DST}\" not found."

cd "${SRC}" || ExitError "Failed to cd to source path \"${SRC}\"."

mkdir -p "${DST}/mingw/lib/bfd-plugins" || ExitError "Failed to create x86 plugin directory."
mkdir -p "${DST}/x86_64-w64-mingw32/lib/bfd-plugins" || ExitError "Failed to create x64 plugin directory."
find . -type f '(' -name '*.dll' -o -name '*.a' -o -name '*.o' ')' -exec cp "{}" "${DST}/{}" ";" || ExitError "Failed to copy files."

cd "${_OLDPWD}"
