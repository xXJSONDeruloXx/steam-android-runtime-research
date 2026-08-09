# Document index

The numbered files are dated evidence records. Read the current syntheses and
operational documents first; use the historical records to recover exact
commands, artifacts, and observations. Historical snapshots are not rewritten
to make their original conclusions look current.

## Current syntheses

- [Parent-session process-audit summary](parent-session-process-audit-summary.md)
- [Nova AHardwareBuffer transport investigation summary](nova-ahb-transport-investigation-summary.md)
- [Doc 34 — runtime harness lifecycle](34-nova-runtime-harness-lifecycle.md)
- [Doc 36 — bounded 1280×960 acceptance profile](36-nova-bounded-acceptance-profile.md)
- [Doc 37 — network and update compatibility](37-nova-network-and-update-compat.md)
- [Doc 38 — X11 presentation capture](38-nova-x11-presentation-capture.md)
- [Doc 62 — harness audit repairs](62-nova-harness-audit-repairs-2026-08-09.md)
- [Doc 65 — CDP-forward and capture guard](65-nova-harness-cdp-forward-guard-2026-08-09.md)

## Background and architecture

- [01 — prior-work evidence](01-prior-work-evidence.md)
- [02 — Termux:X11 kit assessment](02-termux-x11-kit-assessment.md)
- [03 — decision matrix](03-decision-matrix.md)
- [04 — open questions and next experiments](04-open-questions.md)
- [05 — current ARM64 Steam research](05-current-arm64-steam-research.md)
- [06 — Android/Linux/Gamescope roadmap](06-android-linux-gamescope-roadmap.md)

## Nova bring-up and Steam milestones

- [07 — rooted bridge smoke test](07-nova-rooted-bridge-smoke-test.md)
- [08 — Holo glibc/Vulkan probe](08-nova-holo-glibc-vulkan-probe.md)
- [09 — Android AHardwareBuffer handle probe](09-nova-android-ahardwarebuffer-handle-probe.md)
- [10 — stock Gamescope control](10-nova-stock-gamescope-control.md)
- [11 — headless Gamescope seam](11-nova-headless-gamescope-seam.md)
- [12 — Gamescope AHardwareBuffer output](12-nova-gamescope-ahb-output.md) *(historical control)*
- [13 — Xwayland AHardwareBuffer output](13-nova-xwayland-ahb-output.md) *(historical control)*
- [14 — native ARM64 Steam seed and startup](14-nova-steam-arm64-seed-and-startup.md)
- [15 — SteamUI AHardwareBuffer smoke](15-nova-steam-ui-ahb-smoke.md)
- [16 — Gamescope libei input seam](16-nova-libei-input-smoke.md)
- [17 — native Steam hardware GLX probe](17-nova-steam-hardware-glx-probe.md)
- [18 — rooted uinput gamepad smoke](18-nova-uinput-gamepad-smoke.md)
- [19 — Android input to rooted uinput bridge](19-nova-android-input-uinput-bridge.md)
- [20 — physical controller dispatch](20-nova-physical-controller-dispatch.md)
- [21 — virtual gamepad udev visibility](21-nova-input-udev-device-visibility.md)
- [22 — Steam input process-FD probe](22-nova-steam-input-process-fd.md)
- [23 — controlled Steam Gamepad UI input](23-nova-steam-controller-ui-input.md)
- [24 — D-pad semantic input](24-nova-steam-dpad-input.md)
- [25 — Android input bridge in Steam UI](25-nova-android-input-steam-ui.md)
- [26 — SDL3 joystick target-selection pitfall](26-nova-sdl3-event-input.md)
- [27 — SDL3 Gamepad semantic event delivery](27-nova-sdl3-gamepad-event.md)
- [28 — Steam D-pad navigation acceptance](28-nova-steam-dpad-navigation.md)
- [29 — Android bridge Steam UI navigation acceptance](29-nova-android-input-steam-ui-navigation.md)
- [30 — Android A-button mapping checkpoint](30-nova-android-a-button-navigation.md)
- [31 — touch, libei, and fullscreen presentation](31-nova-android-touch-libei-fullscreen.md)
- [32 — live manual input diagnosis](32-nova-live-manual-input-diagnosis.md)
- [33 — Steam font coverage open question](33-nova-steam-font-coverage-open-question.md)

## Parent-session audits and harness repairs

- [35 — parent-session process audit](35-parent-session-process-audit-2026-08-08.md)
- [40 — process-audit follow-up](40-parent-session-process-audit-followup-2026-08-08.md)
- [41 — harness provenance/reset fixes](41-nova-harness-provenance-reset-fixes-2026-08-08.md)
- [43 — process-audit follow-up 2](43-parent-session-process-audit-followup-2026-08-08.md)
- [46 — process-audit follow-up 3](46-parent-session-process-audit-followup-2026-08-08.md)
- [48 — mandatory preflight manifest](48-nova-preflight-manifest-2026-08-08.md)
- [50 — process-audit follow-up 4](50-parent-session-process-audit-followup-2026-08-08.md)
- [55 — process-audit follow-up 5](55-parent-session-process-audit-followup-2026-08-09.md)
- [56 — manual harness guards](56-nova-manual-harness-guards-2026-08-09.md)
- [61 — process-audit follow-up 6](61-parent-session-process-audit-followup-2026-08-09.md)

## AHardwareBuffer transport investigation

### Initial traces and socket comparisons

- [39 — release-message stall](39-nova-release-message-stall-2026-08-08.md)
- [42 — AHB trace stall](42-nova-ahb-trace-stall-2026-08-08.md)
- [44 — seqpacket experiment](44-nova-ahb-seqpacket-experiment-2026-08-08.md)
- [45 — seqpacket result](45-nova-ahb-seqpacket-result-2026-08-08.md)
- [47 — socket-trace experiment](47-nova-ahb-socket-trace-experiment-2026-08-08.md)
- [49 — socket-trace result](49-nova-ahb-socket-trace-result-2026-08-08.md)

### Receive, queue, and endpoint observability

- [51 — Android receive-wait experiment](51-nova-ahb-app-receive-wait-experiment-2026-08-08.md)
- [52 — Android receive-wait result](52-nova-ahb-app-receive-wait-result-2026-08-09.md)
- [53 — transport observability experiment](53-nova-ahb-transport-observability-experiment-2026-08-09.md)
- [54 — transport observability result](54-nova-ahb-transport-observability-result-2026-08-09.md)
- [57 — read-queue experiment](57-nova-ahb-read-queue-experiment-2026-08-09.md)
- [58 — read-queue result](58-nova-ahb-read-queue-result-2026-08-09.md)
- [59 — receive-timeout observability experiment](59-nova-ahb-receive-timeout-observability-experiment-2026-08-09.md)
- [60 — receive-timeout observability result](60-nova-ahb-receive-timeout-observability-result-2026-08-09.md)
- [63 — handshake-deadlock research synthesis](63-nova-ahb-handshake-deadlock-research-synthesis-2026-08-09.md)
- [64 — poll/recvmsg boundary experiment](64-nova-ahb-poll-recvmsg-boundary-experiment-2026-08-09.md)
- [66 — poll/recvmsg boundary result](66-nova-ahb-poll-recvmsg-boundary-result-2026-08-09.md)

### Correlation and current hypothesis

- [67 — blocking-stream correlation experiment](67-nova-ahb-blocking-stream-correlation-experiment-2026-08-09.md)
- [68 — blocking-stream correlation result](68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md)
- [69 — clock-correlated socket-trace experiment](69-nova-ahb-clock-correlated-socket-trace-experiment-2026-08-09.md)
- [70 — clock-correlated socket-trace result](70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md)
- [71 — continuous-repaint fix](71-nova-ahb-continuous-repaint-fix-2026-08-09.md)
- [72 — Gamescope present-cadence experiment](72-nova-gamescope-present-cadence-experiment-2026-08-09.md)
