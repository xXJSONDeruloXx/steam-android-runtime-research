# Nova Proton 11 ARM64 Peggle Deluxe experiment — 2026-08-10

Status: completed; device result recorded below.

## Question

Geometry Wars reached Proton 11 ARM64, FEX, Wine, and Direct3D 9 but crashed
before producing a frame. Peggle Deluxe is a much smaller, older 2D Windows
game in the same signed-in library. It is a useful control for determining
whether the failure is general to this 32-bit FEX path or specific to Geometry
Wars' executable/startup behavior.

This experiment will ask the signed-in Steam client to install AppID `3480`
through `steam://install/3480`, then run `Peggle.exe` through the retained
Proton 11.0 (ARM64) wrapper. The download is an intentional device-state
change for the requested small-game comparison; no existing game, prefix,
account, or shader-cache data will be removed.

## Run identity

Run ID: `proton-arm64-20260810T041139Z-peggle-deluxe-install-and-launch`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `640b314`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Steam AppID `3480`, expected name `Peggle Deluxe`;
- expected executable `steamapps/common/Peggle Deluxe/Peggle.exe`;
- Proton package AppID `4628740`, Steam directory `Proton 11.0 (ARM64)`;
- Termux:X11 display geometry `1280x960` through the existing one-click APK.

This document was committed and pushed before requesting the download or
starting the bounded launch.

## Controlled variables

The run will retain the successful X11/Steam display path and the explicit
Proton 11 ARM64 wrapper:

1. install only AppID `3480` through Steam;
2. use a new AppID-3480 compatdata path, copying only the known-good Proton 11
   ARM64 198X prefix template if a default prefix again produces unusable
   relative kernel32 links;
3. add only the empty
   `HKLM\\Hardware\\Description\\System\\CentralProcessor\\0` section
   required by the earlier FEX startup boundary;
4. run `Peggle.exe` directly through `proton runinprefix` without
   `VK_ICD_FILENAMES`;
5. capture fresh readiness, process lifetime, Proton/Wine/FEX log, return
   status, and same-run screenshots.

## Acceptance and cleanup

Installation success requires a new Steam-owned `appmanifest_3480.acf`, the
expected executable, and recorded package size/hash evidence. Launch success
requires a real `Peggle.exe` process and a same-run frame that is not the
unchanged Steam UI; a Proton log alone is only a startup-boundary result.

Before and after the bounded run, use the exact Nova/X11 and rootfs cleanup
helpers. Final checks must show no matching Steam, Wine, FEX, Gamescope,
Termux:X11, relay, mount, or temporary socket. The installed Peggle files and
AppID-3480 compatdata will be retained for follow-up experiments; only
run-specific wrapper staging, generated launcher state, and direct logs are
disposable.

## Result

Installation succeeded through Steam's own download path. The device created
`steamapps/appmanifest_3480.acf` with build ID `10697`, a 267,808-byte download,
and a 19,463,282-byte installed depot. The downloaded `Peggle.exe` is a PE32
Intel 80386 binary. Recorded hashes are:

- `appmanifest_3480.acf`: `c1918bb4129557445517c1644ab776c238a465b37b929f89e0aedc0977857527`;
- `Peggle.exe`: `d37a37e305e468dc48fd88eeb4e1056a086881e1be14f66f3590c99a88c44d4c`;
- Proton log, 776,489 bytes: `2e950a3932381a3090fa11b442e12cef6b69b5a4de6e2f9a419fa814ad9a1a0f`;
- post-run 1280x960 screenshot: `fe9822678695f756afb299f9eb50ca970b5c86b591af0cfea5ed98a797d3415f`.

For the bounded launch, AppID 3480 used a copy of the already working Proton
11 ARM64 198X prefix. The source 198X prefix was not modified. The declared
empty CPU registry section was present, and the wrapper's kernel32 links again
resolved to the retained `proton-11-arm64` package.

The direct run used the fresh launcher namespace and returned status `0`:

```text
direct-run.sh 14670 14684 run
Proton: proton-11.0-1-beta5-unstripped
SteamGameId: 3480
direct_rc: 0
```

The zero wrapper return code is not a rendering success. The Proton log shows
`Peggle.exe` loading, builtin `kernel32.dll`, `libwow64fex.dll`, Wine X11,
DirectDraw, and wined3d. Vulkan physical-device enumeration again reported
`res -3`; wined3d selected `llvmpipe (LLVM 21.1.5, 128 bits)`. After FEX's
unaligned-atomic handling, Wine reported exception code `1` at address
`0x7500000000`, followed by `invalid frame` and `Exception frame is not in
stack limits`. The captured post-run screen remained the Steam UI and no
Peggle frame appeared.

Peggle therefore confirms the Geometry Wars result at the shared 32-bit
runtime boundary: two unrelated small PE32 games reach Proton, FEX, Wine's
X11 path, and wined3d/llvmpipe, but neither produces a game frame before the
same class of invalid exception-frame failure. This lowers the value of
trying more small 32-bit games until the next experiment isolates the FEX /
32-bit exception path or tests the launcher's Freedreno Vulkan ICD in a
separate bounded run. It does not justify returning to the
Gamescope-to-AHardwareBuffer path yet.

## Persistent device state after cleanup

The Proton 11 ARM64 wrapper remains at
`compatibilitytools.d/proton-11-arm64`, and Steam still maps AppID `1086010`
(198X) to `proton11_arm64`. The Peggle install and AppID-3480 compatdata are
retained for follow-up work; the 198X source prefix and account data were not
altered.

The exact X11 cleanup reported `nova_x11_cleanup=pass` and the rootfs cleanup
reported `nova_runtime_cleanup=pass`. No matching game, Wine, FEX, Steam,
Gamescope, X11, relay, or mount remained. The run-specific launcher state,
Peggle staging directory, direct log directory, and ADB CDP forward were
removed.
