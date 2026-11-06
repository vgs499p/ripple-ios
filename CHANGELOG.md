# Changelog

## 0.1.3 — 2026-11-06

First separately published legacy iOS development build.

- Recognize Ripple’s standalone login page, including its empty form action.
- Preserve hidden fields and the login submit control.
- Confirm sign-in using the authenticated composer/logout state.
- Recover the account handle through the own-profile menu.
- Provide native timeline, conversation and text composition screens.
- Package an IPA and a gzip-compressed Debian package for legacy Cydia.

Tested: direct HTTPS, public timeline parsing and successful sign-in on an
armv7 iPhone 5 running iOS 6.1.4. Other feature flows remain under development.
