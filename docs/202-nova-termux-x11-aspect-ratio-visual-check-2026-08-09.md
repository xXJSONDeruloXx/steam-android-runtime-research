# Nova Termux:X11 aspect-ratio visual check — 2026-08-09

Status: predeclared; device result pending.

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

Run ID: `display-20260810T00xxxxZ-x11-stretch-1280x800-awake`

The final UTC timestamp will replace `00xxxx` in the result section after the
device run begins. The selected profile is:

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
