# Nova rootless R9 — Termux:X11 and network handoff predeclaration — 2026-08-11

Run ID: `nova-rootless-r9-x11-network-20260811T070826Z`
Sub-run: `R9-rootless-x11-network-steam-handoff`
Status: predeclared; R8 supervisor evidence was pushed and its exact trees
were removed before this run.

## Purpose and controlled change

R8 proved that the app-UID supervisor can enter the public ARM64 Steam seed,
but the seed's updater failed with `XOpenDisplay failed` and HTTP error 0
when no X11 server was present. R9 adds the two missing runtime conditions
together:

- install and verify the current Nova APK in place, then start a fresh
  Termux-owned `:77` server through the APK's `RootlessLauncherService`;
- connect the guest over `DISPLAY=127.0.0.1:77` and the Android-inherited
  network namespace; and
- run the unchanged app-owned closure and supervisor with the standard
  Steam Big Picture flags:
  `-gamepadui -steamos3 -steampal -steamdeck`.

Gamescope/AHardwareBuffer, DRM/KMS, rooted paths, Runtime 4/Proton, audio,
controller relays, Steam authentication, and SteamUI patches remain out of
scope. The public seed is fresh, so its updater frame and manifest handoff are
the first acceptance boundary.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `7f0efd7` (`docs: record rootless R8 supervisor boundary`).
- APK to install in place:
  `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `1c246f292053b0e7463874ff376c4c75c5f180e61d0e767c78297481db302507`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo SteamUI manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- Termux base: official `v0.119.0-beta.3`, arm64-v8a.
- Termux:X11: `1.03.01-d8013ac-09.08.26`; both dependency artifact hashes
  are recorded in [354](354-nova-rootless-termux-base-install-2026-08-10.md).

Installing the APK uses `adb install -r` only; it must not clear Nova data.
The rootless run still uses a new app-owned home and never reads or copies
rooted Steam data.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r9-x11-network-20260811T070826Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r9-x11-network-20260811T070826Z/
```

The Termux bridge has a separate exact state scope for display `:77`:

```text
/data/data/com.termux/files/home/.nova-rootless/
```

Only the `:77` helper PID/log and the matching `127.0.0.1:6077` listener may
be stopped or removed. The rooted display `:0`, versioned Holo rollback tree,
and any other Termux session remain outside scope.

Rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Run sequence and acceptance

1. Verify the device, free space, exact R8 cleanup, no matching process, and
   rooted rollback paths. Install the pinned APK in place and record the
   installed APK hash without clearing app data.
2. Verify `com.termux` and `com.termux.x11` plus the already user-granted
   `com.termux.permission.RUN_COMMAND`. Start `run_rootless_x11=true` through
   the APK, open the Termux:X11 activity if needed for visual evidence, and
   require a fresh Termux-owned `:77` process plus loopback port `6077`.
3. Run the rootless transport probe against
   `127.0.0.1:6077`. Snapshot the app-UID `/proc/net/route` and
   `ipv6_route`; record default-route presence or absence without fabricating
   a gateway. Do not bind a route shadow unless the result is explicitly
   required by the fresh evidence.
4. Stage the same exact archive, 161 Holo files, two Debian GTK2 files, PRoot
   closure, helper assets, and public seed as R8. Use the known-good Holo
   `bsdtar` bootstrap input for extraction, then require the unchanged guest
   closure marker.
5. Run supervisor `preflight` with `DISPLAY=127.0.0.1:77`, then run the
   public seed with only:

   ```text
   /opt/nova-steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck
   ```

   Capture fresh stdout/stderr, supervisor state, Steam updater/SteamUI logs,
   and a screenshot only when it can be correlated to the R9 process and
   display. Require the first updater frame and/or a successful manifest
   handoff before classifying SteamUI startup.
6. Stop only the R9 Steam/PRoot tree and the Termux `:77` helper. Verify the
   rootless display listener, sockets, and app/remote trees are gone while the
   rooted `:0` session and rollback paths remain.

## Failure classification

- `127.0.0.1:6077` unavailable: APK-to-Termux display bridge failure.
- X11 protocol/window failure with port open: display contract failure, not
  Steam or network success.
- HTTP/DNS failure after X11 connects: rootless Android network contract
  failure; preserve route-shadow evidence and Steam updater output.
- Updater handoff succeeds but SteamUI does not frame: Steam client/UI or
  guest-runtime boundary; do not add Gamescope or patches in this run.

## Cleanup and follow-up

Commit and push the R9 result before any further variable changes. Remove only
the named R9 app/remote trees and the Termux `:77` state. Do not export or
back up authentication data. If the updater handoff passes, the next fresh
run may classify SteamUI/OOBE; if it fails at network, keep the display
server isolated and predeclare a network-only contract test.

