# Nova AHB continuous-repaint fix — 2026-08-09

Status: superseded by the exact-stack A/B on the attached Nova on 2026-08-09.
The global repaint trigger is rejected: the no-trigger artifact passes both
the 240-frame AHB-only boundary and the visible Steam/controller gate, while
the trigger-enabled artifact leaves the Android surface dark.

## Causal hypothesis

The clock-correlated run in [doc 70](70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md)
showed Android waiting with an empty ACK socket while Gamescope had not yet
entered the frame's `wait_release` path. The Gamescope source explains a
possible direct cause: `steamcompmgr` calls the headless connector only when
`bShouldPaint` is true, and the normal path requires `vblank && hasRepaint`.
An unchanged Steam/X11 scene can therefore stop calling `Present()` even
though the Android AHB consumer is synchronously waiting for the next ACK.

This is a scheduling starvation hypothesis, not evidence of a lost ACK or a
SurfaceControl release-fence failure.

## Behavioral change

The attempted change set `hasRepaint` on each vblank when
`NOVA_AHB_OUTPUT_SOCKET` was enabled. That made the AHB output act like a
continuously refreshed display, but it also forced the global compositor down
a path that produced a dark Android surface even while the same Steam scene
was visible in the upstream X11 window.

The change deliberately leaves these parts untouched:

- original `SOCK_STREAM` transport and blocking `recvmsg()`;
- three per-buffer sockets and modulo-3 ownership mapping;
- SurfaceControl transactions and release-fence handling;
- Gamescope's per-slot release wait and acquire-fence ACK handoff.

## Historical validation of the rejected hunk

- The updated patch applies after the existing headless, transport, clock,
  and input patches.
- The ARM64 Gamescope build completed successfully from source commit
  `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- The originally recorded build hash was
  `94c248a2b64afe6388da87a78dd697bd685cc845c87ca851eb024b81050d4397`.
  That artifact was not present in the current checkout, so the acceptance run
  rebuilt the exact current patch stack instead of treating that hash as
  interchangeable.
- The rejected trigger-enabled binary was built from the same source commit with
  libei enabled and has SHA-256
  `ed45595515e34e80ff10fd92d492d14d75f1f9cde8bf2aa224e835ada491aa7e`.

## Exact-stack device A/B

The guarded original stream was run with the current binary and APK under
run ID `manual-20260809T034401Z-repaintfix-150`, at 1280x960 fullscreen with
blocking ACK waits, socket tracing, Xwayland, software CEF settings, and the
normal provenance/cleanup gates. Its final markers were:

```text
ahb_double_buffer_frames=150 releases=149
ahb_double_buffer=pass
android_ahb_target_reached=150
headless_gamescope_ahb=pass
```

The same-run trace contains frame 149 release completion, compose, ACK send,
and the next target boundary; there was no move into
`wait_android_release()`. The first 240-frame attempt also reached
`android_ahb_target_reached=240`, but the APK's former 64 KiB native report
buffer truncated its app report around frame 156 before the final summary.
The report buffer is being enlarged in the test-bench APK so future 240-frame
acceptance runs fail closed without discarding their final producer result.

The exact-stack no-trigger artifact was built from the same Gamescope source
commit and all remaining headless/transport/clock/input patches. It has
Gamescope SHA-256
`fd86ba1d81f502d7ef05b17ef150193926e91008538185cccfe9473557aa7325`.

Its AHB-only run was `ahb-only-20260809T043714Z-no-vblank`:

```text
ahb_double_buffer_frames=240 releases=239
ahb_double_buffer=pass
android_ahb_composite_frame=240
android_ahb_target_reached=240
headless_gamescope_ahb=pass
```

Its full controller/UI run was
`controller-20260809T043310Z-no-vblank-reportfix`. It passed the fresh
Steam-surface gate, Android D-pad press/release forwarding, Steam input-FD
ownership, and navigation:

```text
controller_ui_surface=pass
controller_ui_steam_surface=pass
controller_ui_navigation=pass
controller_ui_android_input_bridge=pass
steam_input_fd_probe=pass
native_steam_controller_ui_input_smoke=pass
```

The trigger-enabled artifact (`ed45595515e34e80ff10fd92d492d14d75f1f9cde8bf2aa224e835ada491aa7e`) passed AHB transport but failed the same Android visual gate while X11 and fresh SteamUI logs were ready. The current patch therefore removes the trigger; the remaining open work is a true end-user login-screen and hardware-acceleration acceptance, not another global repaint retry.
