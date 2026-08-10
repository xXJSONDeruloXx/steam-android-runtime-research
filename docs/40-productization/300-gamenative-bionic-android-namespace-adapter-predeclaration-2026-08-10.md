# GameNative Bionic Android-namespace adapter predeclaration — 2026-08-10

## Goal

Repeat the Geometry Wars GameNative Proton 11 ARM64EC test with one changed
variable: provide the Bionic process with an Android system-library namespace
while still giving Wine a non-root UID and a writable, run-scoped prefix.

The preceding direct control proved that `/system/bin/linker64` and the
official Bionic imagefs can start Wine, but Android's shell linker namespace
would not load imagefs libraries from `/data/local/tmp`. Wine also rejects a
root-owned prefix when run as root. This adapter is intended to isolate those
two boundaries without changing Proton, DXVK, the Nova ICD, the WSI layer, or
the game.

## Hypothesis

Inside a private mount namespace:

1. bind Android `/system`, `/vendor`, `/apex`, `/product`, `/odm`, and
   `/linkerconfig` into the existing Nova rootfs;
2. bind Android `/dev` and `/proc` into the same rootfs;
3. use the rootfs glibc `setpriv` only as a launcher helper to drop to UID/GID
   2000 before executing the Android `/system/bin/linker64`; and
4. run the Bionic Wine payload with chroot-relative paths, `DISPLAY=:0`, the
   GameNative preload chain, and a fresh copy of the signed-in AppID 8400
   prefix.

The Bionic executable and its libraries remain the GameNative artifacts. The
chroot is path plumbing for the Android system tree and X11 socket, not a
replacement glibc runtime. The first gate remains `wine --version`; only a
passing gate may launch Geometry Wars.

## Run identity and provenance

- Predeclared run ID:
  `nova-game-gamenative-bionic-android-namespace-adapter-20260810T133100Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Persistent rootfs (input only): `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Fresh parent: one-click LauncherActivity, hardware acceleration enabled,
  CEF GPU enabled, software GL forced for Steam CEF, split CEF environment
- Display: fresh Termux:X11 `:0`, Android `1280x960`, stretched X11 `1280x800`
- GameNative source revision:
  `4c3269c63851849fbe16e462733494755ce47524`
- WinNative source revision:
  `89daef3bc5693762868b2254054b47f4cdf27edf`
- GameNative Proton Wine revision:
  `147d88ee0c4eee8b356110dd0c53cc44b7515f73`
- Proton WCP SHA-256:
  `be248bf8baf354c4426f997605c6b78debbc93b091a3be3339c1bbc2176b596f`
- Bionic imagefs SHA-256:
  `368db62bfc58b72c97e5169bda9aa64d4246f07964c447e27c79a065e7e9c48b`
- `libredirect-bionic.so` SHA-256:
  `a6a0ee59bac93112f84bf75994def7607a278e8cb011a6e23414cb0107abc2cd`
- Known-good WSI layer SHA-256:
  `895a6dc9dc63e5778c0171fc56cdcb7e565a0f99c137c137073cb5ce8693b24a`
- WSI manifest SHA-256:
  `31758fb210e73e1ecd7460c9ec413e8eab6a7281b0ba847cd351af79f17f742a`

The preceding boundary result is recorded in
[`docs/40-productization/299-nova-gamenative-bionic-direct-namespace-result-2026-08-10.md`](299-nova-gamenative-bionic-direct-namespace-result-2026-08-10.md).

## Staging and process contract

All archive extraction, WCP files, imagefs contents, WSI artifacts, wrapper,
ICD, and prefix copy will live under:

```text
/data/local/tmp/nova-holo-rootfs/tmp/<run-id>/
```

The persistent prefix will be copied to the run directory and chowned to UID
2000. The persistent AppID 8400 prefix will not be chowned or used as the
write target. The adapter's private mount namespace will disappear at process
exit, and the run directory will be removed after evidence capture.

The adapter will invoke the Android linker only after the glibc `setpriv`
helper has dropped privileges:

```text
/system/bin/chroot <rootfs> \
  /usr/bin/setpriv --reuid=2000 --regid=2000 --groups=2000 \
  /usr/bin/env -i <GameNative Bionic environment> \
/system/bin/linker64 <WCP>/bin/wine ...
```

## Harness correction before the smoke gate

The first staged smoke invocation entered the adapter namespace and reached its
declared environment, but returned status `127` because the chroot did not
contain the target of Android's `/system/bin/linker64` symlink. A namespace
inspection showed that `/system/bin/linker64` resolves to
`/apex/com.android.runtime/bin/linker64`; a plain bind of `/apex` does not
carry Android's separately mounted nested APEX filesystems into the chroot.

The adapter was corrected to bind `/apex/com.android.runtime` explicitly after
binding `/apex`. An isolated check of that mount shape then executed
`/system/bin/linker64 --help` successfully inside the chroot. This changes only
the namespace plumbing; Proton, the imagefs, WSI layer, ICD, prefix copy, and
game remain fixed for the declared control. The failed smoke output is retained
as `bionic-adapter-smoke-pre-apex.txt` in the run evidence.

The Bionic environment will use `/system/lib64`, the extracted imagefs and
WCP libraries, the explicit X11 socket at `/tmp/.X11-unix/X0`,
`HODLL=libwow64fex.dll`, and the run-scoped WSI layer. No Nova Gamescope or
ICD source changes are part of this control.

## Acceptance and classification

Capture:

- fresh parent readiness and native WSI/Vulkan probe;
- exact bind/namespace and privilege-drop output;
- Bionic smoke status/output;
- Wine, DXVK, Vulkan, FEX, and Geometry Wars process/log evidence;
- screen checksums before and after the game attempt;
- persistent-prefix hashes before and after, plus run-copy ownership;
- exact launcher/X11/runtime cleanup markers; and
- absence of the run directory and temporary staging after teardown.

Classify the outcome as one of:

- **adapter reached Bionic Wine and Geometry Wars rendering**;
- **adapter reached Wine but failed in FEX/Proton or prefix setup**;
- **adapter reached DXVK but failed in Vulkan/WSI**; or
- **adapter failed before Bionic Wine**, with the first failing mount, linker,
  or privilege boundary.
