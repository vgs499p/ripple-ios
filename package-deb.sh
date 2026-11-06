#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUT=${IOS_BUILD_DIR:-"$HERE/build"}
mkdir -p "$OUT"
OUT=$(CDPATH= cd -- "$OUT" && pwd)
APP="$OUT/Ripple.app"
test -f "$APP/RippleLegacy" || { echo 'Build Ripple.app first with build.sh.' >&2; exit 1; }
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Info.plist")
PACKAGE=tel.ripple.native.ios6
STAGE=$(mktemp -d "$OUT/.deb-stage.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT HUP INT TERM
mkdir -p "$STAGE/Applications" "$STAGE/DEBIAN" "$STAGE/usr/share/doc/$PACKAGE"
cp -R "$APP" "$STAGE/Applications/Ripple.app"
cp "$HERE/LICENSE" "$HERE/NOTICE" "$STAGE/usr/share/doc/$PACKAGE/"
SIZE=$(du -sk "$STAGE/Applications" "$STAGE/usr" | awk '{sum += $1} END {print sum}')
cat >"$STAGE/DEBIAN/control" <<EOF
Package: $PACKAGE
Name: Ripple
Version: $VERSION
Architecture: iphoneos-arm
Section: Applications
Priority: optional
Maintainer: vgs499p <342574562+vgs499p@users.noreply.github.com>
Author: Ripple Native contributors
Depends: firmware (>= 6.0), firmware (<< 11.0)
Installed-Size: $SIZE
Homepage: https://github.com/vgs499p/ripple-ios
Depiction: https://github.com/vgs499p/ripple-ios/releases/tag/v$VERSION
Icon: file:///Applications/Ripple.app/Icon@2x.png
Tag: role::enduser
Description: Native Ripple client for legacy iOS (development build)
 Direct HTTPS timeline, sign-in, conversations and text posting.
 For jailbroken devices with 32-bit app support. Tested on iOS 6.1.4.
 Background notification helper and photo uploads are not included.
EOF
for SCRIPT in postinst postrm; do
  cp "$HERE/packaging/$SCRIPT" "$STAGE/DEBIAN/$SCRIPT"
done
find "$STAGE" -type d -exec chmod 755 {} +
find "$STAGE" -type f -exec chmod 644 {} +
chmod 755 "$STAGE/Applications/Ripple.app/RippleLegacy" "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/postrm"
# Old iOS dpkg does not understand zstd. Both tar members must use gzip.
COPYFILE_DISABLE=1 dpkg-deb --root-owner-group --uniform-compression -Zgzip -z9 \
  --build "$STAGE" "$OUT/${PACKAGE}_${VERSION}_iphoneos-arm.deb"
