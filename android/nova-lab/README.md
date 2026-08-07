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

## Evidence to collect

The important output is:

- `root_probe_report.txt`: root identity, SELinux mode, namespace/chroot result, and
  access to `/dev/dri`, KGSL, `/dev/uinput`, and `/sys/class/kgsl`;
- `device-logcat.txt`: the app's Surface and HardwareBuffer result;
- `device-screenshot.png`: a visual check that the SurfaceView received posted frames.

The next experiment after this one is to stage a fixed ARM64 glibc rootfs (starting
with the Holo snapshot already documented in `docs/05-current-arm64-steam-research.md`)
and run a non-Steam ELF plus Vulkan loader probe through the same supervisor.
