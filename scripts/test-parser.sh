#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEMP=$(mktemp -d)
trap 'rm -rf "$TEMP"' EXIT HUP INT TERM
SDK=$(xcrun --sdk macosx --show-sdk-path)
xcrun clang -fobjc-arc -fblocks -Wno-deprecated-declarations -isysroot "$SDK" \
  -I "$SDK/usr/include/libxml2" -I "$HERE/Sources" \
  "$HERE/Tests/parser-test.m" "$HERE/Sources/RPClient.m" "$HERE/Sources/RPSession.m" \
  -framework Foundation -framework CFNetwork -framework Security -lxml2 -o "$TEMP/parser-test"
"$TEMP/parser-test" "$@"
