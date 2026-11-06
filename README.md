# Ripple for legacy iOS

An unofficial native client for [Ripple](https://ripple.tel/), built with UIKit
for jailbroken iOS devices. It connects directly to Ripple over HTTPS, without
an intermediary server or a public API.

**Development build 0.1.8** — tested on an iPhone 5 running iOS 6.1.4. This is a
32-bit armv7 app and requires iOS 6–10 with 32-bit app support. Other devices and
OS versions have not been verified.

## Install

Both the `.ipa` and `.deb` are available from [Releases](https://github.com/vgs499p/ripple-ios/releases).
The `.deb` installs to `/Applications/Ripple.app` and refreshes the icon cache.
It requires a compatible jailbreak. Use an appropriate jailbreak installer for
the IPA; it is not App Store signed.

You can also add the [Poop Labs APT repository](https://poopware-laboratories.github.io/pooplabs-apt-repo/)
in Cydia → Sources → Edit → Add:

```text
https://poopware-laboratories.github.io/pooplabs-apt-repo/
```

Search for **Ripple** (package `tel.ripple.native.ios6`).

## Current state

- Public and following timelines, Older/Newer pagination, search and a user directory.
- Native profile pages with profile banners, avatars, biographies and account counts.
- Native sign-in, conversations, text posts, replies, quotes, likes and reposts.
- Photo viewing and foreground notification polling.
- Options for alerts about people you follow or every public post.

Sign-in and public timeline loading have been confirmed on the test phone.
The remaining flows have not all been tested end to end. Photo uploads, full
profile customization and the optional background notification helper are still
in progress. **Alerts currently require Ripple to remain open.**

Sign-in sessions are saved in the device Keychain and restored across restarts.
Sign out deletes the saved session. Your password is never stored. Ripple can
still expire or revoke a session; the client does not bypass server expiry. Failure diagnostics contain response codes, cookie counts and page
markers, never passwords or cookie values. Development screenshots are enabled
only by the optional `RIPPLE_DEVICE_TEST` compile flag.

Requests identify this client as `RippleNative-iOS/0.1.8 (iPhone; iOS <runtime-version>; armv7)`.
The version is read from iOS at runtime. The Ripple server controls how that
value is labeled in its Sessions page; older sessions keep the user-agent value
recorded when they were created.

## Build

Use macOS with Apple clang, `ldid`, and your own licensed armv7-capable iPhoneOS
SDK. The tested SDK is iPhoneOS 6.1. The SDK and Apple frameworks are not included.
The iOS compatibility client is Objective-C; the desktop Rust client is maintained
separately in [ripple-mac](https://github.com/vgs499p/ripple-mac).

```sh
IOS_SDK=/absolute/path/to/iPhoneOS6.1.sdk sh build.sh
sh package-deb.sh
```

Outputs are placed in `build/`. Set `IOS_BUILD_DIR` in both commands to use a
different directory. Debian packaging requires `dpkg-deb`; it uses gzip for
compatibility with legacy iOS package managers.

Run parser regression tests on macOS:

```sh
sh scripts/test-parser.sh
```

`Tests/session-test.m` uses a dedicated synthetic Keychain item to check save,
restore in a new process, cookie rotation, path scoping, and sign-out cleanup.
It never uses or displays a real account session.

The parser tests cover login form discovery, empty action resolution, submit/hidden
fields, account recognition, trusted HTTPS destinations, text and pagination.
`Tests/network-probe.m` can check login-page discovery on a device without
submitting credentials.

## License

Application source is **GPL-2.0-or-later**; see [LICENSE](LICENSE).
Ripple branding and website content belong to their respective owners.
