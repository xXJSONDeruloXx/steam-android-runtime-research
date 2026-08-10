# Open Questions and Next Experiments

## Harness hygiene checkpoint

The Nova loop previously allowed a stopped rootfs Steam/Gamescope tree to
survive into the next run, which could make stale Steam log lines look like
fresh readiness while the new Android Surface was gray. That methodology issue
is resolved by the exact-scope cleanup and artifact-provenance gate in
[doc 34](34-nova-runtime-harness-lifecycle.md). Keep its zero-residual-process
check mandatory when adding new long-lived experiments.

## Phase 0: verify the live ARM64 sources

The native client is now directly observable rather than inferred from a repackaged kit:

1. Fetch the [Valve ARM64 Steam client manifest](https://client-update.steamstatic.com/steam_client_steamdeck_publicbeta_linuxarm64) and record the HTTP status, manifest revision, and resolved `bins_linuxarm64_linuxarm64` payload.
2. Fetch the [SteamRT3C ARM64 preview pointer](https://repo.steampowered.com/steamrt3c/images/latest-public-beta.txt) and record the runtime snapshot.
3. Use the [Holo ARM64 package channel](https://holo-packages.steamos.cloud/holo-core-aarch64-preview/) to confirm the target package set includes gamescope, Mesa/Turnip, Wayland, PipeWire, and the glibc/kernel baseline.
4. Keep the exact date and revisions in the evidence log; Valve's client channel and the community images are moving targets.

## Phase 1: prove the native session on supported hardware

Use [Armada](https://github.com/armada-os/armada) or [PockNix](https://github.com/shuuri-labs/pocknix-os)
on a supported Snapdragon handheld if one is available. This is a Linux-image/bootloader test, not the
Android-app milestone, but it answers whether the current ARM64 Steam client can reach login/Gamepad UI
under gamescope with the required kernel, input, audio, and device graphics stack.

Capture:

- exact image/repository commit and device/SoC;
- Steam first-run/login or Gamepad UI screenshot;
- gamescope/Steam/steamwebhelper logs;
- controller navigation and a launched game;
- suspend/resume and a clean session switch.

## Phase 2: test the attached kit

Use one known ARM64 Snapdragon/Adreno device and capture evidence rather than relying on the kit’s README claims.

1. Start Termux:X11 and PulseAudio.
2. Enter the same ARM64 Linux container used for Steam.
3. Run `steam-x11-doctor` and save:
   - `xdpyinfo`.
   - `glxinfo -B`.
   - `vulkaninfo --summary`.
   - PulseAudio status.
4. Run `steam-x11-arm64` and capture:
   - Steam stdout/stderr.
   - `steamwebhelper` process environment.
   - `STEAM_EXEC_SHIM_LOG` output.
   - A screenshot of the UI.
5. Try the native client with `-gamepadui` and `-bigpicture`.
6. Record whether login, library artwork, navigation, and controller input work.

The first result should be classified separately for:

- Steam process startup.
- `steamwebhelper` hardware rendering.
- Login UI.
- Gamepad UI.
- Controller input.

## Phase 3: put Gamescope around the working client

Before using the Android AHardwareBuffer backend, test the native ARM64 Steam client inside the Termux:X11 environment with patched gamescope.

Suggested order:

1. `xmessage` or another trivial X11 client.
2. A simple Vulkan client.
3. Normal Steam desktop mode.
4. `-gamepadui` or `-bigpicture`.

This will show whether the failure is in Steam, Gamescope WSI, Xwayland, or the Android display path.

## Phase 4: return to the native Android presentation path

Once Steam renders in the Linux/gamescope session:

- Replace Termux:X11 output with the persistent AHardwareBuffer pool; the Nova lab now
  proves the current three-buffer version of this contract, with the historical
  two-buffer baseline labeled in [doc 12](12-nova-gamescope-ahb-output.md).
- Carry the proven acquire/release-fence queue into the real Wayland/gamescope session.
- The stock Holo gamescope control reaches the KGSL Turnip Adreno device, then fails at
  `VK_EXT_physical_device_drm`. The explicit headless experiment now crosses that seam,
  accepts a real Wayland SHM surface, and completes Vulkan compositor submissions; the next
  step is to replace its internal output image with the persistent AHardwareBuffer integration.
- Forward Android controller and touch events into the gamescope/Wayland session.
- Keep gamescope alive independently of short-lived test children.
- Test Steam suspend/resume and clean shutdown.

## Acceptance criteria for the actual product direction

The target should not be considered proven until all of these work on one device:

1. Android app starts and stops the Linux session.
2. Native ARM64 Steam launches inside the managed Linux userspace.
3. `steamwebhelper` uses the hardware Vulkan path rather than llvmpipe/lavapipe.
4. Steam login UI appears.
5. Gamepad UI/Big Picture appears without a desktop mouse/keyboard workflow.
6. The confirmed physical controller path reaches Steam navigation; validate
   its game-level mapping and rumble once a launched game produces a frame.
7. Frames reach the Android display through the intended presentation path.
8. Suspend/resume and process cleanup work without stale sessions.

## Open technical questions

- Does the ARM64 Steam client reach login under the attached kit’s normal X11 path, and does `-gamepadui` work there? The Nova rootfs now launches the native client and `steamwebhelper`, reaches both SteamUI WebSocket `connection ready` markers, and visibly presents the pre-login Gamepad UI welcome screen; account login remains open.
- Does the client require additional Steam Deck environment/configuration outside Armada/PockNix?
- Does native ARM64 Steam still depend on SysV semaphore behavior missing from some Android kernels? Confirmed for this Nova kernel: the direct probe returns `ENOSYS`; a disposable POSIX-backed adapter lets Steam pass that startup path.
- Can the kit’s CEF environment shim be used unchanged inside the Holo rootfs?
- Partially answered: can the headless Gamescope seam sustain display-size Android
  AHardwareBuffer output for Steam’s actual frames? The Nova connector now completes a bounded
  120-frame 960x540 run with 120 acquire-fence handoffs, 120 SurfaceControl completions, and 119
  release-fence returns while the native Steam Gamepad UI is visibly present. The current Xwayland
  path falls back from glamor to software because GBM Wayland interfaces are absent, and CEF reports
  ANGLE/softpipe rather than hardware rendering. See [doc 15](15-nova-steam-ui-ahb-smoke.md).
- What input protocol is least invasive: Android HID injection, Wayland input, SDL, or a custom socket?
  The historical Nova experiments establish the available libei, uinput,
  Android dispatch, SDL, and Steam-consumer seams; see [docs 16](16-nova-libei-input-smoke.md),
  [18](18-nova-uinput-gamepad-smoke.md), [20](20-nova-physical-controller-dispatch.md),
  [27](27-nova-sdl3-gamepad-event.md), and [29](29-nova-android-input-steam-ui-navigation.md).
  The live physical controller is now confirmed working in the signed-in
  Termux:X11/Steam session. See [doc 298](298-nova-physical-controller-live-confirmation-2026-08-10.md).
  Controller transport and Steam UI navigation are therefore removed from the
  immediate blocker list. Keep only game-level mapping, rumble, hotplug, and
  alternate-renderer validation for later.
- Can Android touch drive the live Gamescope session, and can Steam remain visible in
  the app's fullscreen presentation? The Nova touch path now passes end to end: an
  Android `MotionEvent` reaches the app's abstract socket, the ARM64 libei helper,
  Gamescope's virtual touch device, and the compositor's received-event log. A
  synthetic fullscreen Gamescope frame is also visible edge to edge. With a 120-frame
  compositor run and a 30-second settle, the native Steam fullscreen run reaches
  SteamUI readiness and shows the language selector/welcome screen edge to edge under
  the strict Steam-surface gate; see [doc 31](31-nova-android-touch-libei-fullscreen.md).
- Are frames reaching the Android panel in monotonically increasing order at a
  stable display cadence? The current acquire/release-fence and latch metrics
  prove handoff and safe buffer reuse, but not visual ordering, repeats, drops,
  or vsync-locked pacing. Add the debug-only frame ID/timestamp trace described
  in [doc 12](12-nova-gamescope-ahb-output.md), correlate producer submit,
  Android latch/present, and release events, then act on the classification
  before treating the presentation path as temporally correct.
- Can the Nova expose hardware GLX/CEF for Steam? The bounded `msm` probe keeps
  Gamescope's Turnip/AHardwareBuffer side alive but Steam exits before CEF with
  `SIGILL`; an explicit `freedreno` Gallium profile instead fails at `drisw`
  initialization. See [doc 17](17-nova-steam-hardware-glx-probe.md).
- Why do some Steam OOBE language and network labels render as empty square or
  rectangle glyphs? The DOM contains the expected Unicode strings, while the
  live 1280x960 CEF surface renders Latin/Cyrillic/Greek and some accented
  Latin text but visibly substitutes missing glyphs for several CJK and other
  entries. This is recorded as a post-login font-coverage/fallback gate in
  [doc 33](33-nova-steam-font-coverage-open-question.md); first capture
  fontconfig and CDP font evidence before changing the current presentation
  path.
- Can a rooted Android app give a Linux userspace enough GPU/DMABUF/Surface access without booting a separate kernel?
- Does the Linux session use Android's already-active network data path without a second Wi-Fi/Ethernet
  registration step? `chroot`/PRoot should preserve the host network namespace by default, but the
  rooted `su` helper's UID may not inherit the app's process-bound or per-app VPN selection, and the
  glibc rootfs does not automatically receive Android bionic's `libnetd_client` socket/DNS hooks.
  Validate actual glibc socket selection, namespace identity, netd/UID behavior, DNS, IPv4/IPv6,
  reconnect, and VPN policy for both rooted and rootless launch modes. Steam's `System.Network` calls
  should remain a UI compatibility seam rather than become a requirement to emulate Android network
  hardware; see the [network contract in the roadmap](06-android-linux-gamescope-roadmap.md).
- For rootless mode, can an app-owned `Surface`/`ANativeWindow` replace the current privileged/low-level presentation path without a copy bottleneck?
- Which rootless process boundary works for glibc Steam: proot, a user namespace, Termux:X11, or a future Android-native launcher?
- Can FEX/Proton run with explicit wrappers and no host `binfmt_misc` or privileged helper?
- What Steam ARM64 package/update channel is legally and technically appropriate for distribution?

## Current recommendation

Do not build a large custom Android UI yet. The Nova lab has captured the
native client's child-process lifecycle, a signed-in Steam Gamepad UI session,
and the physical controller path is now confirmed working for the current
Termux:X11 route. Next focus the rooted Android app on the remaining
presentation/game, audio, network, and lifecycle gates. Revisit controller
behavior only as a game-level or alternate-renderer regression check.
