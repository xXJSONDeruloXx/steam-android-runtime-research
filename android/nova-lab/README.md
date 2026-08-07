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
- `device-screenshot.png`: a visual check that the SurfaceView received posted frames.

The fixed ARM64 glibc rootfs, KGSL Turnip probe, Android image-memory handoff, and
one-frame SurfaceControl presentation with a transferred acquire fence are now
automated by the scripts below. The next acceptance target is a reusable
double-buffered loop with asynchronous acquire/release synchronization.

## Holo ARM64 glibc probe

The next-stage scripts keep the rootfs and downloaded packages under the ignored
`build/` directory, then push only disposable copies to `/data/local/tmp`:

```sh
android/nova-lab/fetch-holo-rootfs.sh
android/nova-lab/install-holo-packages.sh
android/nova-lab/build-kgsl-turnip.sh
android/nova-lab/deploy-kgsl-turnip.sh
android/nova-lab/build-vulkan-offscreen-probe.sh
android/nova-lab/deploy-vulkan-offscreen-probe.sh
android/nova-lab/deploy-holo-probe.sh
android/nova-lab/deploy-ahb-bridge-test.sh
```

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
implement a reusable compositor queue, Android release-fence return, Wayland, or
gamescope.
