# Retroid Pocket Nova rooted bridge smoke test

Test date: 2026-08-07
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno
ADB serial: `675a2365`

This is the first executable Android-side milestone from the roadmap. It intentionally
does not contain Steam or a Linux distribution. It tests whether a rooted Android app
can own a display surface while a privileged helper can enter a controlled Linux-style
process/filesystem boundary.

## Device and root state

The final direct probe was run with the checked-in asset from
`android/nova-lab/src/main/assets/root-probe.sh` through:

```text
adb shell "su -c '/system/bin/sh /data/local/tmp/nova-lab-root-probe.sh ...'"
```

Observed values:

```text
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
selinux=Permissive
fingerprint=qti/kalama/kalama:13/TKQ1.231222.001/eng.RPN.20260722.081626:user/release-keys
kernel=5.15.123-android13-8-g697b78910a71-dirty
```

The active Magisk daemon is 30.7 (`30700`). The Magisk database currently has explicit
policy rows for the ADB shell and the lab package; its global/default policy was not
changed. A future development-only switch to grant every app would remove this safety
boundary and is intentionally not part of the repository experiment.

## Results

| Contract | Result | Evidence |
|---|---|---|
| Root helper | Pass | `uid=0`, Magisk SELinux context |
| Mount namespace | Pass | `/system/bin/unshare -m` completed |
| Android/bionic chroot | Pass | `chroot.exec=ok`, `chroot.proc=ok`, UID 0 |
| Linux device visibility | Pass | `/dev/dri/card0`, `/dev/dri/renderD128`, `/dev/kgsl-3d0`, and `/dev/uinput` reported `rw` |
| Kernel interfaces | Pass | `/sys/class/kgsl`, `/proc`, and `/sys` were visible to the root probe |
| App-owned Surface | Pass | `120/120` Canvas frames posted at approximately `53.3 fps` |
| Android HardwareBuffer allocation | Pass | 64x64 RGBA8888 buffer created with CPU-write, GPU-sampled-image, and composer-overlay usage (`0x930`) |
| Visual presentation | Pass | Final device screenshot showed the purple `Nova Surface frame 120/120` buffer |

The app was built with the host Android command-line tools (`android-35`, Build Tools
35.0.1), signed with a persistent local debug key, installed on the Nova, and launched
from `android/nova-lab/deploy-and-test.sh`. Generated APK, logcat, report, and screenshot
files remain ignored under `android/nova-lab/build/`; the source harness and this result
are the durable evidence.

## What was learned while iterating

Several failures were useful boundary measurements rather than hidden:

- A nested `adb shell su -c` command initially executed the script as the ADB shell
  because the remote command was split at `&&`. The deploy script now passes one quoted
  command string and the report verifies UID 0.
- Nova's Toybox `mount` does not implement the util-linux `--make-rprivate` spelling.
  The helper now uses explicit bind mounts and an `EXIT` cleanup trap inside the private
  mount namespace.
- A top-level `/apex` bind does not include the runtime APEX submount. The chroot helper
  explicitly binds `/apex/com.android.runtime`, `/proc`, and `/linkerconfig`; Android's
  bionic `/system/bin/sh` then executes inside the chroot.
- `HardwareBuffer.getId()` is not present on the Nova's Android 13 framework despite
  compiling against the newer host SDK. The app reports API-33-compatible dimensions,
  format, and usage instead.
- The first SurfaceView run posted buffers but captured black. Setting the SurfaceView
  above the app window and requesting RGBA8888 produced the visible final frame.

The disposable mount tests were explicitly unmounted after the failed command. The
system partitions were read-only throughout; no system file or boot image was changed by
this experiment.

## Boundary of the proof

This does **not** yet prove that a Linux Steam session can run. The chroot currently
executes Android's bionic shell, not a glibc ARM64 rootfs. The app's Canvas/Surface and
Java HardwareBuffer checks also do not prove that a Linux compositor can export frames,
use release fences, or present through SurfaceControl. There is no gamescope, Wayland,
Xwayland, Vulkan-loader-in-chroot, SteamRT3C, or native Steam client in this milestone.

## Next experiment

The next high-value step is to stage one fixed Holo ARM64 rootfs snapshot under an
app-owned directory, bind it through the same root supervisor, and run a tiny glibc
ARM64 ELF plus a Vulkan-loader/device probe. That will answer whether Android's rooted
chroot boundary is sufficient for the Linux userspace ABI before any Steam download or
gamescope integration. The Holo snapshot and Valve ARM64 endpoints are already recorded
in [the current ARM64 research](05-current-arm64-steam-research.md); binaries should be
fetched at test time and not committed here.
