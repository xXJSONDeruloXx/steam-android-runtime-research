# Android app roadmap: Linux-first Steam Gamepad UI

## Target architecture

The Android app should be a control plane and presentation shell. Linux owns the Steam session:

```text
Android app
  ├─ lifecycle / permissions / storage / downloads
  ├─ root or rootless process supervisor
  ├─ controller + touch input bridge
  └─ Android Surface / AHardwareBuffer presentation
        │
        └── Linux userspace
              ├─ glibc ARM64 rootfs (Holo/Arch-compatible baseline)
              ├─ native ARM64 Steam client + SteamRT3C ARM64 runtime
              ├─ gamescope + Wayland/Xwayland
              ├─ PipeWire / session services
              └─ ARM Proton + FEX for x86 game content
```

The app should not recreate Steam's library, login, downloads, or Gamepad UI. Armada and PockNix show
that the Steam client already supplies the right primary UI when launched with the Deck session flags.

## Root is acceptable for the first milestone

There are two useful rooted proofs, and they answer different questions.

### A. Full Linux boot proof

Use Armada or PockNix on a supported Snapdragon handheld. This changes the boot path and gives Linux
ownership of the kernel, DRM/KMS, seat, input, audio, and power services. It is the fastest way to prove
the current ARM64 Steam + gamescope + Gamepad UI composition, but it is not yet an Android app.

Acceptance:

- Steam reaches first-run/login and Gamepad UI;
- gamescope presents the panel continuously;
- controller navigation and one game work;
- suspend/session switching/cleanup are understood.

### B. Android-managed rooted proof

Keep Android booted, use a root helper to mount or enter an app-owned glibc Linux rootfs, and launch the
native ARM64 Steam client from there. Use the existing Android-compatible gamescope presentation work
from `steam-arm-findings` rather than assuming Android exposes a normal DRM/KMS path.

The first Android milestone should be intentionally narrow:

1. Start one fixed rootfs and one fixed native ARM64 Steam client seed.
2. Start a persistent Linux supervisor and capture all logs to app storage.
3. Launch gamescope and Steam Gamepad UI with the Armada/PockNix flags.
4. Present frames through the tested AHardwareBuffer/Surface path.
5. Forward one controller class reliably.
6. Stop the session and clean every child process.

This is the right place to reuse GameNative's Android lifecycle/storage/controller patterns and the
existing `steam-arm-findings` graphics work. The first release can clearly say “root required” while the
Linux session is being stabilized.

## Rootless stages

Rootless should mean “the Android app no longer needs a privileged helper,” not “the app secretly owns a
Linux kernel.” Each stage removes one privilege boundary and keeps the previous stage as a fallback.

### Rootless stage 1: native ARM64 Steam under a user-owned Linux environment

Use the Valve ARM64 manifest/runtime and an app-owned glibc rootfs, then run the client through a user-space
boundary such as proot or a Termux-style launcher. Start with normal desktop/X11 or a user-owned nested
Wayland path. Validate:

- the native `steamrtarm64` client starts;
- `steamwebhelper` hardware rendering works;
- login and `-gamepadui` work;
- the app can persist the Steam home/library without root.

The attached Termux:X11 kit is useful here as a diagnostic/fallback, but it is not evidence of a
gamescope-backed Steam Deck session.

### Rootless stage 2: app-owned compositor surface

Replace the desktop display with an Android app-owned `Surface`/`ANativeWindow` or a proven equivalent. The
Nova lab now has a two-buffer AHardwareBuffer/SurfaceControl queue with acquire/release-fence
backpressure, [doc 12](12-nova-gamescope-ahb-output.md) connects that pool to the patched headless
Gamescope compositor for sustained 60-frame and 960x540 Wayland-SHM runs, and [doc 13](13-nova-xwayland-ahb-output.md)
crosses the same path with an animated ARM64 X11 client through Xwayland. The first acquire fence is
intentionally synchronous. The stock Holo gamescope control reaches the same KGSL Turnip device but is
blocked by its unconditional `VK_EXT_physical_device_drm` device-identity requirement; the narrow
patched headless path crosses that identity boundary.
If the existing AHardwareBuffer/SurfaceControl path relies on privileged APIs, use a buffer-copy or
producer/consumer path that the ordinary app sandbox permits. Measure frame latency, buffer reuse, release
fences, rotation, and lifecycle loss before optimizing.

The desired contract is:

```text
gamescope/Wayland frame
  -> Android-compatible producer
    -> app-owned Surface
      -> SurfaceView/TextureView/HardwareBuffer presentation
```

The Nova lab has now launched the native ARM64 Steam process through the same
Xwayland/Gamescope control and resolved the first semaphore, FFmpeg, SDL, X11
authorization, GTK2, NSS/NSPR, rootfs-DNS, runtime-directory, machine-id, and
SteamRT diagnostic-tool boundaries. The process starts `steamwebhelper`, reaches
both SteamUI WebSocket `connection ready` markers, and visibly renders the
pre-login Gamepad UI welcome screen into the Android AHardwareBuffer queue; see
[doc 15](15-nova-steam-ui-ahb-smoke.md). The stage is not complete until login,
controller input, a game, and clean lifecycle behavior work, and the current
CEF report still identifies software `softpipe` rendering. An optional libei
Gamescope build now accepts a keyboard scancode and completes the EIS protocol
round trip through `gamescope-0-ei`; [doc 16](16-nova-libei-input-smoke.md)
records the result. That proves a compositor-side control seam, not gamepad/HID
navigation, so Android event mapping remains required.
The separate hardware GLX probe keeps the same Gamescope/Turnip output alive,
but native Steam exits before `steamwebhelper` with `SIGILL` when Mesa's `msm`
path is selected; an explicit `freedreno` profile fails at `drisw` creation.
See [doc 17](17-nova-steam-hardware-glx-probe.md). Hardware CEF is therefore
still an open graphics gate, independent of the already-proven Vulkan output.

### Rootless stage 3: user-space Steam session supervision

Remove root-only system services one by one:

- explicit gamescope/FEX wrappers instead of host `binfmt_misc`;
- app-owned controller socket/HID/Wayland input injection instead of `/dev/uinput`;
- user-session PipeWire or Android audio bridge instead of system audio services;
- normal-priority scheduling first, then optional Android-supported performance hints;
- app-owned temporary directories and mounts instead of privileged bind mounts.

This stage may expose hard Android limitations. A rootless fallback that runs the native client in a
user-owned display is still useful even if the full DRM-backed gamescope path remains rooted or requires a
separate Linux boot.

### Rootless stage 4: x86 Windows games

Only after native Steam UI and presentation work should the app add FEX + ARM Proton for x86 game content.
Use explicit per-game wrappers, as Armada/PockNix do, and avoid making the Steam client itself depend on
FEX. Validate pressure-vessel/bwrap, user namespaces, file descriptors, shared memory, futex/semaphore
behavior, and controller handoff per game.

## Privilege boundary matrix

| Capability | Full Linux boot | Rooted Android app | Rootless Android app |
|---|---|---|---|
| ARM64 Steam process | Native | Native | Native, if proot/user-space loader works |
| Steam Gamepad UI | Proven by Armada/PockNix | Targeted MVP | Targeted after stage 1 |
| DRM/KMS gamescope backend | Natural | Usually unavailable unless Android/device exposes it | Not a safe assumption |
| Android Surface presentation | Separate bridge | Rooted bridge already explored | App-owned Surface/ANativeWindow or buffer-copy bridge |
| Controller `/dev/uinput` | System service | Root helper possible | App input/socket path required |
| Gamescope keyboard input | Native EIS/XTEST path | libei round trip proven | Android event mapping required |
| PipeWire/session services | Systemd/logind | Rootfs + Android bridge | User session only |
| FEX/Proton x86 games | System integration | Root helper can provide missing pieces | Explicit wrappers and user namespaces required |
| ABL/kernel/firmware ownership | Yes | Android kernel remains in control | Android kernel remains in control |

## Recommended implementation order

1. Freeze one known Snapdragon/Adreno target and record GPU, Android build, kernel, display orientation,
   controller, and audio capabilities.
2. Reproduce native ARM64 Steam + gamescope on Armada/PockNix or an equivalent full Linux boot.
3. Build a rooted Android app supervisor around a fixed Holo/Arch-compatible rootfs and the same Steam
   client bootstrap; finish the Bootstrapper HTTP/child-process lifecycle first.
4. Make the Android presentation bridge pass Steam login/Gamepad UI, then one game, then suspend/stop.
5. Move input/audio/scheduling from root services to app-compatible bridges.
6. Remove root for the Linux process/rootfs path.
7. Add FEX + Proton as a compatibility layer for x86 games and maintain a rooted fallback for devices that
   cannot expose the required graphics/input interfaces.

## Decision gates

Do not advance to the next stage until the current stage produces artifacts:

| Gate | Required evidence |
|---|---|
| Native client | ARM64 manifest/runtime revision, bootstrap logs, `steamui.so`, `.installed` manifest |
| Steam UI | Screenshot/video of login and Gamepad UI; `steamwebhelper` hardware-rendering logs |
| Linux session | gamescope logs, controller navigation, one launched game |
| Android presentation | continuous Steam UI/game frames on the app-owned surface, with frame/fence metrics |
| Lifecycle | clean start/stop, no stale Steam/gamescope processes, suspend/resume behavior |
| Rootless | same UI/session evidence without privileged helper; documented fallbacks for missing APIs |

## Important non-goals

- Do not begin by reverse-engineering the Android Steam libraries when the native ARM64 Linux client is
  directly available.
- Do not use FEX to launch the native ARM64 Steam client; reserve it for x86 game payloads.
- Do not assume Holo alone provides a bootable Snapdragon handheld image.
- Do not treat “gamescope starts” or “vkcube renders” as proof that Steam Gamepad UI works.
- Do not commit Valve runtime binaries or large OS images to the evidence repository; keep the repo as
  source notes, hashes, URLs, and reproducible procedures.
