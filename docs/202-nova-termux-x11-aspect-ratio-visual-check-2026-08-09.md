# Nova Termux:X11 aspect-ratio visual check — 2026-08-09

Status: one setup-invalid attempt recorded; corrected retry predeclared and
device result pending.

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

Before changing preferences, the run will pull and hash the exact
`com.termux.x11_preferences.xml` file. After the captures, it will restore
that file byte-for-byte, force-stop Termux:X11, run the exact Nova runtime and
X11 cleanup helpers, and verify that no process, socket, relay, preload,
bridge log, or temporary state from this run remains.

## Evidence to capture

The run will record:

1. the APK and relevant launcher/source hashes;
2. the original and temporary Termux:X11 preference hashes and selected keys;
3. fresh launcher, Steam, webhelper, and Termux:X11 logs;
4. an Android `1280x960` screenshot while Steam is awake and settled;
5. an X11 window tree and fresh PPM captures for the X11 root and Steam child;
6. exact post-run cleanup output and a residual-process/socket audit.

The Android screenshot is the acceptance surface. X11 geometry is supporting
evidence and must not be treated as a visual pass by itself.

## Decision boundary

The experiment passes only if the awake Android screenshot shows the current
Steam frame occupying the intended Nova surface without an unexplained black
band or crop, and the screenshot's frame identity agrees with fresh Steam/X11
state from this run. A `1280x800` X11 root alone is a partial result.

If the screenshot remains `1280x960` with a black band, or if the device locks
or the screenshot cannot be correlated to the current Steam frame, this is a
negative/partial result. The next change will be made in the Steam window or
Android presentation layer, not by modifying controller handling.

## Cleanup contract

This run follows [34](34-nova-runtime-harness-lifecycle.md). The exact-scope
cleanup helper runs before launch and on exit. Temporary preference changes are
restored even when the launcher is stopped, and the result will be committed
and pushed before another long device experiment begins.
