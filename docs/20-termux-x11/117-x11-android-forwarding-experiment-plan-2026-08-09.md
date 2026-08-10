# X11-to-Android forwarding experiment plan — 2026-08-09

Status: branch decision and open-ended X11/Termux track. The first five
experiments are an initial ladder, not a cap; no device result is claimed by
this document.

## Scope and working assumption

“X11 forwarding” here means running a Linux X11 client from the Nova ARM64
userspace and displaying it through the Android [Termux:X11](https://github.com/termux/termux-x11)
server. The first path deliberately does not use the Nova Gamescope
AHardwareBuffer receiver or Android `SurfaceControl` presentation. The current
Gamescope/AHB line remains valuable prior art and stays intact on
`feat/nova-steam-end-to-end`; this branch is a bounded escape route around its
current presentation blocker.

The user’s “Temu to ERMUX” wording is recorded as the Termux:X11 assumption.
If the device cannot run that app/package pair, the experiment is a failed
bring-up with evidence, not permission to silently substitute another display
architecture.

The expanded objective is to take this route as far as the device can support:
first a reliable X11 display, then native ARM64 Steam, then the Steam OOBE and
login flow, including the QR-code login view visibly presented on the Android
screen. Every device experiment gets a fresh identity, a durable result note,
and a commit pushed before the next experiment starts. A negative result is
useful only when it identifies the first failed boundary and leaves the device
clean.

## Branch decision

This branch starts at:

```text
base_branch=feat/nova-steam-end-to-end
base_commit=86ecf22
main_at_branch_creation=335c600
new_branch=feat/x11-android-forwarding-experiments
```

Starting from the current head is intentional. Its diff from `main` contains
both diagnostic Gamescope/AHB patches and the tested session infrastructure:

- exact-scope Nova cleanup and post-stop verification;
- fresh run identity, artifact provenance, and X11 capture guards;
- Activity-stop cancellation and quiet-scene lifecycle handling;
- native Steam launch, input, and session controls already exercised on the
  attached Nova device.

Branching directly from `main` would discard those regression safeguards and
make the first X11 result less trustworthy. The new path will not depend on
the AHB output patches: it will use separate, explicitly named scripts and
profiles, leave the existing AHB defaults untouched, and avoid changing
Gamescope source while the X11 route is being evaluated.

If the route succeeds, extract a smaller upstream-shaped implementation later:
port only the new X11/session files and the minimum lifecycle fixes onto a
fresh branch from `main`. Do not make the successful fallback depend on the
accumulated readback, cadence, frame-marker, tiling, or transport diagnostics.

## Prior art read this turn

The reference checkouts were shallow clones made on 2026-08-09:

| Project | Revision | Relevant model |
|---|---|---|
| [Termux:X11](https://github.com/termux/termux-x11) | `d8013ac5d174bb16120f915c10a7255948c59c17` | Android app plus a companion Termux package. `termux-x11 :1 -xstartup ...` starts a real X server; the app’s `SurfaceView` hands an Android `Surface` to native `libXlorie`/EGL rendering, while `ACTION_STOP` closes the Activity. The X-server process and Activity are separate lifecycle objects. |
| [Winlator](https://github.com/brunodev85/winlator) | `fb66541b93a4eb3ee585a433b4c7b20544d58e40` | Android-owned X server, renderer, container, and input-control stack. Its useful pattern is explicit environment/container start-stop and a renderer view that can be paused/resumed; it is not an external X11 forwarding protocol. |
| [GameNative](https://github.com/utkarshdalal/GameNative) | `4c3269c63851849fbe16e462733494755ce47524` | Winlator-derived Android product lifecycle. `XServerScreen` synchronizes the X server view with Activity lifecycle events, releases renderer/window listeners, watches guest process exit, and conditionally keeps services alive across backgrounding. It also contains practical GL/Vulkan/AHardwareBuffer renderer options. |

The local [Termux:X11 kit assessment](../00-start-here/02-termux-x11-kit-assessment.md) adds
the important limitation: that path targets normal ARM64 Steam desktop mode,
not Gamescope or Steam Deck Big Picture, and the kit contains claims rather
than a Nova device result. The local X11 capture helper is useful for Linux-side
diagnostics but does not prove Android-side display.

## Initial experiment ladder

These five experiments are the initial sequence. They are deliberately small
enough to isolate the display, session, lifecycle, input, and product-shape
questions. They do not limit the continuation of this track.

### 1. Termux:X11 display bring-up

Install or stage the official Termux:X11 Android app and its companion package,
start a fresh display, and run the existing synthetic X11 client from the Nova
ARM64 rootfs. No Gamescope, AHB socket, or `SurfaceControl` output is in scope.

Pass requires a non-uniform Android-side Termux:X11 capture, a fresh X display
and client/window identity, recorded app/package and helper hashes, and clean
server/client teardown. Failure must identify whether installation, server
startup, socket visibility, client connection, or Android rendering failed.

### 2. Native ARM64 Steam over direct X11

Keep the display/session setup from experiment 1 and launch the existing native
ARM64 Steam client with `DISPLAY` pointed at the Termux:X11 display. Do not
start Gamescope or the Nova AHB bridge. First establish the simplest stable
Steam desktop/Gamepad UI rendering mode; only vary CEF/GL settings if the
experiment contract names that as the one changed variable.

Pass requires a fresh Steam X11 window visible in the Android-side capture,
fresh Steam readiness evidence, and a session that survives the bounded
observation interval.

### 3. X11 session lifecycle and relaunch

Stop the X11 server and Steam tree, verify the display socket and process set
are gone, then start a new display/session and repeat the same Steam launch.
Exercise Activity foreground/background once if the app is available. This
borrows Termux:X11 and GameNative lifecycle structure without adding a custom
compositor.

Pass requires a new display/session identity after restart, no stale Steam log
or socket satisfying readiness, and clean teardown on both normal stop and
interruption.

### 4. Android input through the X11 path

With the direct-X11 Steam session held constant, validate one touchscreen and
one physical gamepad action through the Android-side X11 input path. Use the
existing Nova input evidence helpers only where they do not alter the display
transport. The first acceptance target is visible focus/navigation change, not
full login.

Pass requires event provenance, focus ownership, a before/after visual or
state difference, and a clean session stop.

### 5. Steam Gamepad UI/fullscreen fallback decision

Attempt the closest Steam Deck-like shell that the direct X11 path can support
(`-gamepadui` or the equivalent existing Steam flags), while recording network,
audio, and renderer mode. This is the decision experiment: either the X11
fallback is a credible temporary product path, or the evidence says to return
to the Gamescope/AHB line with a narrower compositor question.

Pass is not “Steam launched”; it requires visible fullscreen UI, usable input,
and documented network/audio/graphics limits. A negative result still closes
the fallback question if the preceding evidence is fresh and complete.

## Open-ended continuation toward OOBE and QR login

After the initial ladder, continue with one separately predeclared and
published experiment at a time while the route is producing new evidence. The
intended sequence is:

1. Repeat the synthetic client until the X11 window and same-run captures pass
   through the corrected private-namespace launcher.
2. Launch native ARM64 Steam over direct Termux:X11 and establish a fresh
   desktop/Gamepad UI window without Gamescope or the AHB bridge.
3. Advance the fresh Steam OOBE using the existing Android touch/controller
   evidence paths, keeping X11 capture and Android screenshot identity tied to
   the same run.
4. Reach the Steam login page and verify that the QR-code login view is
   visibly rendered on the physical Android display, not merely present in
   Steam DOM or logs.
5. Repeat the login/OOBE result across a stop/relaunch or Activity
   foreground/background cycle to establish whether it is a usable session
   architecture rather than a one-shot demo.

This continuation has no fixed run count. Stop only after the QR acceptance
passes, the route reaches a clearly documented device/runtime blocker, or the
remaining work would require changing more than one independently testable
boundary in the same experiment. Preserve the Gamescope/AHardwareBuffer line
as a separate option throughout.

## Guardrails for this branch

- Read `docs/00-start-here/34-nova-runtime-harness-lifecycle.md` immediately before every
  Nova device run.
- Run exact-scope cleanup before launch and on every exit; never reuse a prior
  X socket, process, screenshot, log tail, or readiness marker.
- Record Termux:X11 APK/package, companion package, rootfs/client artifact,
  display number/socket, renderer/input flags, and SHA-256 values.
- Keep the AHB/Gamescope patch stack frozen. No low-level compositor change is
  justified by an X11 result.
- Commit each durable experiment contract/result before starting the next one.
- Do not start the next device experiment until the current result and any
  harness repair are committed and pushed.
- Keep each follow-up one-variable and separately documented; the current
  five-step ladder is not a stopping rule.

## Immediate next step

The immediate next step is to repeat experiment 1 with the committed private
mount-namespace launcher and exact teardown helper. Verify whether the
attached Retroid Pocket Nova can map the synthetic X11 client and produce both
same-run X11 and Android captures. Do not launch Steam until that display
boundary is independently proven.
