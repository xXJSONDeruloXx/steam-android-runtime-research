# Steam Android Runtime Research

Evidence archive for building an Android app with a Linux runtime and a
Steam/gamepad-first experience, rather than making Windows/Wine the primary
product model.

Status: evidence and harness documentation current through 2026-08-09.

## Current state

The rooted Retroid Pocket Nova lab can launch native ARM64 Steam through the
Holo rootfs, reach SteamUI readiness, and present the pre-login Gamepad UI on
the Android AHardwareBuffer path. Android key-event and touch-to-libei input
seams also reach the live session. CEF is still software-rendered; account
login, hardware CEF, game launch, audio, and clean long-lived lifecycle remain
open gates.

The current presentation blocker is narrower than “Gamescope does not work.”
Gamescope composition and the Android buffer handoff work in bounded runs, but
the three-buffer ACK/release path can stop at a frame-level boundary. The
[AHB transport summary](docs/nova-ahb-transport-investigation-summary.md)
contains the current causal state and experiment order. The next scheduler
trace is predeclared in [doc 72](docs/72-nova-gamescope-present-cadence-experiment-2026-08-09.md).

## Decisions and operating documents

- [Decision matrix](docs/03-decision-matrix.md) — current direction and alternatives.
- [Open questions](docs/04-open-questions.md) — living technical gates.
- [Android/Linux/Gamescope roadmap](docs/06-android-linux-gamescope-roadmap.md) — staged product plan.
- [Nova lab quickstart](android/nova-lab/README.md) — build, deploy, profile, and artifact workflow.
- [Runtime lifecycle contract](docs/34-nova-runtime-harness-lifecycle.md) — mandatory cleanup and provenance rules.
- [Bounded acceptance profile](docs/36-nova-bounded-acceptance-profile.md) — reproducible 1280×960 profile.
- [Network/update boundary](docs/37-nova-network-and-update-compat.md) — Android-host network contract.
- [X11 presentation capture](docs/38-nova-x11-presentation-capture.md) — source-vs-Android capture rules.
- [Parent-session audit summary](docs/parent-session-process-audit-summary.md) — condensed process and evidence controls.
- [Full document index](docs/README.md) — chronological and topical links to every numbered record.
- [Retroid Pocket Nova flashing kit](tools/retroid-pocket-nova/README.md) — device preparation and flashing notes.

## Milestones that matter now

- [Native ARM64 Steam seed and startup](docs/14-nova-steam-arm64-seed-and-startup.md) — loader, runtime, and bootstrap boundaries.
- [SteamUI AHardwareBuffer smoke](docs/15-nova-steam-ui-ahb-smoke.md) — pre-login Gamepad UI crossing the complete path.
- [D-pad navigation acceptance](docs/28-nova-steam-dpad-navigation.md) and [Android bridge acceptance](docs/29-nova-android-input-steam-ui-navigation.md) — live controller navigation.
- [Touch/libei/fullscreen checkpoint](docs/31-nova-android-touch-libei-fullscreen.md) — Android touch dispatch and fullscreen presentation.
- [Latest clock-correlated transport result](docs/70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md) — current frame-149 boundary.
- [Continuous-repaint hypothesis](docs/71-nova-ahb-continuous-repaint-fix-2026-08-09.md) — cross-compiled source change awaiting device verification.

Historical records are retained as dated evidence, including earlier control
experiments whose conclusions were later superseded. The index labels those
series so a historical snapshot is not mistaken for current status.

## Acceptance gates

The Android-managed runtime is not complete until one fresh, provenance-bound
run demonstrates:

1. native ARM64 Steam login or authenticated Gamepad UI;
2. hardware `steamwebhelper` rendering;
3. trusted, correctly ordered Android presentation without unexplained stalls;
4. Android controller/touch navigation and a launched game;
5. audio, suspend/resume, clean stop, and no residual processes or sockets.

## Research references

- [GameNative](https://github.com/xXJSONDeruloXx/GameNative) supplies Android lifecycle, storage, download, Steam-data, input, and rendering patterns.
- [deck-in-a-box](https://github.com/xXJSONDeruloXx/deck-in-a-box) demonstrates FEX inside an Android-managed Linux environment, with Steam still blocked by its FEX/proot thread path.
- [steam-droid](https://github.com/xXJSONDeruloXx/steam-droid) provides Valve ARM64 Android-library evidence but not a complete native-service boot.
- [steam-arm-findings](https://github.com/xXJSONDeruloXx/steam-arm-findings) provides the earlier Android AHardwareBuffer, SurfaceControl, and Gamescope direction.
- [Armada](https://github.com/armada-os/armada) and [PockNix](https://github.com/shuuri-labs/pocknix-os) remain the strongest full-Linux native ARM64 Steam/session references.

Generated rootfs, APK, binary, capture, and device-run artifacts belong under
ignored build/run directories and must not be treated as repository evidence
unless their run identity and hashes are recorded in a document.
