# Nova GameNative Bionic Android-namespace adapter result — 2026-08-10

## Result

The private mount adapter corrected the first Android linker namespace defect,
but it still failed before Bionic Wine. After `/apex/com.android.runtime` was
bound explicitly, the adapter could execute Android's
`/system/bin/linker64` and validate the linker path. The loader then rejected
the run-scoped GameNative imagefs preload library:

```text
CANNOT LINK EXECUTABLE "<run>/gamenative-proton/bin/wine": library "<run>/imagefs/usr/lib/libandroid-sysvshm.so" not found: needed by main executable
```

The file was staged from the official Bionic imagefs; this `not found` is the
Android linker namespace boundary, not evidence that the archive lacked the
library. The adapter did not reach `wine-11.0`, FEX, Proton, DXVK, Vulkan
device creation, or Geometry Wars. No game-rendering verdict is assigned.

This closes the root/chroot adapter as the next unblocker. GameNative's
application-private process model remains the higher-value control because it
starts the Bionic payload from the Android app process and its linker
namespace, rather than trying to reproduce that namespace from a root-side
chroot.

## Run identity and provenance

- Run ID:
  `nova-game-gamenative-bionic-android-namespace-adapter-20260810T133100Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Persistent rootfs (input only): `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Fresh parent: one-click LauncherActivity, hardware acceleration enabled,
  CEF GPU enabled, software GL forced for Steam CEF, split CEF environment
- Display: Termux:X11 `:0`, Android `1280x960`, stretched X11 `1280x800`
- Adapter source commit at the final validation:
  `ec1eda6` (`test: validate Bionic linker namespace paths`)
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
- WSI layer SHA-256:
  `895a6dc9dc63e5778c0171fc56cdcb7e565a0f99c137c137073cb5ce8693b24a`
- WSI manifest SHA-256:
  `31758fb210e73e1ecd7460c9ec413e8eab6a7281b0ba847cd351af79f17f742a`

The run was predeclared in
[`docs/300-gamenative-bionic-android-namespace-adapter-predeclaration-2026-08-10.md`](300-gamenative-bionic-android-namespace-adapter-predeclaration-2026-08-10.md).

## Namespace correction and smoke gate

The first adapter attempt failed because Android's
`/system/bin/linker64` symlink targets the separately mounted
`/apex/com.android.runtime/bin/linker64`. Binding only the top-level `/apex`
directory did not expose that nested APEX filesystem. The adapter then bound
`/apex/com.android.runtime` explicitly. Its path check passed:

```text
-rwxr-xr-x ... /apex/com.android.runtime/bin/linker64
lrwxr-xr-x ... /system/bin/linker64 -> /apex/com.android.runtime/bin/linker64
gamenative_bionic_adapter=pass mode=smoke run_id=nova-game-gamenative-bionic-android-namespace-adapter-20260810T133100Z
```

The final smoke status was `1`, with the first runtime failure being the
Android linker rejection of the imagefs `libandroid-sysvshm.so` path. The
adapter therefore did not pass its Bionic Wine gate.

Evidence:

- Smoke output:
  `android/nova-lab/build/runs/nova-game-gamenative-bionic-android-namespace-adapter-20260810T133100Z/bionic-adapter-smoke.txt`
- Smoke output SHA-256:
  `49bde86443c089bc57a3d52818449e874f3a18210f2e781a70ed66a6b7d0fe77`
- Pre-APEX failure is retained as
  `bionic-adapter-smoke-pre-apex.txt` in the same run directory.
- Adapter source:
  [`android/nova-lab/device/nova-gamenative-bionic-geometry-wars-android-namespace.sh`](../android/nova-lab/device/nova-gamenative-bionic-geometry-wars-android-namespace.sh)

## Fresh display and Vulkan control

The parent session reached fresh readiness, and the native probe ran while
that same parent/X11 session was live. The probe returned status `0` and
reported Turnip Adreno 740, Xlib/XCB surface extensions, and the WSI layer's
device-side `VK_KHR_swapchain` bridge. It also repeated the lower-level Nova
ICD limitation:

```text
vkCreateDevice extension VK_KHR_swapchain not available for devices associated with ICD /opt/nova-kgsl-driver/libvulkan_freedreno.so
```

This is not a claim that the ICD-side swapchain problem is fixed. It confirms
that the display/WSI control was available before the Bionic linker failure.

Evidence:

- Native probe:
  `android/nova-lab/build/runs/nova-game-gamenative-bionic-android-namespace-adapter-20260810T133100Z/native-probe.txt`
- Native probe SHA-256:
  `bdc8481a17564f99101216a0e9a40ef837d99078857ac48f53f65a94746aba87`
- Native probe status: `0`
- Parent screen SHA-256:
  `2d6ac91175a2cfb16b3cda0b3b614e313320f4efd1e3428a87cc99594eb0b0f1`

## Prefix and cleanup evidence

The persistent AppID 8400 prefix was not used as the adapter write target. Its
captured registry hashes remained the known values:

```text
system.reg  5a7fba0513db2c05776d5b3de08140d2a897ca711842b74dbb475e6ad47ffa22
user.reg    1943c8d9f5b2da5e4bd9ef016c1c49f62d110a3882c67b94af60adcaa209217a
userdef.reg a2e53741b4af39b5371308fb9ab998988cbdd0ed69b377dc29c89d1a6cfa791e
```

There were no Wine, DXVK, Vulkan, FEX, or Geometry Wars processes after the
failed smoke. The parent teardown returned:

```text
nova_launcher_x11_stretch_restore=pass
nova_launcher_stop=pass
```

The exact run directory under
`/data/local/tmp/nova-holo-rootfs/tmp/` was removed, and the final exact
process audit found no matching Nova rootfs, Steam, Gamescope, or launcher
process. No persistent prefix or top-level Nova staging input was modified.

## Decision and next control

Do not spend another iteration adding root/chroot binds or moving the same
preload paths around. The adapter has demonstrated that a root-created mount
namespace is not equivalent to the app-private Android linker namespace that
GameNative uses.

The next experiment will add a bounded APK-side helper to the Nova lab. It will
stage the same signed-in prefix copy, official GameNative Proton WCP, Bionic
imagefs, and WSI artifacts under the APK's private files directory, then start
`/system/bin/linker64` through the app process. The parent Steam/X11 session,
Proton, driver, and WSI layer will remain fixed. A passing `wine --version`
will be required before attempting Geometry Wars.

The private GameNative `libkgslshim.so` remains excluded: its source is
withheld and its official loader is package-guarded for `app.gamenative`; it
is not a generic Nova swapchain fix.
