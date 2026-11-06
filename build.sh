#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
: "${IOS_SDK:?Set IOS_SDK to a legacy armv7-capable iPhoneOS SDK}"
OUT=${IOS_BUILD_DIR:-"$HERE/build"}
mkdir -p "$OUT"
OUT=$(CDPATH= cd -- "$OUT" && pwd)
APP="$OUT/Ripple.app"
rm -rf "$APP"
mkdir -p "$APP"
for SOURCE in main RPClient RPSession RPImages RPPostCell RPScreens RPSettings RPAlerts; do
  xcrun clang -target armv7-apple-ios6.0 -marm -miphoneos-version-min=6.0 -isysroot "$IOS_SDK" \
    ${IOS_EXTRA_CFLAGS:-} -fobjc-arc -fblocks -Os -Wall -Wextra -Wno-unused-parameter -I"$IOS_SDK/usr/include/libxml2" \
    -c "$HERE/Sources/$SOURCE.m" -o "$OUT/$SOURCE.o"
done
xcrun clang -target armv7-apple-ios6.0 -marm -miphoneos-version-min=6.0 -isysroot "$IOS_SDK" \
  "$OUT/main.o" "$OUT/RPClient.o" "$OUT/RPSession.o" "$OUT/RPImages.o" "$OUT/RPPostCell.o" "$OUT/RPScreens.o" "$OUT/RPSettings.o" "$OUT/RPAlerts.o" -framework UIKit -framework Foundation -framework CFNetwork -framework Security -framework CoreGraphics -framework QuartzCore -framework ImageIO -lobjc -lxml2 -Wl,-no_data_const -Wl,-no_fixup_chains -o "$APP/RippleLegacy"

cp "$HERE/Resources/"* "$APP/"
ldid -S"$HERE/Resources/Entitlements.plist" -Hsha1 "$APP/RippleLegacy"
STAGE=$(mktemp -d "$OUT/.ipa-stage.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT HUP INT TERM
mkdir -p "$STAGE/Payload"
cp -R "$APP" "$STAGE/Payload/"
rm -f "$OUT/Ripple-iOS6-armv7.ipa"
(cd "$STAGE" && COPYFILE_DISABLE=1 /usr/bin/zip -q -r -X "$OUT/Ripple-iOS6-armv7.ipa" Payload)
/usr/bin/file "$APP/RippleLegacy"
printf 'Built %s\n' "$OUT/Ripple-iOS6-armv7.ipa"
