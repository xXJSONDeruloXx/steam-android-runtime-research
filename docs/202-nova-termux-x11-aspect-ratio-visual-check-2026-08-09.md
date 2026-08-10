# Nova Termux:X11 aspect-ratio visual check — 2026-08-09

Status: source-to-surface stretch passed; formal unobscured Android screenshot
acceptance is partial because the Nova USB chooser remained above the frame.

## Question

The Nova Android surface is `1280x960` (4:3), but the direct Steam/X11
profile consistently creates a `1280x800` Steam Big Picture child (16:10),
leaving a black lower band in the Android capture. A previous temporary
Termux:X11 `1280x800`/stretch run reached the Android lock screen, so it did
not establish whether an awake Steam frame is stretched, letterboxed, or
cropped.

This bounded run asks whether Termux:X11's supported custom resolution and
stretch mode can make the live Steam frame fill the Nova surface. It is a
display-only experiment: no physical or synthetic input will be sampled or
sent, and the audio bridge remains disabled so the result is not coupled to
the completed audio transport work.

## Predeclared run

Run ID: `display-20260810T003214Z-x11-stretch-1280x800-awake-v2`

The selected profile is:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- APK `com.xjsonderulo.steamandroid.novalab`, `LauncherActivity` with the
  newly explicit `run_steam_session=true` auto-start extra;
- direct Termux:X11, display `:0`, software Steam/CEF (`HARDWARE_ACCEL=0`);
- Steam flags `-fullscreen -fulldesktopres`;
- audio bridge disabled;
- temporary Termux:X11 preferences: `displayResolutionMode=custom`,
  `displayResolutionCustom=1280x800`, `displayResolutionExact=1280x800`,
  `displayStretch=true`, `fullscreen=true`;
- no button, touch, keyboard, pointer, controller, or game-launch action.

The explicit normal-session extra is launcher plumbing, not a geometry
variable: without it, an automated run would need to tap the product
launcher. The audio bridge extra is deliberately not set.

Source commit: `4c36ee1`; APK SHA-256:
`0ff3b753b113e0a5c9ecadd7b1f88a66113b1891ec7e698fbe5eaa1950fa18f8`.

## Setup-invalid attempt — `display-20260810T002424Z-x11-stretch-1280x800-awake`

The first launch used the same APK and temporary XML values, but the restored
preference file was accidentally assigned the launcher app's UID `10121`
instead of Termux:X11's UID `10120`. Termux:X11 logged:

```text
SharedPreferencesImpl: Attempt to read preferences file
/data/user/0/com.termux.x11/shared_prefs/com.termux.x11_preferences.xml without permission
```

Because the app could not read the test preferences, this run is not geometry
evidence. No screenshot was accepted. The host-captured original preference
hash was `25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895`,
the temporary file hash was
`0989cb3336c9bf61b06213a01176a81c206b8b80458358be81527c5df20fef50`, and the
restored target matched the original hash byte-for-byte with owner `10120`,
group `10120`, and mode `660`.

The first root-side stop invocation also omitted the app asset-directory
argument and reported `nova_launcher_cleanup=missing_helper`. The exact X11
cleanup helper was rerun directly and returned `nova_x11_cleanup=pass`; the
exact runtime cleanup then returned `nova_runtime_cleanup=pass`, with no Nova
process, X11 socket, or run-scoped stage remaining. This is an invocation
failure recorded for correction, not a display result.

## Corrected device result — `display-20260810T003214Z-x11-stretch-1280x800-awake-v2`

The corrected run used the same APK after the ownership repair. Termux:X11
read the temporary file successfully; there was no preference permission
warning. The original and restored preference hash was
`25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895`, and the
temporary profile hash was
`0989cb3336c9bf61b06213a01176a81c206b8b80458358be81527c5df20fef50`. The
restored file ended with owner `10120`, group `10120`, and mode `660`.

The run stayed on the normal direct software path:

```text
source_commit=4c36ee1
apk_sha256=0ff3b753b113e0a5c9ecadd7b1f88a66113b1891ec7e698fbe5eaa1950fa18f8
audio_bridge=0
hardware_accel=0
steam_flags=-fullscreen -fulldesktopres
input=not sampled or sent
```

The fresh Android/Termux evidence was:

```text
SurfaceChangedListener: Surface was changed: 1280x960
tx11-request: window changed: 1280 800 builtin
LorieNative: Sent shared buffer width 1280 stride 1280 height 800
LorieNative: Received shared buffer width 1280 stride 1280 height 800
```

The X11 tree and both captures remained stable. The root was `1280x800`, and
the mapped Steam Big Picture window was `0x2400035`, also `1280x800`:

```text
nova_x11_tree=pass root=0x511
nova_x11_window id=0x2400035 parent=0x511 depth=1 map_state=viewable
  x=0 y=0 width=1280 height=800 name="Steam Big Picture Mode"
nova_x11_capture=pass id=0x2400035 width=1280 height=800
```

The X11 source frame was a fresh signed-in Steam home screen. Current-run
Steam markers reached `Started webhelper process 10221` at `00:33:53`,
`CreateMainWindow` at `00:34:08`, and the signed-in initialization sequence
through `00:34:09`. The baseline and settled X11 tree hashes were both
`363bb7b81d01195c0bcaa6b1300943264bd434c1190950d0c8eb40934ce4a41c`; the
settled X11 PPM hash was
`62725ee44a0bc5341578f5d9fdcf59aaa2c25a7b93bc9c6d989b998ef441426f`.

### Android-surface visual boundary

The first Android capture was the lock screen. `wm dismiss-keyguard` exposed
the Steam frame without sending input, but the Nova firmware immediately
presented its persistent `com.rp.settings` `Use USB for` chooser above Steam.
`am force-stop`, `CLOSE_SYSTEM_DIALOGS`, and a temporary exact-package disable
did not remove the already-created system-UID overlay. The package was
re-enabled before teardown. No Back, tap, key, pointer, or controller event
was sent, so the unobscured Android screenshot gate is correctly recorded as
partial rather than silently accepted.

Even with the chooser dimming the background, the visible side bands provide
a strong geometry correlation against the same-run X11 PPM. Comparing the
settled Android capture against the X11 source gave:

```text
edge_luminance_correlation_stretch=0.976013
edge_luminance_correlation_letterbox=0.288230
bottom_edge_correlation_stretch=0.988303
bottom_edge_correlation_letterbox=0.000000
```

The bottom `y=800..879` edge contains non-black Steam content in the Android
capture, where a letterboxed model predicts black. This is evidence that
Termux:X11 `displayStretch=true` scales the live `1280x800` Steam frame into
the full `1280x960` Android surface and removes the prior lower black band.
It is a source-to-surface geometry pass, not a claim that the USB chooser has
been solved.

### Cleanup

The exact run cleanup returned:

```text
nova_x11_cleanup=pass
nova_runtime_cleanup=pass
```

The preference file was restored byte-for-byte, the package was re-enabled,
the launcher state directory and X11 socket directory were empty, and no
matching Nova process remained after the final audit. Pre-existing historical
PPMs in the device capture directory were left untouched; this run's helper,
PPMs, relay stage, preference backup, and launcher state were removed.

The `1280x800` custom buffer plus `displayStretch=true` hypothesis therefore
passes at the Termux:X11-to-Android presentation layer. The remaining product
issue is not Steam's window geometry; it is making the profile automatic and
dealing with the Nova USB overlay without relying on operator input. The next
non-button phase can move to another subsystem, with geometry kept as a
productization task rather than reopening Gamescope/AHardwareBuffer.

Before changing preferences, the run pulled and hashed the exact
`com.termux.x11_preferences.xml` file. After the captures, it restored
that file byte-for-byte, force-stopped Termux:X11, ran the exact Nova runtime
and X11 cleanup helpers, and verified that no process, socket, relay, preload,
bridge log, or temporary state from this run remains.

## Evidence collected

The run recorded:

1. the APK and relevant launcher/source hashes;
2. the original and temporary Termux:X11 preference hashes and selected keys;
3. fresh launcher, Steam, webhelper, and Termux:X11 logs;
4. an Android `1280x960` screenshot while Steam is awake and settled;
5. an X11 window tree and fresh PPM captures for the X11 root and Steam child;
6. exact post-run cleanup output and a residual-process/socket audit.

The Android screenshot is the acceptance surface. X11 geometry is supporting
evidence and must not be treated as a visual pass by itself.

## Decision

The source-to-surface geometry result passes. The Android screenshot is a
partial formal acceptance because the firmware overlay remained visible, but
the same-run edge correlation and non-black bottom strip establish the
stretch-versus-letterbox decision without input. The next change should
productize the temporary preference profile or move to another subsystem; it
should not reopen the Steam window-size or Gamescope/AHardwareBuffer paths for
this geometry question.

## Cleanup contract

This run follows [34](34-nova-runtime-harness-lifecycle.md). The exact-scope
cleanup helper runs before launch and on exit. Temporary preference changes are
restored even when the launcher is stopped, and the result will be committed
and pushed before another long device experiment begins.
