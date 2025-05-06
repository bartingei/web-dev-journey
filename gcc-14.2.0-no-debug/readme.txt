1. build libraries and dlls with build-mingw64-64-posix-lto.sh
2. rename created output folder
3. build applications with build-mingw64-64-posix.sh
4. run copy-libs.sh in renamed library output folder (or adjust paths within this file)
5. copy libstdc++.dll from host gcc to target/lib/gcc...