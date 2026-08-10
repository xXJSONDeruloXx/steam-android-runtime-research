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
- The attached [Termux:X11 kit assessment](docs/02-termux-x11-kit-assessment.md) is a useful simpler bring-up path for normal ARM64 Steam desktop mode, but its own README explicitly excludes Gamescope and Steam Deck Big Picture.
- The open [Termux:X11-to-Android forwarding track](docs/117-x11-android-forwarding-experiment-plan-2026-08-09.md) is now being taken past the initial display/lifecycle ladder toward native Steam OOBE, login, and a QR-code view visibly rendered on the Android screen; its first [partial display result](docs/119-termux-x11-display-bring-up-result-2026-08-09.md) has not yet reached a mapped synthetic window.
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
- [Nova AHB transport observability result](docs/54-nova-ahb-transport-observability-result-2026-08-09.md) records stable peer identities, complete ACK/SCM_RIGHTS syscalls, and the reproduced frame-318 receive boundary.
- [Parent session process-audit follow-up 5](docs/55-parent-session-process-audit-followup-2026-08-09.md) records Luna's latest two-hour audit and the required timeout, path, polling, teardown, and phase-barrier repairs.
- [Nova manual harness guards](docs/56-nova-manual-harness-guards-2026-08-09.md) records the finite-timeout policy and fail-closed post-stop verifier added after Luna's audit.
- [Nova AHB read-queue experiment](docs/57-nova-ahb-read-queue-experiment-2026-08-09.md) predeclares the timed receive/FIONREAD boundary and blocked-thread evidence.
- [Nova AHB read-queue result](docs/58-nova-ahb-read-queue-result-2026-08-09.md) records the reproduced frame-133 ACK wait, absent receive-timeout return, and clean guarded teardown.
- [Nova AHB receive-timeout observability experiment](docs/59-nova-ahb-receive-timeout-observability-experiment-2026-08-09.md) predeclares logging and readback of Android's `SO_RCVTIMEO` setup without changing transport behavior.
- [Nova AHB receive-timeout observability result](docs/60-nova-ahb-receive-timeout-observability-result-2026-08-09.md) records valid 15-second socket readback followed by the unchanged frame-273 blocking ACK boundary.
- [Parent session process-audit follow-up 6](docs/61-parent-session-process-audit-followup-2026-08-09.md) records the remaining hard-coded X11, stale-log correlation, teardown, and capture-status risks.
- [Nova harness audit repairs](docs/62-nova-harness-audit-repairs-2026-08-09.md) records the run-scoped X11 manifest, PID-filtered boundary poll, aggregate capture status, and fail-closed teardown wrapper added after the audit.
- [Nova AHB handshake-deadlock research synthesis](docs/63-nova-ahb-handshake-deadlock-research-synthesis-2026-08-09.md) incorporates the attached report's ACK-first causal conclusion, hypothesis ordering, and independent SurfaceControl correctness items.
- [Nova AHB poll/recvmsg boundary experiment](docs/64-nova-ahb-poll-recvmsg-boundary-experiment-2026-08-09.md) predeclares the property-gated finite ACK poll and queue-state observation.
- [Nova manual-capture harness guards](docs/65-nova-harness-cdp-forward-guard-2026-08-09.md) records the invalid pre-forward/X11-staging attempts and the fail-closed capture preconditions added before the replacement run.
- [Nova AHB poll/recvmsg boundary result](docs/66-nova-ahb-poll-recvmsg-boundary-result-2026-08-09.md) records the valid frame-109 timed poll with zero queued bytes, stable endpoint pairs, and the downstream EPIPE after diagnostic fail-closed behavior.
- [Nova blocking-stream ACK correlation experiment](docs/67-nova-ahb-blocking-stream-correlation-experiment-2026-08-09.md) predeclares the unchanged blocking receiver needed to correlate a full Gamescope ACK with the same Android wait frame.
- [Nova blocking-stream ACK correlation result](docs/68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md) records the earlier paired ACK boundary and its downstream ring release timeout.
- [Nova clock-correlated AHB socket trace experiment](docs/69-nova-ahb-clock-correlated-socket-trace-experiment-2026-08-09.md) predeclares shared-clock and thread identity instrumentation for the original stream transport.
- [Nova clock-correlated AHB socket trace result](docs/70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md) refines the deadlock ordering with a same-run 60-second frame-149 boundary.
- [Nova AHB continuous-repaint A/B result](docs/71-nova-ahb-continuous-repaint-fix-2026-08-09.md) rejects the global repaint trigger after an exact-stack device comparison and records the retained transport/UI result.
- [Nova AHB repaint acceptance and Steam UI boundary](docs/72-nova-ahb-repaint-acceptance-and-steam-ui-boundary-2026-08-09.md) records the current no-hunk acceptance, the visible Steam UI gate, and the test-bench report handoff repair.
- [Nova latest UI, touch, and login boundary](docs/73-nova-latest-ui-touch-login-boundary-2026-08-09.md) records the fresh controller/touch validation, OOBE login-state transition, stale Android presentation, and event-driven AHB next step.
- [Nova AHB ancillary-data parser fix](docs/74-nova-ahb-ancillary-parser-fix-2026-08-09.md) records the frame-188 `__cmsg_nxthdr` producer stall, the bounded control-message parser, and a fresh 240-frame device pass.
- [Nova continuous AHB quiet-scene fix](docs/75-nova-continuous-ahb-quiet-scene-fix-2026-08-09.md) records the device validation that keeps the live receiver blocked through Gamescope quiet scenes while retaining the bounded probe timeout.
- [Nova AHB explicit cancellation](docs/76-nova-ahb-explicit-cancellation-2026-08-09.md) records the bounded regression and Activity-stop cancellation validation for the blocking native receiver.
- [Nova Gamescope scheduler-trace integration](docs/77-nova-gamescope-scheduler-trace-integration-2026-08-09.md) makes the opt-in repaint/present diagnostic patch part of the reproducible Gamescope build sequence.

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
- [Nova AHB transport observability experiment](docs/53-nova-ahb-transport-observability-experiment-2026-08-09.md)
- [Nova AHB transport observability result](docs/54-nova-ahb-transport-observability-result-2026-08-09.md)
- [Parent session process-audit follow-up 5](docs/55-parent-session-process-audit-followup-2026-08-09.md)
- [Nova manual harness guards](docs/56-nova-manual-harness-guards-2026-08-09.md)
- [Nova AHB read-queue experiment](docs/57-nova-ahb-read-queue-experiment-2026-08-09.md)
- [Nova AHB read-queue result](docs/58-nova-ahb-read-queue-result-2026-08-09.md)
- [Nova AHB receive-timeout observability experiment](docs/59-nova-ahb-receive-timeout-observability-experiment-2026-08-09.md)
- [Nova AHB receive-timeout observability result](docs/60-nova-ahb-receive-timeout-observability-result-2026-08-09.md)
- [Parent session process-audit follow-up 6](docs/61-parent-session-process-audit-followup-2026-08-09.md)
- [Nova harness audit repairs](docs/62-nova-harness-audit-repairs-2026-08-09.md)
- [Nova AHB handshake-deadlock research synthesis](docs/63-nova-ahb-handshake-deadlock-research-synthesis-2026-08-09.md)
- [Nova AHB poll/recvmsg boundary experiment](docs/64-nova-ahb-poll-recvmsg-boundary-experiment-2026-08-09.md)
- [Nova manual-capture harness guards](docs/65-nova-harness-cdp-forward-guard-2026-08-09.md)
- [Nova AHB poll/recvmsg boundary result](docs/66-nova-ahb-poll-recvmsg-boundary-result-2026-08-09.md)
- [Nova blocking-stream ACK correlation experiment](docs/67-nova-ahb-blocking-stream-correlation-experiment-2026-08-09.md)
- [Nova blocking-stream ACK correlation result](docs/68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md)
- [Nova clock-correlated AHB socket trace experiment](docs/69-nova-ahb-clock-correlated-socket-trace-experiment-2026-08-09.md)
- [Nova clock-correlated AHB socket trace result](docs/70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md)
- [Nova AHB continuous-repaint fix](docs/71-nova-ahb-continuous-repaint-fix-2026-08-09.md)
- [Nova AHB repaint acceptance and Steam UI boundary](docs/72-nova-ahb-repaint-acceptance-and-steam-ui-boundary-2026-08-09.md)
- [Nova latest UI, touch, and login boundary](docs/73-nova-latest-ui-touch-login-boundary-2026-08-09.md)
- [Nova AHB ancillary-data parser fix](docs/74-nova-ahb-ancillary-parser-fix-2026-08-09.md)
- [Nova continuous AHB quiet-scene fix](docs/75-nova-continuous-ahb-quiet-scene-fix-2026-08-09.md)
- [Nova AHB explicit cancellation](docs/76-nova-ahb-explicit-cancellation-2026-08-09.md)
- [Nova Gamescope scheduler-trace integration](docs/77-nova-gamescope-scheduler-trace-integration-2026-08-09.md)
- [Nova Gamescope scheduler-trace device result](docs/78-nova-gamescope-scheduler-trace-result-2026-08-09.md)
- [Nova AHB frame identity device result](docs/79-nova-ahb-frame-identity-result-2026-08-09.md)
- [Nova AHB downstream surface-marker experiment](docs/80-nova-ahb-surface-marker-experiment-2026-08-09.md)
- [Nova AHB downstream surface-marker result](docs/81-nova-ahb-surface-marker-result-2026-08-09.md)
- [Nova origin/main repaint-trigger result](docs/82-nova-origin-main-repaint-trigger-result-2026-08-09.md)
- [Nova OOBE A-button surface-correlation experiment](docs/83-nova-oobe-a-button-surface-correlation-experiment-2026-08-09.md)
- [Nova OOBE A-button surface-correlation result](docs/84-nova-oobe-a-button-result-2026-08-09.md)
- [Nova bounded-session overlay guard experiment](docs/85-nova-bounded-overlay-guard-experiment-2026-08-09.md)
- [Nova OOBE AHB lifecycle-grace experiment](docs/86-nova-oobe-ahb-lifecycle-grace-experiment-2026-08-09.md)
- [Nova OOBE AHB lifecycle-grace result](docs/87-nova-oobe-ahb-lifecycle-grace-result-2026-08-09.md)
- [Nova Gamescope present-cadence result](docs/88-nova-gamescope-present-cadence-result-2026-08-09.md)
- [Nova AHB valid-content cadence experiment](docs/89-nova-ahb-valid-content-cadence-experiment-2026-08-09.md)
- [Nova AHB valid-content cadence result](docs/90-nova-ahb-valid-content-cadence-result-2026-08-09.md)
- [Nova AHB valid-content timeout-split experiment](docs/91-nova-ahb-valid-content-timeout-split-experiment-2026-08-09.md)
- [Nova AHB valid-content timeout-split result](docs/92-nova-ahb-valid-content-timeout-split-result-2026-08-09.md)
- [Nova controller UI readiness-timeout experiment](docs/93-nova-controller-ui-readiness-timeout-experiment-2026-08-09.md)
- [Nova controller UI readiness-timeout result](docs/94-nova-controller-ui-readiness-timeout-result-2026-08-09.md)
- [Nova presentation diagnostics experiment](docs/95-nova-presentation-diagnostics-experiment-2026-08-09.md)
- [Nova presentation diagnostics result](docs/96-nova-presentation-diagnostics-result-2026-08-09.md)
- [Nova same-run X11/AHB presentation split experiment](docs/97-nova-same-run-x11-ahb-presentation-split-experiment-2026-08-09.md)
- [Nova same-run X11/AHB presentation split result](docs/98-nova-same-run-x11-ahb-presentation-split-result-2026-08-09.md)
- [Nova 1280x960 Steam/X11 resolution experiment](docs/99-nova-1280x960-steam-x11-resolution-experiment-2026-08-09.md)
- [Nova 1280x960 Steam/X11 resolution result](docs/100-nova-1280x960-steam-x11-resolution-result-2026-08-09.md)
- [Nova settled X11 presentation timing experiment](docs/101-nova-settled-x11-presentation-timing-experiment-2026-08-09.md)
- [Nova settled X11 presentation timing result](docs/102-nova-settled-x11-presentation-timing-result-2026-08-09.md)
- [Nova AHB pre-marker content probe experiment](docs/103-nova-ahb-pre-marker-content-probe-experiment-2026-08-09.md)
- [Nova AHB pre-marker content probe result](docs/104-nova-ahb-pre-marker-content-probe-result-2026-08-09.md)
- [Nova AHB import-layout probe experiment](docs/105-nova-ahb-import-layout-probe-experiment-2026-08-09.md)
- [Nova AHB import-layout probe result](docs/106-nova-ahb-import-layout-probe-result-2026-08-09.md)
- [Nova AHB output-tiling A/B experiment](docs/107-nova-ahb-output-tiling-ab-experiment-2026-08-09.md)
- [Nova AHB output-tiling A/B result](docs/108-nova-ahb-output-tiling-ab-result-2026-08-09.md)
- [Nova optimal-tiling Steam-surface experiment](docs/109-nova-optimal-tiling-steam-surface-experiment-2026-08-09.md)
- [Nova optimal-tiling Steam-surface result](docs/110-nova-optimal-tiling-steam-surface-result-2026-08-09.md)
- [Nova raw AHardwareBuffer snapshot experiment](docs/111-nova-ahb-raw-snapshot-experiment-2026-08-09.md)
- [Nova raw AHardwareBuffer snapshot result](docs/112-nova-ahb-raw-snapshot-result-2026-08-09.md)
- [Nova Vulkan AHardwareBuffer readback experiment](docs/113-nova-ahb-vulkan-readback-experiment-2026-08-09.md)
- [Nova Vulkan AHardwareBuffer readback result](docs/114-nova-ahb-vulkan-readback-result-2026-08-09.md)
- [Nova Vulkan AHardwareBuffer readback rerun experiment](docs/115-nova-ahb-vulkan-readback-rerun-experiment-2026-08-09.md)
- [Nova Vulkan AHardwareBuffer readback rerun result](docs/116-nova-ahb-vulkan-readback-rerun-result-2026-08-09.md)
- [X11-to-Android forwarding experiment plan](docs/117-x11-android-forwarding-experiment-plan-2026-08-09.md)
- [Termux:X11 display bring-up experiment](docs/118-termux-x11-display-bring-up-experiment-2026-08-09.md)
- [Termux:X11 display bring-up partial result](docs/119-termux-x11-display-bring-up-result-2026-08-09.md)
- [Termux:X11 private-namespace client retry](docs/120-termux-x11-private-namespace-client-retry-2026-08-09.md)
- [Termux:X11 cleanup-token self-match result](docs/121-termux-x11-cleanup-token-self-match-result-2026-08-09.md)
- [Termux:X11 stateful cleanup and foreground launcher result](docs/122-termux-x11-stateful-cleanup-result-2026-08-09.md)
- [Termux:X11 synthetic window result](docs/123-termux-x11-synthetic-window-result-2026-08-09.md)
- [Termux:X11 Android screen capture experiment](docs/124-termux-x11-android-screen-capture-experiment-2026-08-09.md)
- [Termux:X11 screen-capture preflight result](docs/125-termux-x11-screen-capture-preflight-result-2026-08-09.md)
- [Termux:X11 screen-capture Magisk preflight result](docs/126-termux-x11-screen-capture-magisk-preflight-result-2026-08-09.md)
- [Termux:X11 screen-capture phase-aware preflight result](docs/127-termux-x11-screen-capture-phase-preflight-result-2026-08-09.md)
- [Termux:X11 explicit cleanup-phase repair](docs/128-termux-x11-explicit-cleanup-phase-repair-2026-08-09.md)
- [Termux:X11 Android screen-capture result](docs/129-termux-x11-android-screen-capture-result-2026-08-09.md)
- [Termux:X11 native ARM64 Steam experiment](docs/130-termux-x11-native-steam-experiment-2026-08-09.md)
- [Termux:X11 native ARM64 Steam result](docs/131-termux-x11-native-steam-result-2026-08-09.md)
- [Termux:X11 rootfs device-namespace repair experiment](docs/132-termux-x11-rootfs-device-repair-experiment-2026-08-09.md)
- [Termux:X11 rootfs device-namespace repair result](docs/133-termux-x11-rootfs-device-repair-result-2026-08-09.md)
- [Termux:X11 rootfs stdio probe experiment](docs/134-termux-x11-rootfs-stdio-probe-experiment-2026-08-09.md)
- [Termux:X11 rootfs stdio probe result](docs/135-termux-x11-rootfs-stdio-probe-result-2026-08-09.md)
- [Termux:X11 native ARM64 Steam root-identity experiment](docs/136-termux-x11-native-steam-root-identity-experiment-2026-08-09.md)
- [Termux:X11 native ARM64 Steam root-identity result](docs/137-termux-x11-native-steam-root-identity-result-2026-08-09.md)
- [Termux:X11 rootfs `/dev` bind probe experiment](docs/138-termux-x11-rootfs-dev-bind-probe-experiment-2026-08-09.md)
- [Termux:X11 rootfs `/dev` bind probe result](docs/139-termux-x11-rootfs-dev-bind-probe-result-2026-08-09.md)
- [Termux:X11 native ARM64 Steam `/dev` bind experiment](docs/140-termux-x11-native-steam-dev-bind-experiment-2026-08-09.md)
- [Termux:X11 native ARM64 Steam `/dev` bind preflight result](docs/141-termux-x11-native-steam-dev-bind-preflight-result-2026-08-09.md)
- [Termux:X11 native ARM64 Steam bind-launcher forwarding repair](docs/142-termux-x11-native-steam-dev-bind-launcher-forwarding-repair-2026-08-09.md)
- [Termux:X11 native ARM64 Steam `/dev` bind result](docs/143-termux-x11-native-steam-dev-bind-result-2026-08-09.md)
- [Termux:X11 native ARM64 Steam `/dev/shm` experiment](docs/144-termux-x11-native-steam-dev-shm-experiment-2026-08-09.md)
- [Termux:X11 native ARM64 Steam `/dev/shm` result](docs/145-termux-x11-native-steam-dev-shm-result-2026-08-09.md)
- [Termux:X11 native ARM64 Steam procfs experiment](docs/146-termux-x11-native-steam-procfs-experiment-2026-08-09.md)
- [Termux:X11 native ARM64 Steam procfs result](docs/147-termux-x11-native-steam-procfs-result-2026-08-09.md)
- [Termux:X11 cleanup and log-capture repair](docs/148-termux-x11-cleanup-and-log-capture-repair-2026-08-09.md)
- [Termux:X11 cleanup/log-capture control result](docs/149-termux-x11-cleanup-log-capture-control-result-2026-08-09.md)
- [Termux:X11 native Steam cleanup-control experiment](docs/150-termux-x11-native-steam-cleanup-control-experiment-2026-08-09.md)
- [Termux:X11 native Steam cleanup-control result](docs/151-termux-x11-native-steam-cleanup-control-result-2026-08-09.md)
- [Termux:X11 native Steam `-cef-disable-gpu` experiment](docs/152-termux-x11-native-steam-cef-disable-gpu-experiment-2026-08-09.md)
- [Termux:X11 native Steam `-cef-disable-gpu` result](docs/153-termux-x11-native-steam-cef-disable-gpu-result-2026-08-09.md)
- [Termux:X11 native Steam delayed CEF capture experiment](docs/154-termux-x11-native-steam-cef-delayed-capture-experiment-2026-08-09.md)
- [Termux:X11 native Steam delayed CEF capture result](docs/155-termux-x11-native-steam-cef-delayed-capture-result-2026-08-09.md)
- [Termux:X11 native Steam OOBE Enter-input experiment](docs/156-termux-x11-native-steam-oobe-enter-experiment-2026-08-09.md)
- [Termux:X11 native Steam OOBE Enter focus-guard result](docs/157-termux-x11-native-steam-oobe-enter-focus-guard-result-2026-08-09.md)
- [Termux:X11 native Steam OOBE Enter retry experiment](docs/158-termux-x11-native-steam-oobe-enter-retry-experiment-2026-08-09.md)
- [Termux:X11 native Steam OOBE timezone result](docs/159-termux-x11-native-steam-oobe-timezone-result-2026-08-09.md)
- [Termux:X11 native Steam OOBE timezone Enter experiment](docs/160-termux-x11-native-steam-oobe-timezone-enter-experiment-2026-08-09.md)
- [Termux:X11 native Steam OOBE timezone persistence result](docs/161-termux-x11-native-steam-oobe-timezone-persistence-result-2026-08-09.md)
- [Termux:X11 native Steam OOBE two-Enter sequence experiment](docs/162-termux-x11-native-steam-oobe-two-enter-sequence-experiment-2026-08-09.md)
- [Termux:X11 native Steam OOBE network result](docs/163-termux-x11-native-steam-oobe-network-result-2026-08-09.md)
- [Termux:X11 native Steam OOBE network-select experiment](docs/164-termux-x11-native-steam-oobe-network-select-experiment-2026-08-09.md)
- [Termux:X11 native Steam OOBE login-wait result](docs/165-termux-x11-native-steam-oobe-login-wait-result-2026-08-09.md)
- [Termux:X11 native Steam OOBE login settle experiment](docs/166-termux-x11-native-steam-oobe-login-settle-experiment-2026-08-09.md)
- [Termux:X11 native Steam OOBE login-settle result](docs/167-termux-x11-native-steam-oobe-login-settle-result-2026-08-09.md)
- [Termux:X11 native Steam OOBE login-lifetime experiment](docs/168-termux-x11-native-steam-oobe-login-lifetime-experiment-2026-08-09.md)
- [Termux:X11 native Steam OOBE login-lifetime result](docs/169-termux-x11-native-steam-oobe-login-lifetime-result-2026-08-09.md)
- [Termux:X11 native Steam login API probe experiment](docs/170-termux-x11-native-steam-login-api-probe-experiment-2026-08-09.md)
- [Termux:X11 native Steam login API probe result](docs/171-termux-x11-native-steam-login-api-probe-result-2026-08-09.md)
- [Termux:X11 networking phase plan](docs/172-termux-x11-networking-phase-plan-2026-08-09.md)
- [Termux:X11 network and Steam bridge inventory experiment](docs/173-termux-x11-network-inventory-experiment-2026-08-09.md)
- [Termux:X11 network inventory window-wait result](docs/174-termux-x11-network-inventory-window-wait-result-2026-08-09.md)
- [Termux:X11 network inventory client-selection result](docs/175-termux-x11-network-inventory-client-selection-result-2026-08-09.md)
- [Termux:X11 network inventory observer-path result](docs/176-termux-x11-network-inventory-observer-path-result-2026-08-09.md)
- [Termux:X11 network inventory result](docs/177-termux-x11-network-inventory-result-2026-08-09.md)
- [Termux:X11 private session-bus experiment](docs/178-termux-x11-network-session-bus-experiment-2026-08-09.md)
- [Termux:X11 private session-bus startup-failure result](docs/179-termux-x11-network-session-bus-startup-failure-result-2026-08-09.md)
- [Termux:X11 root-private session-bus repair experiment](docs/180-termux-x11-root-private-session-bus-repair-experiment-2026-08-09.md)
- [Termux:X11 root-private session-bus result](docs/181-termux-x11-root-private-session-bus-result-2026-08-09.md)
- [Termux:X11 root-private session-bus CDP confirmation](docs/182-termux-x11-root-private-session-bus-cdp-experiment-2026-08-09.md)
- [Termux:X11 root-private session-bus CDP result](docs/183-termux-x11-root-private-session-bus-cdp-result-2026-08-09.md)
- [Termux:X11 rootfs network-service inventory result](docs/184-termux-x11-network-rootfs-service-inventory-result-2026-08-09.md)
- [Termux:X11 UID-matched session-bus experiment](docs/185-termux-x11-uid-matched-session-bus-experiment-2026-08-09.md)
- [Termux:X11 UID-matched session-bus result](docs/186-termux-x11-uid-matched-session-bus-result-2026-08-09.md)
- [Termux:X11 system-D-Bus-only experiment](docs/187-termux-x11-system-dbus-only-experiment-2026-08-09.md)
- [Termux:X11 system-D-Bus-only result](docs/188-termux-x11-system-dbus-only-result-2026-08-09.md)
- [Termux:X11 system-D-Bus repeatability experiment](docs/189-termux-x11-system-dbus-repeat-experiment-2026-08-09.md)
- [Termux:X11 system-D-Bus repeat result](docs/190-termux-x11-system-dbus-repeat-result-2026-08-09.md)
- [Termux:X11 system-D-Bus profile packaging](docs/191-termux-x11-system-dbus-profile-packaging-2026-08-09.md)
- [Termux:X11 system-bus-only dependency isolation experiment](docs/192-termux-x11-system-bus-without-session-bus-experiment-2026-08-09.md)
- [Termux:X11 system-bus-only result](docs/193-termux-x11-system-bus-without-session-bus-result-2026-08-09.md)
- [Termux:X11 two-bus interactive QR login session](docs/194-termux-x11-two-bus-qr-login-interactive-experiment-2026-08-09.md)
- [Termux:X11 interactive QR login result](docs/195-termux-x11-interactive-qr-login-result-2026-08-09.md)
- [Termux:X11 post-login subsystem boundary result](docs/196-termux-x11-post-login-subsystem-boundary-result-2026-08-09.md)
- [Nova one-click launcher implementation](docs/197-nova-one-click-launcher-implementation-2026-08-09.md)
- [Termux:X11 198X game-launch boundary result](docs/198-termux-x11-198x-game-launch-result-2026-08-09.md)
- [Nova one-click APK v0.3 acceptance boundary](docs/199-nova-one-click-apk-v03-acceptance-boundary-2026-08-09.md)
- [Nova Termux:X11 hardware-acceleration capability probe](docs/200-nova-termux-x11-hardware-accel-probe-2026-08-09.md)
- [Nova Steam-to-Android AudioTrack PCM bridge experiment](docs/201-nova-steam-audiotrack-pcm-bridge-experiment-2026-08-09.md)
- [Nova Termux:X11 aspect-ratio visual check](docs/202-nova-termux-x11-aspect-ratio-visual-check-2026-08-09.md)
- [Termux:X11 198X command-line launch experiment](docs/203-termux-x11-198x-cli-launch-experiment-2026-08-09.md)
- [Nova x86-64 compatibility-runtime inventory](docs/204-nova-x86-runtime-inventory-experiment-2026-08-10.md)
- [Nova Proton 11 ARM64 Steam-download experiment](docs/205-nova-proton-11-arm64-steam-download-experiment-2026-08-10.md)
- [Nova Proton 11 ARM64 198X tool-discovery experiment](docs/206-nova-proton-11-arm64-198x-tool-discovery-experiment-2026-08-10.md)
- [Nova Proton 11 ARM64 Geometry Wars experiment](docs/207-nova-proton-11-arm64-geometry-wars-experiment-2026-08-10.md)
- [Nova Proton 11 ARM64 Peggle Deluxe experiment](docs/208-nova-proton-11-arm64-peggle-deluxe-experiment-2026-08-10.md)
- [Nova Termux:X11 Steam hardware-acceleration UI experiment](docs/209-nova-termux-x11-steam-hardware-accel-ui-experiment-2026-08-10.md)
- [Retroid Pocket Nova flashing kit](tools/retroid-pocket-nova/README.md)

## Evidence standard

“Proven” means the repository contains concrete on-device output, test artifacts, or a documented build/run result. “Partial” means a lower-level prerequisite works but the target milestone does not. “Claimed/untested” means the artifact describes a path but does not include enough device evidence to verify it independently.

## Scope note

This archive records technical evidence, not a redistribution of Valve runtime binaries. The attached ZIP was inspected but is not copied into this repository. Its SHA-256 and original workspace path are recorded in the kit assessment.
