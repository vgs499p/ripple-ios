# 0.1.10

- Refresh like/repost counts from the current feed and page, show pending requests, and highlight confirmed count changes without resetting scroll position.

# Changelog

## 0.1.9 — 2026-11-06

- Keep the **Post** control visible on the narrow Timeline navigation bar.
- Move feed refresh to pull-to-refresh.

## 0.1.8 — 2026-11-06

- Label the timeline composer control **Post** so it is easy to find.

## 0.1.7 — 2026-11-06

- Fix Notifications being routed to an empty profile view when its URL includes
  the `tlmode=mentions` query.
- Fix accent selection by matching the chosen palette label instead of the
  action-sheet button index.

## 0.1.6 — 2026-11-06

- Add persisted accent choices: Ripple Red, Breeze Orange, Leaf Green, Rose Pink,
  Nord Blue, Amethyst and Graphite.
- Add native profile pages with banners, avatars, biographies and account counts.
- Upgrade Ripple's same-host legacy HTTP profile redirects to HTTPS before
  attaching session cookies.

## 0.1.4 — 2026-11-06

- Save sign-in sessions in Keychain and restore them on launch.
- Keep passwords out of saved data and honor cookie expiry and path scope.
- Preserve rotated cookies and clear saved sign-in when signing out.
- Ignore responses from the previous session after sign-out.
- Add a dedicated Keychain access group for the jailbreak-signed app.


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
