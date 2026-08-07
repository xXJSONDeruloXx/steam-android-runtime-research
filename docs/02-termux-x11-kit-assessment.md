# Attached Termux:X11 Kit Assessment

## Provenance

Input archive:

```text
/tmp/codex-remote-attachments/019fdc7b-17d3-7ed3-951b-fc1ad62b46d1/E7EAEB8B-DD5F-40A7-80EA-4A1EB5FCDF5D/1-steam-arm64-termux-x11-kit.zip
```

SHA-256:

```text
c4e00d23ee834136614eee3ca33cd3aeb5ed8ea386a626f46db3965b2e3b70f8
```

The ZIP contains 12 small text/source files, 38,056 bytes uncompressed. It has no device logs, screenshots, benchmark output, or Steam runtime payloads. It also uses backslashes as archive path separators; extraction succeeded with a warning.

## What it is

The kit is a hardware-first launcher for a native ARM64 Linux Steam installation inside an Android-hosted Linux environment:

```text
Termux + Termux:X11 + PulseAudio
  -> proot-distro/chroot Debian, Ubuntu, or Arch ARM64 userspace
    -> native ARM64 Steam
      -> X11 desktop UI and steamwebhelper/CEF
```

The kit README explicitly says it is for normal Steam desktop mode and is not for:

- Gamescope.
- Steam Deck Big Picture mode.
- Android Wayland bridge projects.
- Software rendering fallbacks.

That makes it adjacent to the target, not an implementation of the target.

## What the kit actually contributes

### 1. Termux host setup

`host/termux-start-x11-pulse.sh` starts:

- Termux:X11 on `DISPLAY=127.0.0.1:5`.
- PulseAudio TCP on `tcp:127.0.0.1:4713`.
- A visible Android-side X11 window through the Termux:X11 app.

This is a practical display/audio host for quick experiments, but the Android user is still interacting with a separate Termux:X11 surface rather than a dedicated launcher APK surface.

### 2. Container-side environment normalization

`bin/steam-x11-env` sets:

- X11 rather than Wayland: `EGL_PLATFORM=x11`, `SDL_VIDEODRIVER=x11`, `XDG_SESSION_TYPE=x11`.
- Zink for Steam UI GL: `MESA_LOADER_DRIVER_OVERRIDE=zink`, `GALLIUM_DRIVER=zink`.
- A hardware Vulkan ICD through `VK_ICD_FILENAMES` and `VK_DRIVER_FILES`.
- `LIBGL_KOPPER_DISABLE=false` and `LIBGL_KOPPER_DRI2=true`.
- XRandR/Xinerama/XVidMode SDL paths disabled because Termux:X11 does not fully expose them.
- PulseAudio and runtime-directory settings.

This directly addresses the same class of failures seen in ARM64 Steam containers: Steam probing unsupported X11 features, changing the GL environment for `steamwebhelper`, and falling back to software or crashing.

### 3. Steam launcher

`bin/steam-x11-arm64`:

- Locates an existing `steamrtarm64/steam` binary.
- Refuses obvious software-renderer tokens by default.
- Creates a compatibility `steamrtarm32` symlink to the ARM64 runtime.
- Disables several portal and CEF sandbox paths.
- Forces CEF to X11 + ANGLE + Vulkan.
- Runs through `dbus-run-session`.

The launcher does not install or update Steam. The ARM64 Steam runtime must already exist in the container.

### 4. Child-process shim

`lib/steam-exec-env-shim.c` is the most interesting piece.

It is a glibc/Linux `LD_PRELOAD` library that hooks:

- `__libc_start_main`.
- `execve`.
- `posix_spawn`.

For `steamwebhelper` and Steam’s update UI it:

- Re-injects the hardware Mesa/Vulkan/X11 environment.
- Removes inherited software-rendering variables.
- Removes hostile Chromium GPU/Ozone flags.
- Adds ANGLE/Vulkan/X11 flags.
- Re-applies the preload library to child processes.

This is a focused answer to a real Steam-on-ARM-container problem: the parent Steam process can have a correct GPU environment while the CEF child loses it.

## What appears promising

The kit is valuable for a fast, low-level milestone:

> Can the native ARM64 Steam client and `steamwebhelper` render hardware-accelerated Steam UI inside an Android-hosted ARM64 Linux userspace?

It is simpler than the custom gamescope/SurfaceControl path because Termux:X11 provides the outer X11 display and PulseAudio provides audio. It is also likely easier to run without root than the Holo/chroot route.

It may be worth testing with:

```sh
steam-x11-doctor
steam-x11-arm64 -gamepadui
steam-x11-arm64 -bigpicture
```

Those arguments are not part of the supplied launcher’s default behavior; they are proposed experiments, not results from the archive.

## What it does not solve

### Not a Steam Deck session

The launcher targets normal desktop Steam. It does not provide:

- Gamescope.
- Steam Deck Gamepad UI as the default shell.
- Android `SurfaceControl` presentation.
- Android-to-Linux controller/input forwarding.
- A dedicated Android app lifecycle.
- Suspend/resume or process supervision at the product level.

### No independent runtime evidence

The ZIP includes instructions and implementation code, but no log proving that Steam reached login, rendered `steamwebhelper`, or stayed hardware accelerated on a specific device. The kit should therefore be classified as “implementation candidate / claimed path,” not “proven milestone.”

### Several assumptions are hardcoded or fragile

- It expects an already-installed `steamrtarm64/steam` binary.
- The default ICD path is Freedreno-specific.
- The ARM32-to-ARM64 symlink is a broad compatibility workaround.
- CEF sandbox and GPU sandbox protections are disabled.
- The launcher uses `pkill` against portal processes.
- Termux:X11’s TCP display is a useful bring-up surface but not the desired final Android presentation architecture.

## Relationship to earlier work

This kit overlaps with the Termux:X11 interim path in [steam-arm-findings](https://github.com/xXJSONDeruloXx/steam-arm-findings/blob/main/experiments/termux-x11-gamescope-20260615.md), but it is more focused on making normal ARM64 Steam/CEF stable under X11. The earlier work added Gamescope and reached visible `xmessage` output plus Steam updater progress; this kit does not add Gamescope, but its child-process shim may be a better starting point for Steam UI bring-up.

## Assessment

| Question | Assessment |
|---|---|
| Does it help prove native ARM64 Steam? | Yes, potentially; it removes several known X11/CEF environment problems. |
| Does it implement Linux containers on Android? | Only as a launcher layer; it assumes proot/chroot/container setup already exists. |
| Does it implement Steam Big Picture? | No. The README explicitly excludes it. |
| Does it implement Gamescope? | No. |
| Does it implement a dedicated Android app? | No; it depends on Termux and Termux:X11. |
| Is it worth testing? | Yes, as the fastest native ARM64 Steam UI bring-up experiment. |
| Is it the final architecture? | No. The final path still points toward the rooted ARM64 + gamescope + Android buffer bridge. |
