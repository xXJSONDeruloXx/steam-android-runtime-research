# Steam Android Runtime Research

Private evidence archive for building an Android app with a Linux runtime and a Steam/gamepad-first experience, rather than a Windows/Wine container as the primary product model.

Status: evidence gathered through 2026-08-09.

## Bottom line

No previous Android-app attempt has reached the actual Steam login/library on Android. The Nova lab now
reaches the pre-login Steam Gamepad UI and the live Steam DOM reaches `/login`. The latest device run
resolved the timeout-driven quiet-scene failure in the continuous Android AHardwareBuffer receiver:
Android and X11 remained usable through a quiet Steam scene and reached the same timezone page, but
login and frame-identity correlation are still unaccepted gates. The latest
manual lifecycle run also proves that Activity stop cancels a blocking AHB ACK
wait without waiting for the 15-second timeout. The current
ARM handheld Linux ecosystem has moved further than the earlier experiments:
Valve's ARM64 client and Steam runtime are directly reachable from live distribution endpoints, and
Armada/PockNix document complete native-ARM64 Steam + gamescope sessions on supported Snapdragon
handhelds.

The useful results are split across several projects:

- [GameNative](https://github.com/xXJSONDeruloXx/GameNative) proves the Android product plumbing: storage, downloads, Steam data, containers, input, lifecycle, and practical rendering.
- [deck-in-a-box](https://github.com/xXJSONDeruloXx/deck-in-a-box) proves that real FEX can execute x86 code inside an Android-managed Linux environment, but Steam crashes in the FEX+proot thread path.
- [steam-droid](https://github.com/xXJSONDeruloXx/steam-droid) proves Valve's ARM64 Android Steam libraries can be loaded, but the public package is not sufficient to boot the native service.
- [steam-arm-findings](https://github.com/xXJSONDeruloXx/steam-arm-findings) proves the strongest display path so far: ARM64 Linux userspace, KGSL Turnip, AHardwareBuffer exchange, SurfaceControl presentation, and a gamescope Android backend capable of presenting 600 compositor frames.
- The attached [Termux:X11 kit assessment](docs/00-start-here/02-termux-x11-kit-assessment.md) is a useful simpler bring-up path for normal ARM64 Steam desktop mode, but its own README explicitly excludes Gamescope and Steam Deck Big Picture.
- The open [Termux:X11-to-Android forwarding track](docs/20-termux-x11/117-x11-android-forwarding-experiment-plan-2026-08-09.md) is now being taken past the initial display/lifecycle ladder toward native Steam OOBE, login, and a QR-code view visibly rendered on the Android screen; its first [partial display result](docs/20-termux-x11/119-termux-x11-display-bring-up-result-2026-08-09.md) has not yet reached a mapped synthetic window.
- [Current ARM64 Steam research](docs/00-start-here/05-current-arm64-steam-research.md) records the live Valve endpoints, Holo's ARM64 package/rootfs channel, and the current Armada/PockNix session implementations.
- [Android/Linux/gamescope roadmap](docs/00-start-here/06-android-linux-gamescope-roadmap.md) turns the evidence into a rooted MVP and a staged rootless target.
- [Nova rooted bridge lab](docs/10-ahb-and-harness/07-nova-rooted-bridge-smoke-test.md) records the first real Android-app Surface/HardwareBuffer and rooted chroot smoke test.
- [Nova Holo glibc/Vulkan probe](docs/10-ahb-and-harness/08-nova-holo-glibc-vulkan-probe.md) records native ARM64 glibc success, the stock-Holo control failure, a working KGSL Turnip/offscreen command path, and a verified Vulkan DMA-BUF export/import handoff.
- [Nova Android AHardwareBuffer probe](docs/10-ahb-and-harness/09-nova-android-ahardwarebuffer-handle-probe.md) records Android Vulkan import, a bidirectional Android-to-Holo DMA-BUF/GPU handoff, export-before-wait acquire-fence ordering, and a five-frame two-buffer SurfaceControl loop with release-fence backpressure.
- [Nova stock gamescope control](docs/10-ahb-and-harness/10-nova-stock-gamescope-control.md) records the first gamescope run on the same KGSL Vulkan path: stock gamescope reaches the Adreno device, then stops because its DRM-device discovery contract is not available.
- [Nova headless gamescope seam](docs/10-ahb-and-harness/11-nova-headless-gamescope-seam.md) records a patched ARM64 headless gamescope compositor crossing that DRM-identity boundary, compositing 298 Wayland SHM frames on the Nova, and leaving persistent Android output as the next seam.
- [Nova Gamescope Android output](docs/10-ahb-and-harness/12-nova-gamescope-ahb-output.md) records the imported AHardwareBuffer output path from Gamescope through Android SurfaceControl, including sustained 60-frame and 960x540 acquire/release fence runs.
- [Nova Xwayland Android AHardwareBuffer output](docs/10-ahb-and-harness/13-nova-xwayland-ahb-output.md) records an animated ARM64 X11 client crossing Xwayland, Gamescope, and the same 960x540 Android fence loop.
- [Nova native ARM64 Steam seed and startup](docs/10-ahb-and-harness/14-nova-steam-arm64-seed-and-startup.md) records the live Valve seed/runtime, reproducible deployment, System V semaphore and loader ABI probes, and the first bounded native Steam launch.
- [Nova native Steam Gamepad UI through Android AHardwareBuffer](docs/10-ahb-and-harness/15-nova-steam-ui-ahb-smoke.md) records the first live SteamUI WebSocket-ready Gamepad UI screen crossing the complete Nova presentation path, with software CEF rendering explicitly called out.
- [Nova Gamescope libei input seam](docs/10-ahb-and-harness/16-nova-libei-input-smoke.md) records the first live keyboard-event round trip through Gamescope's EIS socket while native Steam and Android presentation remain active; gamepad navigation is still open.
- [Nova native Steam hardware GLX probe](docs/10-ahb-and-harness/17-nova-steam-hardware-glx-probe.md) records the bounded negative result for the Holo `msm` path: Steam reaches neither CEF nor a hosted frame before the Nova's Mesa/SVE and GLX boundaries fire.
- [Nova rooted uinput gamepad smoke](docs/10-ahb-and-harness/18-nova-uinput-gamepad-smoke.md) records the real Xbox evdev-to-virtual-gamepad relay while native Steam and Android presentation remain alive; Steam navigation is still the next gate.
- [Nova Android input to rooted uinput bridge](docs/10-ahb-and-harness/19-nova-android-input-uinput-bridge.md) records Android controller enumeration and deterministic key dispatch through an abstract socket into the rooted virtual gamepad; Steam navigation is still the next gate.
- [Nova physical controller dispatch](docs/10-ahb-and-harness/20-nova-physical-controller-dispatch.md) records a rooted evdev event delivered to Android as a controller-class `KeyEvent` and forwarded through the rooted virtual gamepad bridge; Steam consumption is still the next gate.
- [Nova virtual gamepad udev visibility](docs/10-ahb-and-harness/21-nova-input-udev-device-visibility.md) records Holo `libudev` discovery and uid-501 access to the virtual event node; Steam's own HIDAPI acceptance is still open.
- [Nova Steam input process FD probe](docs/10-ahb-and-harness/22-nova-steam-input-process-fd.md) records the native Steam process holding an open FD for that virtual event node while the AHardwareBuffer smoke passes; UI navigation is still open.
- [Nova controlled Steam Gamepad UI input](docs/10-ahb-and-harness/23-nova-steam-controller-ui-input.md) combines that live FD observation with an exact physical BTN_SOUTH relay; the event reaches the virtual node, but the language-selector navigation region remains unchanged.
- [Nova D-pad semantic Steam UI input](docs/10-ahb-and-harness/24-nova-steam-dpad-input.md) repeats the live-session comparison with BTN_DPAD_DOWN; the lower-level path still passes, but the selector remains unchanged, rejecting a narrow A-button mapping explanation.
- [Nova Android input bridge in Steam UI](docs/10-ahb-and-harness/25-nova-android-input-steam-ui.md) records the earlier key-only negative comparison; the corrected app-side acceptance is in doc 29.
- [Nova SDL3 joystick event target-selection pitfall](docs/10-ahb-and-harness/26-nova-sdl3-event-input.md) records why the first name-based SDL3 event result was superseded when duplicate virtual nodes were found.
- [Nova SDL3 Gamepad semantic event delivery](docs/10-ahb-and-harness/27-nova-sdl3-gamepad-event.md) uses the exact relay-created event path and proves Valve's SDL3 Gamepad mapping receives D-pad press/release events.
- [Nova Steam Gamepad UI D-pad navigation acceptance](docs/10-ahb-and-harness/28-nova-steam-dpad-navigation.md) proves an exact rooted `BTN_DPAD_DOWN` event changes the live Steam Gamepad UI navigation panel while native Steam owns the matching event FD and Android presentation passes.
- [Nova Android input bridge Steam UI navigation acceptance](docs/10-ahb-and-harness/29-nova-android-input-steam-ui-navigation.md) proves the Android app dispatch/socket path changes the live Steam Gamepad UI navigation panel under a strict Steam-surface visual gate.
- [Nova Android A-button mapping and feedback-loop checkpoint](docs/10-ahb-and-harness/30-nova-android-a-button-navigation.md) corrects the Nova ABXY semantic table, filters the virtual-device feedback loop, and proves Android `KEYCODE_BUTTON_A` reaches SDL3 as Xbox button 0 / Linux `BTN_SOUTH`; A-button UI activation remains open.
- [Nova Android touch → Gamescope libei and fullscreen presentation checkpoint](docs/10-ahb-and-harness/31-nova-android-touch-libei-fullscreen.md) proves the app touch socket, ARM64 libei helper, Gamescope touch events, and native Steam Gamepad UI visible on the fullscreen AHardwareBuffer presentation path; hardware CEF remains open.
- [Nova live manual input diagnosis](docs/10-ahb-and-harness/32-nova-live-manual-input-diagnosis.md) records the persistent-session workflow, Android overlay focus issue, and live D-pad/touch observations.
- [Nova Steam font coverage open question](docs/10-ahb-and-harness/33-nova-steam-font-coverage-open-question.md) records the missing-glyph symptom without making it a blocker for the input/network loop.
- [Nova runtime harness lifecycle](docs/00-start-here/34-nova-runtime-harness-lifecycle.md) defines fresh run identity, exact cleanup, artifact provenance, and stale-evidence guardrails.
- [Parent session process audit](docs/10-ahb-and-harness/35-parent-session-process-audit-2026-08-08.md) records Luna's last-two-hours audit of repeated process mistakes and the resulting harness repairs.
- [Nova bounded acceptance profile](docs/00-start-here/36-nova-bounded-acceptance-profile.md) defines the reproducible 1280×960 AHB/libei acceptance profile and clean-run evidence.
- [Nova network and update compatibility boundary](docs/00-start-here/37-nova-network-and-update-compat.md) records Android-host network reachability, the research-only updater boundary, and the OOBE restart-branch isolation.
- [Nova X11 presentation capture](docs/10-ahb-and-harness/38-nova-x11-presentation-capture.md) adds same-run upstream window captures for separating CEF/Xwayland, Gamescope, and Android presentation failures.
- [Nova release-message stall](docs/10-ahb-and-harness/39-nova-release-message-stall-2026-08-08.md) records the first traced AHardwareBuffer release-wait boundary.
- [Parent session process-audit follow-up](docs/10-ahb-and-harness/40-parent-session-process-audit-followup-2026-08-08.md) records the next Luna audit and process repairs.
- [Nova harness provenance/reset fixes](docs/10-ahb-and-harness/41-nova-harness-provenance-reset-fixes-2026-08-08.md) records the linked-worktree and remote-shell cleanup hardening.
- [Nova AHB trace stall](docs/10-ahb-and-harness/42-nova-ahb-trace-stall-2026-08-08.md) records the fresh frame-level timezone-to-network reproducer.
- [Parent session process-audit follow-up 2](docs/10-ahb-and-harness/43-parent-session-process-audit-followup-2026-08-08.md) records the latest two-hours Luna audit and remaining workflow risks.
- [Nova AHB seqpacket experiment](docs/10-ahb-and-harness/44-nova-ahb-seqpacket-experiment-2026-08-08.md) defines the one-variable transport hypothesis and acceptance gate.
- [Nova AHB seqpacket result](docs/10-ahb-and-harness/45-nova-ahb-seqpacket-result-2026-08-08.md) records the negative device result and the next socket-instrumentation gate.
- [Parent session process-audit follow-up 3](docs/10-ahb-and-harness/46-parent-session-process-audit-followup-2026-08-08.md) records Luna's newest two-hour audit and the remaining preflight/capture/phase risks.
- [Nova AHB socket-trace experiment](docs/10-ahb-and-harness/47-nova-ahb-socket-trace-experiment-2026-08-08.md) predeclares syscall, ancillary-FD, inode, and poll evidence for the original stream baseline.
- [Nova mandatory preflight manifest](docs/10-ahb-and-harness/48-nova-preflight-manifest-2026-08-08.md) records and enforces the cleanup, reset, run-identity, and provenance gate repaired after the latest Luna audit.
- [Nova AHB socket-trace result](docs/10-ahb-and-harness/49-nova-ahb-socket-trace-result-2026-08-08.md) records the stream baseline's valid message/FD exchange and the frame-432 Android receive/release boundary.
- [Parent session process-audit follow-up 4](docs/10-ahb-and-harness/50-parent-session-process-audit-followup-2026-08-08.md) records Luna's latest two-hour audit and the remaining capture, timeout, focus, and phase-serialization risks.
- [Nova Android receive-wait experiment](docs/10-ahb-and-harness/51-nova-ahb-app-receive-wait-experiment-2026-08-08.md) predeclares the next diagnostic-only app-side ACK wait boundary.
- [Nova AHB transport observability result](docs/10-ahb-and-harness/54-nova-ahb-transport-observability-result-2026-08-09.md) records stable peer identities, complete ACK/SCM_RIGHTS syscalls, and the reproduced frame-318 receive boundary.
- [Parent session process-audit follow-up 5](docs/10-ahb-and-harness/55-parent-session-process-audit-followup-2026-08-09.md) records Luna's latest two-hour audit and the required timeout, path, polling, teardown, and phase-barrier repairs.
- [Nova manual harness guards](docs/10-ahb-and-harness/56-nova-manual-harness-guards-2026-08-09.md) records the finite-timeout policy and fail-closed post-stop verifier added after Luna's audit.
- [Nova AHB read-queue experiment](docs/10-ahb-and-harness/57-nova-ahb-read-queue-experiment-2026-08-09.md) predeclares the timed receive/FIONREAD boundary and blocked-thread evidence.
- [Nova AHB read-queue result](docs/10-ahb-and-harness/58-nova-ahb-read-queue-result-2026-08-09.md) records the reproduced frame-133 ACK wait, absent receive-timeout return, and clean guarded teardown.
- [Nova AHB receive-timeout observability experiment](docs/10-ahb-and-harness/59-nova-ahb-receive-timeout-observability-experiment-2026-08-09.md) predeclares logging and readback of Android's `SO_RCVTIMEO` setup without changing transport behavior.
- [Nova AHB receive-timeout observability result](docs/10-ahb-and-harness/60-nova-ahb-receive-timeout-observability-result-2026-08-09.md) records valid 15-second socket readback followed by the unchanged frame-273 blocking ACK boundary.
- [Parent session process-audit follow-up 6](docs/10-ahb-and-harness/61-parent-session-process-audit-followup-2026-08-09.md) records the remaining hard-coded X11, stale-log correlation, teardown, and capture-status risks.
- [Nova harness audit repairs](docs/10-ahb-and-harness/62-nova-harness-audit-repairs-2026-08-09.md) records the run-scoped X11 manifest, PID-filtered boundary poll, aggregate capture status, and fail-closed teardown wrapper added after the audit.
- [Nova AHB handshake-deadlock research synthesis](docs/10-ahb-and-harness/63-nova-ahb-handshake-deadlock-research-synthesis-2026-08-09.md) incorporates the attached report's ACK-first causal conclusion, hypothesis ordering, and independent SurfaceControl correctness items.
- [Nova AHB poll/recvmsg boundary experiment](docs/10-ahb-and-harness/64-nova-ahb-poll-recvmsg-boundary-experiment-2026-08-09.md) predeclares the property-gated finite ACK poll and queue-state observation.
- [Nova manual-capture harness guards](docs/10-ahb-and-harness/65-nova-harness-cdp-forward-guard-2026-08-09.md) records the invalid pre-forward/X11-staging attempts and the fail-closed capture preconditions added before the replacement run.
- [Nova AHB poll/recvmsg boundary result](docs/10-ahb-and-harness/66-nova-ahb-poll-recvmsg-boundary-result-2026-08-09.md) records the valid frame-109 timed poll with zero queued bytes, stable endpoint pairs, and the downstream EPIPE after diagnostic fail-closed behavior.
- [Nova blocking-stream ACK correlation experiment](docs/10-ahb-and-harness/67-nova-ahb-blocking-stream-correlation-experiment-2026-08-09.md) predeclares the unchanged blocking receiver needed to correlate a full Gamescope ACK with the same Android wait frame.
- [Nova blocking-stream ACK correlation result](docs/10-ahb-and-harness/68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md) records the earlier paired ACK boundary and its downstream ring release timeout.
- [Nova clock-correlated AHB socket trace experiment](docs/10-ahb-and-harness/69-nova-ahb-clock-correlated-socket-trace-experiment-2026-08-09.md) predeclares shared-clock and thread identity instrumentation for the original stream transport.
- [Nova clock-correlated AHB socket trace result](docs/10-ahb-and-harness/70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md) refines the deadlock ordering with a same-run 60-second frame-149 boundary.
- [Nova AHB continuous-repaint A/B result](docs/10-ahb-and-harness/71-nova-ahb-continuous-repaint-fix-2026-08-09.md) rejects the global repaint trigger after an exact-stack device comparison and records the retained transport/UI result.
- [Nova AHB repaint acceptance and Steam UI boundary](docs/10-ahb-and-harness/72-nova-ahb-repaint-acceptance-and-steam-ui-boundary-2026-08-09.md) records the current no-hunk acceptance, the visible Steam UI gate, and the test-bench report handoff repair.
- [Nova latest UI, touch, and login boundary](docs/10-ahb-and-harness/73-nova-latest-ui-touch-login-boundary-2026-08-09.md) records the fresh controller/touch validation, OOBE login-state transition, stale Android presentation, and event-driven AHB next step.
- [Nova AHB ancillary-data parser fix](docs/10-ahb-and-harness/74-nova-ahb-ancillary-parser-fix-2026-08-09.md) records the frame-188 `__cmsg_nxthdr` producer stall, the bounded control-message parser, and a fresh 240-frame device pass.
- [Nova continuous AHB quiet-scene fix](docs/10-ahb-and-harness/75-nova-continuous-ahb-quiet-scene-fix-2026-08-09.md) records the device validation that keeps the live receiver blocked through Gamescope quiet scenes while retaining the bounded probe timeout.
- [Nova AHB explicit cancellation](docs/10-ahb-and-harness/76-nova-ahb-explicit-cancellation-2026-08-09.md) records the bounded regression and Activity-stop cancellation validation for the blocking native receiver.
- [Nova Gamescope scheduler-trace integration](docs/10-ahb-and-harness/77-nova-gamescope-scheduler-trace-integration-2026-08-09.md) makes the opt-in repaint/present diagnostic patch part of the reproducible Gamescope build sequence.

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

## Blocker research rule

When a technical blocker appears, perform a current internet search before
treating it as a hard boundary. Prefer primary project documentation and
source, record the relevant URLs, revisions, and search date in the experiment
record, and compare more than one implementation path when practical.

Keep [Armada](https://github.com/armada-os/armada), [PockNix](https://github.com/shuuri-labs/pocknix-os),
and their [ROCKNIX](https://github.com/ROCKNIX/distribution) foundation as
standing prior-art references for SteamOS-like ARM64 Steam sessions, gamescope,
Xwayland, Proton/FEX, input, audio, display, boot, and lifecycle details. Use
those projects to extract implementation ideas while explicitly separating
their full Linux/DRM/KMS assumptions from this repo's Android/rootfs path.

## Documentation

The documentation is organized into browsable evidence bands. Start with the
[documentation map](docs/README.md), then read the [current roadmap](docs/00-start-here/06-android-linux-gamescope-roadmap.md)
and [lifecycle contract](docs/00-start-here/34-nova-runtime-harness-lifecycle.md)
before choosing work or running the device.

Current high-value records:

- [Standalone runtime/product requirement](docs/00-start-here/299-nova-standalone-runtime-acquisition-product-requirement-2026-08-10.md)
- [SteamclientTermux comparison](docs/00-start-here/333-steamclienttermux-comparison-2026-08-10.md)
- [APK first-run provisioning requirement](docs/00-start-here/333-nova-apk-idempotent-first-run-provisioning-2026-08-10.md)
- [System-D-Bus QR-login result](docs/20-termux-x11/188-termux-x11-system-dbus-only-result-2026-08-09.md)
- [Signed-in interactive QR result](docs/20-termux-x11/195-termux-x11-interactive-qr-login-result-2026-08-09.md)
- [Proton 11 Geometry Wars first-frame result](docs/00-start-here/329-nova-geometry-wars-one-click-first-frame-result-2026-08-10.md)
- [Latest clean-device OOBE boundary](docs/00-start-here/336-nova-clean-device-apk-oobe-2026-08-10.md)
- [Truthful SteamOS update adapter boundary](docs/00-start-here/337-nova-steamos-update-truthful-no-update-adapter-2026-08-10.md)

Use the folder indexes to browse historical experiment/result pairs without
turning the root README into a second flat archive.

## Evidence standard


“Proven” means the repository contains concrete on-device output, test artifacts, or a documented build/run result. “Partial” means a lower-level prerequisite works but the target milestone does not. “Claimed/untested” means the artifact describes a path but does not include enough device evidence to verify it independently.

## Scope note

This archive records technical evidence, not a redistribution of Valve runtime binaries. The attached ZIP was inspected but is not copied into this repository. Its SHA-256 and original workspace path are recorded in the kit assessment.
