# Nova GameNative Proton ARM64EC control result — 2026-08-10

## Result

This was a valid display/WSI control but not a valid GameNative Wine render
attempt. The fresh native probe passed with the existing DMA-BUF/X11 WSI layer,
Turnip, and the one-click Termux:X11 session. The GameNative Proton WCP then
failed before Wine started because it is an Android/Bionic executable whose ELF
interpreter is `/system/bin/linker64`; the test launched it inside the Nova
glibc chroot, where that interpreter does not exist. The direct command
returned `127` from `timeout`, not from Geometry Wars, Wine, DXVK, or Vulkan.

This closes the incorrectly modeled “drop GameNative WCP into the current
glibc rootfs” variant. It does not close GameNative as a rendering route.
GameNative's own launcher source confirms the correct model: its Bionic
ARM64EC path runs Wine directly through Android's linker from the app process,
with Bionic imagefs libraries and `libandroid-sysvshm.so`; it does not chroot
that Wine payload into a glibc filesystem.

## Run identity and provenance

- Run ID: `nova-game-gamenative-proton-arm64ec-20260810T124702Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Game executable SHA-256:
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `7f94e8bc85717147c2c62b4438fae26a826d1132cbbec4e103c9ddad79b84229`
- Repository head at setup: `f12b9810dbcdb408733533f932628644ffe86393`
- Wrapper source commit before direct launch:
  `9f78632f5a6c3f2acbf76a57fd87b98c42450d0c`
- GameNative source: `4c3269c63851849fbe16e462733494755ce47524`
- WinNative source: `89daef3bc5693762868b2254054b47f4cdf27edf`
- GameNative Proton Wine source:
  `147d88ee0c4eee8b356110dd0c53cc44b7515f73`
- Display: Termux:X11 `:0`, Android `1280x960`, stretched X11 `1280x800`
- Native probe status: `0`
- Direct game status: `127`

The GameNative Proton WCP came from
`https://downloads.gamenative.app/proton-11.0-1-arm64ec.wcp`:

- Size: `276851384` bytes
- SHA-256:
  `be248bf8baf354c4426f997605c6b78debbc93b091a3be3339c1bbc2176b596f`
- Profile: Proton `11.0-1-arm64ec`, `binPath=bin`, `libPath=lib`,
  `prefixPack=prefixPack.txz`
- `bin/wine` resolves to `lib/wine/aarch64-unix/wine`
- Wine interpreter: `/system/bin/linker64`
- WCP Wine `bin/wineserver` SHA-256:
  `8e8908d219816d1b64d964bb7b78fea314870ec23fa88a9a201341a38ef2fc85`
- WCP `winex11.so` SHA-256:
  `07a75a5301b915e29d5d390ac697c00013ac781080b29fd48e3ad9981f3465b4`
- WCP `winevulkan.so` SHA-256:
  `3ff331d2e7a527991eb2b3e647a11515d021b010778e176e54b73ca58b698537`

The current glibc rootfs instead provides `/lib/ld-linux-aarch64.so.1`; it
does not contain `$ROOT/system/bin/linker64`. The WCP's `winex11.so` also
requires Bionic-side `libandroid-sysvshm.so`, `libX11.so`, and `libXext.so`,
which are not supplied by the current glibc rootfs.

## Native probe

The probe ran through the same private X11/dev namespace and used only the
run-scoped WSI layer and the existing Nova ICD. It reported:

```text
mount_private=pass path=/
x11_namespace_input=pass allowed_events=9 hidden_events=
VK_KHR_surface                         : extension revision 25
VK_KHR_xcb_surface                     : extension revision 1
VK_KHR_xlib_surface                    : extension revision 1
GPU id = 0 (Turnip Adreno (TM) 740)
Layer-Device Extensions: count = 2
    VK_KHR_swapchain  : extension revision 70
```

Evidence:

- Output:
  `android/nova-lab/build/runs/nova-game-gamenative-proton-arm64ec-20260810T124702Z/native-probe.txt`
- Output SHA-256:
  `2297832523b125c07bd694bc12f01c13cc3b06721029708d0bd3fbb989357147`
- WSI layer SHA-256:
  `895a6dc9dc63e5778c0171fc56cdcb7e565a0f99c137c137073cb5ce8693b24a`
- WSI manifest SHA-256:
  `31758fb210e73e1ecd7460c9ec413e8eab6a7281b0ba847cd351af79f17f742a`

## Direct GameNative launch boundary

The tracked wrapper was
`android/nova-lab/device/nova-gamenative-proton-geometry-wars.sh`, SHA-256
`696e58a835cb237522f36988029c780958a8f705a85c2157bfad863c2619ac5b`.
It staged the WCP at a run-scoped path and set the GameNative-relevant
variables:

```text
DISPLAY=:0
HODLL=libwow64fex.dll
WINE_X11FORCEGLX=1
WINE_NEW_NDIS=1
VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_IMPLICIT_LAYER_PATH=/tmp/<run-id>/wsi-stage
LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so
```

The namespace and wrapper reached the wrapper's own marker, then failed at
the Bionic interpreter boundary:

```text
gamenative_proton_runner=pass run_id=nova-game-gamenative-proton-arm64ec-20260810T124702Z
timeout: failed to run command '/tmp/<run-id>/gamenative-proton/bin/wine': No such file or directory
```

The “No such file” is the kernel's missing-interpreter result, not a missing
Wine symlink. The staged symlink and target were present and the target was
identified as an AArch64 Android 28 executable requesting
`/system/bin/linker64`.

Evidence:

- Command: `direct-command.txt`
- Output: `direct-game-output.txt`
- Output SHA-256:
  `c50301c8a42db78af4ee9fbd40bd86732b48cb75e4e6a2603add0fcb0eb2a442`
- Direct status: `127`
- No Wine, DXVK, Vulkan, or Geometry Wars process was created.

## Prefix protection and cleanup

The exact AppID-8400 files were backed up before the direct invocation:

```text
system.reg             5a7fba0513db2c05776d5b3de08140d2a897ca711842b74dbb475e6ad47ffa22
user.reg               1943c8d9f5b2da5e4bd9ef016c1c49f62d110a3882c67b94af60adcaa209217a
userdef.reg            a2e53741b4af39b5371308fb9ab998988cbdd0ed69b377dc29c89d1a6cfa791e
proton-fex-config.json b01e8e9373cb00e1b1c0d73738883c6b620eaa645d060c52573ea196d5f372d0
```

All four target hashes matched their backups after teardown. The one-click
launcher stop returned `nova_launcher_stop=pass`; its X11 and runtime cleanup
logs returned `nova_x11_cleanup=pass` and `nova_runtime_cleanup=pass`. The
final exact-scope process audit was empty, and the run-scoped WCP, layer,
wrapper, backups, and logs were removed from the device.

The same-run screen captures remained the signed-in Steam UI:

- Before SHA-256:
  `4121fdeafcd44f84ffc7708ac53f5dea308ebc540ddd6b2041669dc01d2b7b9f`
- After SHA-256:
  `e2fb7b276f71425865fd8514e19f7a4d3bb918bbdad770926837598331b3edb3`

Neither is a Geometry Wars frame.

## Decision and next step

Do not alter the current glibc rootfs to make this Bionic WCP appear
executable. The next GameNative-derived experiment must provide the same
Android/Bionic runtime boundary that GameNative uses: Android's linker,
Bionic X11 libraries, `libandroid-sysvshm.so`, and the Android-side Vulkan
driver/renderer integration. The current Steam glibc rootfs can remain the
host for the signed-in Steam client, but its glibc X11 libraries cannot be
substituted for GameNative's Bionic imagefs libraries.

The larger architecture remains clear from the inspected sources: GameNative
and WinNative keep X11 as a guest protocol endpoint and let their Android
renderer own the actual `VK_KHR_android_surface`/swapchain. That is the
credible route if obtaining the Bionic runtime boundary proves larger than
the current experiment.
