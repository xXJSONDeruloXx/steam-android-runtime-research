# Nova Linux bridge lab

This is the first executable Android-side experiment for the rooted Retroid Pocket Nova.
It deliberately tests the two contracts that the future Steam session will depend on
without bundling Steam or a Linux distribution yet:

1. An ordinary Android app can continuously render to an app-owned `Surface` and ask
   Android for a `HardwareBuffer` with sampled-image/composer usage.
2. A Magisk-rooted helper can create a private mount namespace, enter a small chroot
   backed by Android's own `/system` and `/apex`, and see the GPU/input device nodes.

The chroot is an Android/bionic smoke test, not the eventual glibc rootfs. A passing
result means the privileged process boundary is viable; it does not prove that Holo,
SteamRT3C, gamescope, or Steam can run there.

## Build and deploy

The project intentionally uses the Android command-line tools directly so it does not
depend on Android Studio or a checked-in Gradle wrapper:

```sh
android/nova-lab/build.sh
android/nova-lab/deploy-and-test.sh
```

`deploy-and-test.sh` installs the debug APK, runs the root probe directly through
`adb shell su`, launches the app, captures filtered logcat, and saves a device
screenshot under `android/nova-lab/build/`.

The APK also has a **Run rooted probe** button. On first use, Magisk may ask for an
app-specific root grant. The launcher accepts `--ez run_root true` for automated runs.
The **Run native buffer** button calls a small NDK library that allocates an Android
`AHardwareBuffer`, writes a marker through the CPU lock API, sends its native handle
over an `AF_UNIX` socket, and reads the marker back from the received handle.
The automated deploy path passes `--ez run_native true` so the same probe runs without
manual UI interaction. The **Run Android Vulkan** button asks the system Vulkan driver
to import an `AHardwareBuffer` as a Vulkan image, clear it on the GPU, and verify the
pixel through the Android buffer lock API; the automated path passes
`--ez run_android_vulkan true` as well. The **Run Linux bridge** button starts a
private Unix-socket server, sends an `AHardwareBuffer` native handle to the Holo glibc
probe, waits for Linux Turnip to write the allocation and clear it as an image, then
presents that same buffer through an `ASurfaceControl` child of the app's `SurfaceView`.
Run the full cross-process check with:

```sh
android/nova-lab/deploy-ahb-bridge-test.sh
# Optional asynchronous acquire-fence ordering probe:
VULKAN_AHB_ASYNC_FENCE=1 android/nova-lab/deploy-ahb-bridge-test.sh
# Two persistent buffers with SurfaceControl release-fence backpressure:
android/nova-lab/deploy-ahb-double-buffer-test.sh
```

## Evidence to collect

The important output is:

- `root_probe_report.txt`: root identity, SELinux mode, namespace/chroot result, and
  access to `/dev/dri`, KGSL, `/dev/uinput`, and `/sys/class/kgsl`;
- `device-logcat.txt`: the app's Surface, Java HardwareBuffer, and native
  `AHardwareBuffer` handle round-trip results;
- `device-ahb-bridge-logcat.txt`: the cross-process handle transfer and Linux GPU
  write-back, SurfaceControl transaction, and fence result;
- `device-ahb-bridge-screenshot.png`: a visual check that the Linux-rendered blue
  image reached the Android surface;
- `device-ahb-double-buffer-logcat.txt` and `device-ahb-double-buffer-screenshot.png`:
  the five-frame acquire/release-fence loop and its clean visual result;
- `device-screenshot.png`: a visual check that the SurfaceView received posted frames.

The fixed ARM64 glibc rootfs, KGSL Turnip probe, Android image-memory handoff, and
one-frame SurfaceControl presentation with a transferred acquire fence and a
five-frame two-buffer acquire/release loop are now automated by the scripts below. The
next target is a compositor-facing render target and minimal Wayland/gamescope session.

## Holo ARM64 glibc probe

The next-stage scripts keep the rootfs and downloaded packages under the ignored
`build/` directory, then push only disposable copies to `/data/local/tmp`:

```sh
android/nova-lab/fetch-holo-rootfs.sh
android/nova-lab/install-holo-packages.sh
android/nova-lab/install-holo-gamescope.sh
android/nova-lab/build-kgsl-turnip.sh
android/nova-lab/deploy-kgsl-turnip.sh
android/nova-lab/build-vulkan-offscreen-probe.sh
android/nova-lab/deploy-vulkan-offscreen-probe.sh
android/nova-lab/deploy-holo-probe.sh
android/nova-lab/deploy-ahb-bridge-test.sh
android/nova-lab/deploy-ahb-double-buffer-test.sh
android/nova-lab/deploy-gamescope-control.sh
GAMESCOPE_SOURCE=/path/to/gamescope android/nova-lab/build-gamescope-headless.sh
NOVA_GAMESCOPE_INPUT_EMULATION=enabled android/nova-lab/build-gamescope-headless.sh
android/nova-lab/build-libei-key-probe.sh
android/nova-lab/build-wayland-shm-control.sh
android/nova-lab/deploy-gamescope-headless-test.sh
android/nova-lab/deploy-gamescope-headless-composite-test.sh
android/nova-lab/deploy-gamescope-headless-ahb-test.sh
android/nova-lab/deploy-native-steam-smoke-test.sh
android/nova-lab/deploy-native-steam-ui-smoke-test.sh
android/nova-lab/deploy-native-steam-input-smoke-test.sh
android/nova-lab/deploy-native-steam-hardware-probe.sh
android/nova-lab/build-uinput-gamepad-relay.sh
android/nova-lab/deploy-native-steam-gamepad-input-smoke-test.sh
android/nova-lab/deploy-native-steam-android-input-bridge-smoke-test.sh
android/nova-lab/deploy-native-steam-input-device-probe.sh
android/nova-lab/deploy-native-steam-input-fd-probe.sh
android/nova-lab/build-input-udev-probe.sh
android/nova-lab/build-sdl3-joystick-probe.sh
android/nova-lab/fetch-steam-arm64-seed.sh --all
NOVA_STEAM_UID=1000 NOVA_STEAM_GID=1000 android/nova-lab/deploy-steam-arm64-seed.sh
android/nova-lab/build-posix-sync-probe.sh
android/nova-lab/deploy-posix-sync-probe.sh
android/nova-lab/build-sysv-sem-shim.sh
android/nova-lab/build-ffmpeg-avutil-compat.sh
android/nova-lab/build-sdl3-compat.sh
```

The Steam seed and SteamRT archives are downloaded only into the ignored
`build/steam-arm64/` directory. `deploy-steam-arm64-seed.sh` can write a
reproducible `UID:GID` marker so the bounded client runs with `setpriv` under a
non-root user. The seed/bootstrap and current ABI boundary are documented in
`docs/14-nova-steam-arm64-seed-and-startup.md`. The native UI smoke wrapper in
`docs/15-nova-steam-ui-ahb-smoke.md` captures the pre-login Gamepad UI welcome
screen through the Android AHardwareBuffer path. The optional libei build and
`docs/16-nova-libei-input-smoke.md` now prove a keyboard scancode and protocol
round trip through Gamescope's `gamescope-0-ei` socket while that UI is running;
this is a compositor control seam, not yet Android gamepad/HID navigation. Login,
games, and hardware CEF rendering remain open. The separate hardware wrapper in
`docs/17-nova-steam-hardware-glx-probe.md` records the current negative result:
the native `msm` path reaches neither CEF nor a hosted frame before its GLX/SVE
boundary fails. The uinput relay in `docs/18-nova-uinput-gamepad-smoke.md` now
creates a Linux-visible virtual gamepad from the Nova's attached Xbox evdev node.
`deploy-native-steam-android-input-bridge-smoke-test.sh` adds the next seam:
the app enumerates Android controller devices, accepts a key event over an
abstract Unix socket, and the rooted ARM64 helper maps it into that virtual
device. The accepted evidence is documented in
`docs/19-nova-android-input-uinput-bridge.md`. Set
`NOVA_STEAM_ANDROID_INPUT_MODE=physical` to inject a controlled rooted evdev
event and assert that Android dispatches it as a controller-class `KeyEvent`;
that checkpoint is documented in `docs/20-nova-physical-controller-dispatch.md`.
Steam device consumption, navigation, axes, and rumble are still open. For
the lower-level discovery prerequisite, `deploy-native-steam-input-device-probe.sh`
creates the same virtual node, enumerates it through Holo `libudev`, and opens it
as uid 501; see `docs/21-nova-input-udev-device-visibility.md`. For
the direct Valve SDL3 check, add `NOVA_INPUT_SDL3_PROBE=1` (and usually
`NOVA_INPUT_UDEV_MODE=enabled`) to the same command. For
the process-level Steam check, `deploy-native-steam-input-fd-probe.sh` runs the
native gamepad smoke and observes the rooted process FD table for the exact
virtual event node; see `docs/22-nova-steam-input-process-fd.md`. For
the combined live-session event check, `deploy-native-steam-controller-ui-input-smoke-test.sh`
injects one physical `BTN_SOUTH`, verifies the relay's exact event marker,
and compares the Steam UI navigation region before and after; see
`docs/23-nova-steam-controller-ui-input.md`. Its default long profile keeps
the visible AHardwareBuffer UI alive long enough to distinguish the animated
localized greeting from actual selector navigation. Set
`NOVA_CONTROLLER_UI_EVENT_CODE=545` and
`NOVA_CONTROLLER_UI_EVENT_NAME=BTN_DPAD_DOWN` to probe a semantic D-pad
action; set `NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1` to make unchanged
navigation an assertion failure. The negative D-pad result is documented in
`docs/24-nova-steam-dpad-input.md`. Set
`NOVA_CONTROLLER_UI_INPUT_MODE=android-keyevent` to drive the same comparison
through the app's abstract input socket; this mode defaults to
`KEYCODE_DPAD_DOWN`, maps it to Linux code 545, and enables key-only isolation.
Its transport-passing/UI-negative result is documented in
`docs/25-nova-android-input-steam-ui.md`. For
the direct SDL3 event boundary, set `NOVA_INPUT_SDL3_PROBE=1` and
`NOVA_SDL3_EVENT_PROBE=1` (usually with `NOVA_INPUT_UDEV_MODE=enabled`) to
inject one exact `BTN_DPAD_DOWN` event and require SDL3 to receive a joystick
event from the matching virtual instance; see
`docs/26-nova-sdl3-event-input.md`. The first name-based result is retained
there as a target-selection pitfall. For the accepted semantic Gamepad API
check, set `NOVA_SDL3_GAMEPAD_EVENT_PROBE=1`; the harness passes the exact
relay-created event path, expects the Xbox 360 mapping, and requires SDL3
button-down and button-up events for D-pad down. See
`docs/27-nova-sdl3-gamepad-event.md`. The follow-up live Steam UI wrapper now
passes an exact physical `BTN_DPAD_DOWN` through the same relay and observes a
changed Steam navigation panel; see `docs/28-nova-steam-dpad-navigation.md`.
The Android-keyevent variant now also passes through the app socket and changes
the panel; see `docs/29-nova-android-input-steam-ui-navigation.md`. The
Android bridge clears stale Activity/socket state, consumes forwarded events,
and normalizes an up-only Android key delivery by synthesizing the missing
press. Additional button/axis mappings remain open. The corrected ABXY semantic
mapping and the Android-visible virtual-device feedback-loop filter are a
transport checkpoint for `KEYCODE_BUTTON_A`/`BTN_SOUTH`; A-button UI navigation
remains open. See `docs/30-nova-android-a-button-navigation.md`. The current
map is `96->304` (A/SOUTH), `97->305` (B/EAST), `98->306` (C), `99->307`
(X/NORTH), and `100->308` (Y/WEST). The app deliberately ignores events from
the `Nova Virtual Xbox Controller` identity after the rooted helper creates it,
so the app does not feed its own uinput output back into the socket.
For loader-only diagnostics,
`NOVA_STEAM_EXECUTABLE` can point at another ARM64 entry point, such as
`steamwebhelper`, and `NOVA_STEAM_CLIENT_FLAGS` supplies its bounded arguments.

`deploy-holo-probe.sh` returns the Vulkan probe status but always pulls its report,
including expected failures. Set `VULKAN_LOADER_DEBUG=all` for loader diagnostics or
`VULKAN_NODEVICE_SELECT=1` to disable Mesa's implicit device-select layer. The result
and the current KGSL/DRM and DMA-BUF boundaries are documented in
`docs/08-nova-holo-glibc-vulkan-probe.md`. The offscreen probe now exports a Vulkan
allocation as `VK_EXT_external_memory_dma_buf`, imports that FD into a second Vulkan
allocation, and verifies the GPU-written value survives the handoff. The bridge
script extends that result across the Android/Holo process boundary and submits the
verified buffer through SurfaceControl. With `VULKAN_AHB_ASYNC_FENCE=1`, it exports the
final image's Linux acquire fence before waiting and lets SurfaceControl consume it;
the current run observed the fence as unsignaled at Android handoff. It does not yet
implement a real compositor protocol, Wayland, or gamescope; the separate
`deploy-ahb-double-buffer-test.sh` now proves the reusable two-buffer and release-fence
queue contract.

To install the Holo `gamescope` package and run the stock DRM/auto-backend control:

```sh
android/nova-lab/deploy-gamescope-control.sh
```

The control is expected to return success only after reproducing
`physical device doesn't support VK_EXT_physical_device_drm` while `vulkaninfo` still
reports the Turnip Adreno 740. Set `INSTALL_HOLO_GAMESCOPE=0` for repeats after the
package closure is already installed. The report is saved as
`build/device-gamescope-control-report.txt`.

## Headless gamescope seam

The next experiment builds a disposable ARM64 gamescope checkout with
`patches/gamescope-headless-no-drm-identity.patch` and
`patches/gamescope-headless-composite.patch`, then launches the explicit non-session
headless backend inside the same Holo rootfs. It proves that gamescope can initialize
Turnip and synchronously composite a real Wayland surface without
`VK_EXT_physical_device_drm`.

Build and run it with:

```sh
GAMESCOPE_SOURCE=/path/to/gamescope \
  android/nova-lab/build-gamescope-headless.sh
android/nova-lab/build-wayland-shm-control.sh
INSTALL_HOLO_GAMESCOPE=0 \
  android/nova-lab/deploy-gamescope-headless-composite-test.sh
```

The deploy test stages only disposable copies below
`/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver` and saves
`build/device-gamescope-headless-composite-report.txt`. The control client is a
small ARM64 Wayland `wl_shm` program; it exists because the Holo Turnip ICD exposes
no `VK_KHR_surface`/Wayland/XCB surface extension for `vkcube`. The no-client
`deploy-gamescope-headless-test.sh` remains useful for startup-only checks. The
build scripts use ARM64 Debian Docker containers and do not modify the original
gamescope checkout.

The accepted Nova run produced 298 Wayland SHM frames and 298 synchronous
`headless_composite_frame` submissions. The output is still held in Gamescope's
three exportable Vulkan images. The
`deploy-gamescope-headless-ahb-test.sh` iteration imports the existing Android
AHardwareBuffer pool at this connector seam, composites 60 frames by default
into the two-buffer queue, and checks the Linux acquire plus Android release
fences. Set `NOVA_AHB_FRAME_COUNT`, `NOVA_AHB_WIDTH`, and
`NOVA_AHB_HEIGHT` to repeat the same test at another bounded count or display
size; a 30-frame 960x540 run is accepted on the Nova. The control client keeps
the Wayland connection open briefly after the final frame so Android can return
the last release fence before Gamescope shuts down.
The details and exact evidence are in
`docs/12-nova-gamescope-ahb-output.md`.
