# Nova one-click Termux:X11 extra-key-bar suppression experiment — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The productized direct Termux:X11 path already stretches the live `1280x800`
Steam window over the Nova's `1280x960` Android surface, but the user-visible
Termux:X11 extra-key bar (`Esc`, `Home`, `End`, `PgUp`, and related keys)
remains an end-user artifact. Can the one-click launcher suppress that bar as
part of its existing reversible Termux:X11 preference transaction, without
changing the X11 display geometry or leaving preferences modified after stop?

## Fixed profile

- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- APK: `com.xjsonderulo.steamandroid.novalab`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Presentation: direct Termux:X11, Android `1280x960`, stretched X11
  `1280x800`
- Steam: signed-in normal one-click session, software Steam/CEF profile
- Input: no synthetic or physical input will be sent
- Audio: disabled for this display-only run
- Gamescope/AHardwareBuffer: not used
- New launcher variable: `NOVA_ANDROID_LAUNCHER_X11_HIDE_EXTRA_KEYBAR=1`

The launcher must set both Termux:X11 keys to false during the session:

```text
showAdditionalKbd=false
additionalKbdVisible=false
```

The original preferences file, owner, group, mode, and SHA-256 must be
captured before modification and restored byte-for-byte after the run.

## Run identity and acceptance

The final timestamp and evidence directory are assigned immediately before
launch. The intended run ID is:

```text
nova-one-click-x11-keybar-suppression-20260810T
```

A pass requires all of the following from one fresh session:

1. the launcher records the new key-bar profile and fresh readiness;
2. the Android screenshot is a settled Steam frame at `1280x960` without the
   extra-key bar visible;
3. Termux:X11 logs still report the expected `1280x800` stretched buffer and
   the X11 tree has a viewable Steam child;
4. the Steam frame is not replaced by an Android settings overlay; and
5. stop and exact cleanup pass, with no Nova runtime/socket residue and the
   original Termux:X11 preferences hash restored.

An X11 source-frame result without an Android screenshot is not sufficient.
This run does not claim Gamescope, hardware Steam/CEF rendering, game
rendering, controller consumption, touchscreen navigation, audio, networking,
or standalone APK independence.

## Implementation under test

`nova-one-click-root-launcher.sh` will add the key-bar setting to the existing
backup/rewrite/restore transaction. The default is enabled for the product
launcher, while `NOVA_ANDROID_LAUNCHER_X11_HIDE_EXTRA_KEYBAR=0` remains
available for a controlled diagnostic comparison. No persistent preference or
Termux:X11 package file is changed by the source update.

This predeclaration is committed and pushed before the device session.
