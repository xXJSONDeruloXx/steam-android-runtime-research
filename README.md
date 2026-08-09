# Steam Android Runtime Research

Private evidence archive for building an Android app with a Linux runtime and a Steam/gamepad-first experience, rather than a Windows/Wine container as the primary product model.

Status: evidence gathered through 2026-08-08.

## Bottom line

No previous Android-app attempt has reached the actual Steam login/library on Android. The Nova lab now
reaches the pre-login Steam Gamepad UI and the live Steam DOM reaches `/login`, but Android presentation
still has an unresolved stale-frame synchronization gate; the current
ARM handheld Linux ecosystem has moved further than the earlier experiments:
Valve's ARM64 client and Steam runtime are directly reachable from live distribution endpoints, and
Armada/PockNix document complete native-ARM64 Steam + gamescope sessions on supported Snapdragon
handhelds.

The useful results are split across several projects:

- [GameNative](https://github.com/xXJSONDeruloXx/GameNative) proves the Android product plumbing: storage, downloads, Steam data, containers, input, lifecycle, and practical rendering.
- [deck-in-a-box](https://github.com/xXJSONDeruloXx/deck-in-a-box) proves that real FEX can execute x86 code inside an Android-managed Linux environment, but Steam crashes in the FEX+proot thread path.
- [steam-droid](https://github.com/xXJSONDeruloXx/steam-droid) proves Valve's ARM64 Android Steam libraries can be loaded, but the public package is not sufficient to boot the native service.
- [steam-arm-findings](https://github.com/xXJSONDeruloXx/steam-arm-findings) proves the strongest display path so far: ARM64 Linux userspace, KGSL Turnip, AHardwareBuffer exchange, SurfaceControl presentation, and a gamescope Android backend capable of presenting 600 compositor frames.
- The attached [Termux:X11 kit assessment](docs/02-termux-x11-kit-assessment.md) is a useful simpler bring-up path for normal ARM64 Steam desktop mode, but its own README explicitly excludes Gamescope and Steam Deck Big Picture.
- [Current ARM64 Steam research](docs/05-current-arm64-steam-research.md) records the live Valve endpoints, Holo's ARM64 package/rootfs channel, and the current Armada/PockNix session implementations.
- [Android/Linux/gamescope roadmap](docs/06-android-linux-gamescope-roadmap.md) turns the evidence into a rooted MVP and a staged rootless target.
- [Nova rooted bridge lab](docs/07-nova-rooted-bridge-smoke-test.md) records the first real Android-app Surface/HardwareBuffer and rooted chroot smoke test.
- [Nova Holo glibc/Vulkan probe](docs/08-nova-holo-glibc-vulkan-probe.md) records native ARM64 glibc success, the stock-Holo control failure, a working KGSL Turnip/offscreen command path, and a verified Vulkan DMA-BUF export/import handoff.
- [Nova Android AHardwareBuffer probe](docs/09-nova-android-ahardwarebuffer-handle-probe.md) records Android Vulkan import, a bidirectional Android-to-Holo DMA-BUF/GPU handoff, export-before-wait acquire-fence ordering, and a five-frame two-buffer SurfaceControl loop with release-fence backpressure.
- [Nova stock gamescope control](docs/10-nova-stock-gamescope-control.md) records the first gamescope run on the same KGSL Vulkan path: stock gamescope reaches the Adreno device, then stops because its DRM-device discovery contract is not available.
- [Nova headless gamescope seam](docs/11-nova-headless-gamescope-seam.md) records a patched ARM64 headless gamescope compositor crossing that DRM-identity boundary, compositing 298 Wayland SHM frames on the Nova, and leaving persistent Android output as the next seam.
- [Nova Gamescope Android output](docs/12-nova-gamescope-ahb-output.md) records the imported AHardwareBuffer output path from Gamescope through Android SurfaceControl, including sustained 60-frame and 960x540 acquire/release fence runs.
- [Nova Xwayland Android AHardwareBuffer output](docs/13-nova-xwayland-ahb-output.md) records an animated ARM64 X11 client crossing Xwayland, Gamescope, and the same 960x540 Android fence loop.
- [Nova native ARM64 Steam seed and startup](docs/14-nova-steam-arm64-seed-and-startup.md) records the live Valve seed/runtime, reproducible deployment, System V semaphore and loader ABI probes, and the first bounded native Steam launch.
- [Nova native Steam Gamepad UI through Android AHardwareBuffer](docs/15-nova-steam-ui-ahb-smoke.md) records the first live SteamUI WebSocket-ready Gamepad UI screen crossing the complete Nova presentation path, with software CEF rendering explicitly called out.
- [Nova Gamescope libei input seam](docs/16-nova-libei-input-smoke.md) records the first live keyboard-event round trip through Gamescope's EIS socket while native Steam and Android presentation remain active; gamepad navigation is still open.
- [Nova native Steam hardware GLX probe](docs/17-nova-steam-hardware-glx-probe.md) records the bounded negative result for the Holo `msm` path: Steam reaches neither CEF nor a hosted frame before the Nova's Mesa/SVE and GLX boundaries fire.
- [Nova rooted uinput gamepad smoke](docs/18-nova-uinput-gamepad-smoke.md) records the real Xbox evdev-to-virtual-gamepad relay while native Steam and Android presentation remain alive; Steam navigation is still the next gate.
- [Nova Android input to rooted uinput bridge](docs/19-nova-android-input-uinput-bridge.md) records Android controller enumeration and deterministic key dispatch through an abstract socket into the rooted virtual gamepad; Steam navigation is still the next gate.
- [Nova physical controller dispatch](docs/20-nova-physical-controller-dispatch.md) records a rooted evdev event delivered to Android as a controller-class `KeyEvent` and forwarded through the rooted virtual gamepad bridge; Steam consumption is still the next gate.
- [Nova virtual gamepad udev visibility](docs/21-nova-input-udev-device-visibility.md) records Holo `libudev` discovery and uid-501 access to the virtual event node; Steam's own HIDAPI acceptance is still open.
- [Nova Steam input process FD probe](docs/22-nova-steam-input-process-fd.md) records the native Steam process holding an open FD for that virtual event node while the AHardwareBuffer smoke passes; UI navigation is still open.
- [Nova controlled Steam Gamepad UI input](docs/23-nova-steam-controller-ui-input.md) combines that live FD observation with an exact physical BTN_SOUTH relay; the event reaches the virtual node, but the language-selector navigation region remains unchanged.
- [Nova D-pad semantic Steam UI input](docs/24-nova-steam-dpad-input.md) repeats the live-session comparison with BTN_DPAD_DOWN; the lower-level path still passes, but the selector remains unchanged, rejecting a narrow A-button mapping explanation.
- [Nova Android input bridge in Steam UI](docs/25-nova-android-input-steam-ui.md) records the earlier key-only negative comparison; the corrected app-side acceptance is in doc 29.
- [Nova SDL3 joystick event target-selection pitfall](docs/26-nova-sdl3-event-input.md) records why the first name-based SDL3 event result was superseded when duplicate virtual nodes were found.
- [Nova SDL3 Gamepad semantic event delivery](docs/27-nova-sdl3-gamepad-event.md) uses the exact relay-created event path and proves Valve's SDL3 Gamepad mapping receives D-pad press/release events.
- [Nova Steam Gamepad UI D-pad navigation acceptance](docs/28-nova-steam-dpad-navigation.md) proves an exact rooted `BTN_DPAD_DOWN` event changes the live Steam Gamepad UI navigation panel while native Steam owns the matching event FD and Android presentation passes.
- [Nova Android input bridge Steam UI navigation acceptance](docs/29-nova-android-input-steam-ui-navigation.md) proves the Android app dispatch/socket path changes the live Steam Gamepad UI navigation panel under a strict Steam-surface visual gate.
- [Nova Android A-button mapping and feedback-loop checkpoint](docs/30-nova-android-a-button-navigation.md) corrects the Nova ABXY semantic table, filters the virtual-device feedback loop, and proves Android `KEYCODE_BUTTON_A` reaches SDL3 as Xbox button 0 / Linux `BTN_SOUTH`; A-button UI activation remains open.
- [Nova Android touch → Gamescope libei and fullscreen presentation checkpoint](docs/31-nova-android-touch-libei-fullscreen.md) proves the app touch socket, ARM64 libei helper, Gamescope touch events, and native Steam Gamepad UI visible on the fullscreen AHardwareBuffer presentation path; hardware CEF remains open.
- [Nova live manual input diagnosis](docs/32-nova-live-manual-input-diagnosis.md) records the persistent-session workflow, Android overlay focus issue, and live D-pad/touch observations.
- [Nova Steam font coverage open question](docs/33-nova-steam-font-coverage-open-question.md) records the missing-glyph symptom without making it a blocker for the input/network loop.
- [Nova runtime harness lifecycle](docs/34-nova-runtime-harness-lifecycle.md) defines fresh run identity, exact cleanup, artifact provenance, and stale-evidence guardrails.
- [Parent session process audit](docs/35-parent-session-process-audit-2026-08-08.md) records Luna's last-two-hours audit of repeated process mistakes and the resulting harness repairs.
- [Nova bounded acceptance profile](docs/36-nova-bounded-acceptance-profile.md) defines the reproducible 1280×960 AHB/libei acceptance profile and clean-run evidence.
- [Nova network and update compatibility boundary](docs/37-nova-network-and-update-compat.md) records Android-host network reachability, the research-only updater boundary, and the OOBE restart-branch isolation.
- [Nova X11 presentation capture](docs/38-nova-x11-presentation-capture.md) adds same-run upstream window captures for separating CEF/Xwayland, Gamescope, and Android presentation failures.
- [Nova release-message stall](docs/39-nova-release-message-stall-2026-08-08.md) records the first traced AHardwareBuffer release-wait boundary.
- [Parent session process-audit follow-up](docs/40-parent-session-process-audit-followup-2026-08-08.md) records the next Luna audit and process repairs.
- [Nova harness provenance/reset fixes](docs/41-nova-harness-provenance-reset-fixes-2026-08-08.md) records the linked-worktree and remote-shell cleanup hardening.
- [Nova AHB trace stall](docs/42-nova-ahb-trace-stall-2026-08-08.md) records the fresh frame-level timezone-to-network reproducer.
- [Parent session process-audit follow-up 2](docs/43-parent-session-process-audit-followup-2026-08-08.md) records the latest two-hours Luna audit and remaining workflow risks.
- [Nova AHB seqpacket experiment](docs/44-nova-ahb-seqpacket-experiment-2026-08-08.md) defines the one-variable transport hypothesis and acceptance gate.
- [Nova AHB seqpacket result](docs/45-nova-ahb-seqpacket-result-2026-08-08.md) records the negative device result and the next socket-instrumentation gate.
- [Parent session process-audit follow-up 3](docs/46-parent-session-process-audit-followup-2026-08-08.md) records Luna's newest two-hour audit and the remaining preflight/capture/phase risks.
- [Nova AHB socket-trace experiment](docs/47-nova-ahb-socket-trace-experiment-2026-08-08.md) predeclares syscall, ancillary-FD, inode, and poll evidence for the original stream baseline.
- [Nova mandatory preflight manifest](docs/48-nova-preflight-manifest-2026-08-08.md) records and enforces the cleanup, reset, run-identity, and provenance gate repaired after the latest Luna audit.
- [Nova AHB socket-trace result](docs/49-nova-ahb-socket-trace-result-2026-08-08.md) records the stream baseline's valid message/FD exchange and the frame-432 Android receive/release boundary.
- [Parent session process-audit follow-up 4](docs/50-parent-session-process-audit-followup-2026-08-08.md) records Luna's latest two-hour audit and the remaining capture, timeout, focus, and phase-serialization risks.
- [Nova Android receive-wait experiment](docs/51-nova-ahb-app-receive-wait-experiment-2026-08-08.md) predeclares the next diagnostic-only app-side ACK wait boundary.

## Recommended direction

Use a layered strategy:

1. Reuse GameNative's Android-side lifecycle, storage, download, controller, and session-management patterns.
2. Use Armada/PockNix as the current reference for the Steam Deck-like session: native ARM64 Steam, gamescope, Xwayland, input, audio, Proton, and FEX for x86 games.
3. Use Holo's aarch64 Arch package channel for compatible glibc/graphics/gamescope dependencies, while fetching the native Steam client from Valve's client/runtime channels.
4. Prove the first Android product path with root: app-owned Linux userspace plus the existing AHardwareBuffer/SurfaceControl gamescope direction from `steam-arm-findings`.
5. Keep the Termux:X11 kit as a desktop-mode diagnostic/fallback path, and keep FEX as the game-compatibility layer—not the native Steam-client runtime.
6. Remove root only after the session, graphics, input, and lifecycle contracts are independently passing.

The first meaningful acceptance test is: native ARM64 Steam reaches its login or Gamepad UI screen,
with hardware `steamwebhelper` rendering and controller input, on one known Snapdragon/Adreno device.
The first Android-app acceptance test adds: the Android app starts/stops that Linux session and presents
the gamescope frames on its own surface.

## Documents

- [Prior work evidence](docs/01-prior-work-evidence.md)
- [Termux:X11 kit assessment](docs/02-termux-x11-kit-assessment.md)
- [Architecture decision matrix](docs/03-decision-matrix.md)
- [Open questions and next experiments](docs/04-open-questions.md)
- [Current ARM64 Steam research](docs/05-current-arm64-steam-research.md)
- [Android/Linux/gamescope roadmap](docs/06-android-linux-gamescope-roadmap.md)
- [Nova rooted bridge smoke test](docs/07-nova-rooted-bridge-smoke-test.md)
- [Nova Holo glibc and Vulkan probe](docs/08-nova-holo-glibc-vulkan-probe.md)
- [Nova Android AHardwareBuffer handle probe](docs/09-nova-android-ahardwarebuffer-handle-probe.md)
- [Nova stock gamescope control](docs/10-nova-stock-gamescope-control.md)
- [Nova headless gamescope seam](docs/11-nova-headless-gamescope-seam.md)
- [Nova Gamescope Android AHardwareBuffer output](docs/12-nova-gamescope-ahb-output.md)
- [Nova Xwayland Android AHardwareBuffer output](docs/13-nova-xwayland-ahb-output.md)
- [Nova native ARM64 Steam seed and startup](docs/14-nova-steam-arm64-seed-and-startup.md)
- [Nova native Steam Gamepad UI through Android AHardwareBuffer](docs/15-nova-steam-ui-ahb-smoke.md)
- [Nova Gamescope libei input seam](docs/16-nova-libei-input-smoke.md)
- [Nova native Steam hardware GLX probe](docs/17-nova-steam-hardware-glx-probe.md)
- [Nova rooted uinput gamepad smoke](docs/18-nova-uinput-gamepad-smoke.md)
- [Nova Android input to rooted uinput bridge](docs/19-nova-android-input-uinput-bridge.md)
- [Nova physical controller dispatch](docs/20-nova-physical-controller-dispatch.md)
- [Nova virtual gamepad udev visibility](docs/21-nova-input-udev-device-visibility.md)
- [Nova Steam input process FD probe](docs/22-nova-steam-input-process-fd.md)
- [Nova controlled Steam Gamepad UI input](docs/23-nova-steam-controller-ui-input.md)
- [Nova D-pad semantic Steam UI input](docs/24-nova-steam-dpad-input.md)
- [Nova Android input bridge in Steam UI](docs/25-nova-android-input-steam-ui.md)
- [Nova SDL3 joystick event target-selection pitfall](docs/26-nova-sdl3-event-input.md)
- [Nova SDL3 Gamepad semantic event delivery](docs/27-nova-sdl3-gamepad-event.md)
- [Nova Steam Gamepad UI D-pad navigation acceptance](docs/28-nova-steam-dpad-navigation.md)
- [Nova Android input bridge Steam UI navigation acceptance](docs/29-nova-android-input-steam-ui-navigation.md)
- [Nova Android A-button mapping and feedback-loop checkpoint](docs/30-nova-android-a-button-navigation.md)
- [Nova Android touch → Gamescope libei and fullscreen presentation checkpoint](docs/31-nova-android-touch-libei-fullscreen.md)
- [Nova live manual input diagnosis](docs/32-nova-live-manual-input-diagnosis.md)
- [Nova Steam font coverage open question](docs/33-nova-steam-font-coverage-open-question.md)
- [Nova runtime harness lifecycle](docs/34-nova-runtime-harness-lifecycle.md)
- [Parent session process audit](docs/35-parent-session-process-audit-2026-08-08.md)
- [Nova bounded acceptance profile](docs/36-nova-bounded-acceptance-profile.md)
- [Nova network and update compatibility boundary](docs/37-nova-network-and-update-compat.md)
- [Nova X11 presentation capture](docs/38-nova-x11-presentation-capture.md)
- [Nova release-message stall](docs/39-nova-release-message-stall-2026-08-08.md)
- [Parent session process-audit follow-up](docs/40-parent-session-process-audit-followup-2026-08-08.md)
- [Nova harness provenance/reset fixes](docs/41-nova-harness-provenance-reset-fixes-2026-08-08.md)
- [Nova AHB trace stall](docs/42-nova-ahb-trace-stall-2026-08-08.md)
- [Parent session process-audit follow-up 2](docs/43-parent-session-process-audit-followup-2026-08-08.md)
- [Nova AHB seqpacket experiment](docs/44-nova-ahb-seqpacket-experiment-2026-08-08.md)
- [Nova AHB seqpacket result](docs/45-nova-ahb-seqpacket-result-2026-08-08.md)
- [Parent session process-audit follow-up 3](docs/46-parent-session-process-audit-followup-2026-08-08.md)
- [Nova AHB socket-trace experiment](docs/47-nova-ahb-socket-trace-experiment-2026-08-08.md)
- [Nova mandatory preflight manifest](docs/48-nova-preflight-manifest-2026-08-08.md)
- [Nova AHB socket-trace result](docs/49-nova-ahb-socket-trace-result-2026-08-08.md)
- [Parent session process-audit follow-up 4](docs/50-parent-session-process-audit-followup-2026-08-08.md)
- [Nova Android receive-wait experiment](docs/51-nova-ahb-app-receive-wait-experiment-2026-08-08.md)
- [Nova Android receive-wait result](docs/52-nova-ahb-app-receive-wait-result-2026-08-09.md)
- [Retroid Pocket Nova flashing kit](tools/retroid-pocket-nova/README.md)

## Evidence standard

“Proven” means the repository contains concrete on-device output, test artifacts, or a documented build/run result. “Partial” means a lower-level prerequisite works but the target milestone does not. “Claimed/untested” means the artifact describes a path but does not include enough device evidence to verify it independently.

## Scope note

This archive records technical evidence, not a redistribution of Valve runtime binaries. The attached ZIP was inspected but is not copied into this repository. Its SHA-256 and original workspace path are recorded in the kit assessment.
