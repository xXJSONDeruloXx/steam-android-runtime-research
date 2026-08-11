# Nova rootless Termux/X11 dependency install — 2026-08-10

Status: dependency boundary installed; rootless X11 TCP frame test pending.

## Device and artifact identity

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Existing X11 APK: `com.termux.x11`, version
  `1.03.01-d8013ac-09.08.26`, APK SHA-256
  `6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705`.
- Existing X11 APK signing certificate SHA-256:
  `b6da01480eefd5fbf2cd3771b8d1021ec791304bdd6c4bf41d3faabad48ee5e1`.
- Installed base APK: official Termux GitHub
  `v0.119.0-beta.3`, `apt-android-7`, arm64-v8a, SHA-256
  `3bb969df2400d884ccb929b7d79cc76861f291c98942c401e12408d734a460f3`.
- The base APK certificate matched the existing X11 APK exactly.
- Installed Termux packages: `x11-repo=8.4-1`,
  `termux-x11-nightly=1.03.01-5`, and its `xkeyboard-config` dependency.

The APK was installed alongside the rooted Nova runtime. No Nova package,
versioned Holo rootfs, active marker, Termux:X11 process, Steam data, or
authentication file was removed or copied.

## Implementation

`android/nova-lab/rootless/nova-rootless-termux-x11.sh` is the Termux-side
launcher. It runs under the Termux app UID, refuses a real root UID, starts a
separate display number, records a PID/log under Termux's private home, and
supports exact `start`, `status`, and `stop` operations. The Nova side is
expected to invoke it through Termux's `RUN_COMMAND` service after declaring
`com.termux.permission.RUN_COMMAND` and obtaining the user's grant.

`android/nova-lab/rootless/termux.properties` records the required
`allow-external-apps=true` property. This is a user-visible permission boundary,
not an implicit root fallback.

For the first boundary test the launcher uses `:77 -listen tcp -ac` so Nova
can reach the X server without reading Termux's private filesystem. `-ac` is
only an experimental loopback transport workaround while the app-owned bridge
and X11 authentication path are designed; it must not become the shipped
default without a loopback/authentication restriction.

## Next run

Launch the Termux-side `:77` server as `com.termux`, verify that the process is
owned by the Termux app UID, then connect from Nova's app UID using the Holo
X11 client over `127.0.0.1:6077`. Capture a fresh X11 window/frame result and
stop only the exact `:77` process. A TCP port open without an X11 protocol or
window result is not an R1 pass.
