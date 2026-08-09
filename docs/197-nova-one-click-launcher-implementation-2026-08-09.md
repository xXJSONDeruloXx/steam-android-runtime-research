# Nova one-click launcher implementation — 2026-08-09

Status: implementation built locally; device launch is intentionally deferred
while the signed-in Steam download session remains active. This record covers
the packaging change, not a device acceptance result.

## Branch and build

```text
branch=feat/nova-one-click-launcher
base=feat/termux-x11-networking-followup
apk=android/nova-lab/build/nova-lab-debug.apk
apk_sha256=fb479740311b59d740c526f371299004f06778b741001645614cd0c9632ffd1f
package=com.xjsonderulo.steamandroid.novalab
version_code=2
version_name=0.2
min_sdk=29
target_sdk=35
```

The APK was verified with `aapt2 dump badging`, `aapt2 dump xmltree`, and the
existing `apksigner verify` step in `android/nova-lab/build.sh`. It contains
the launcher activity, a special-use foreground service, the exact X11/Steam
client and cleanup scripts, `nova-mount-private`, and the ARM64 glibc uinput
relay.

## What changed

`LauncherActivity` is now the APK's default entry point. It reports the
Termux:X11 dependency and fixed rootfs location, starts or stops the product
session, and keeps the diagnostic `MainActivity` behind an explicit button.
`LauncherService` owns the long-lived `su` process and foreground notification
so switching to Termux:X11 does not make the launch process depend on adb.

`nova-one-click-root-launcher.sh` owns the device-side sequence:

```text
APK button
  -> foreground service
  -> exact preflight (refuse an unrelated live Nova session)
  -> uinput relay from /dev/input/event7
  -> Termux:X11 CmdEntryPoint on :0
  -> Termux:X11 Activity
  -> UID-501 Steam client with both D-Bus buses
```

The Stop action uses the run state directory and the existing X11/runtime
cleanup helpers. It does not use a broad process-name kill. The launcher also
passes `-fullscreen` and `-fulldesktopres` as an explicit 4:3 geometry
hypothesis; a fresh device run must verify `x11-tree` and the Android frame.

## Deliberate limits

- The APK does not redistribute the Valve Steam client or the Holo rootfs. It
  packages orchestration and small helper artifacts; the runtime remains
  device-installed data.
- The gamepad relay is started before Steam so Steam can discover the virtual
  Xbox device during client initialization. Button-by-button Steam acceptance
  is still untested on this direct X11 product profile.
- Android network transport is already working. The Steam network page is not
  a product blocker for downloads and is not changed by this implementation.
- Audio is still open. The current rootfs has no standalone audio server
  endpoint proven against Android AudioFlinger, so the launcher does not claim
  sound output.
- No device install or launch was performed for this record; the current
  signed-in/download session remains untouched.

## Next device acceptance run

After the current manual session is explicitly stopped and cleaned, install
this APK without changing the Termux:X11 APK or rootfs, tap Start Steam, and
capture one fresh run directory containing:

1. launcher/service logs and the exact APK/helper hashes;
2. relay readiness plus Steam's open virtual-event FD;
3. X11 geometry and an Android screenshot at 1280x960;
4. face-button, bumper, stick, trigger, and D-pad events; and
5. audio process/device diagnostics, without calling audio success until a
   real audible or loopback acceptance is available.
