# Nova Proton 11 ARM64 Geometry Wars experiment — 2026-08-10

Status: completed; device result recorded below.

## Question

The installed Steam library has only 198X as a Windows game. Geometry Wars:
Retro Evolved is present in the signed-in user's cached library history as
AppID `8400`, with the executable `GeometryWars.exe`, but its app manifest and
game directory are absent from the Nova. It is a useful small-game comparison:
the title is substantially simpler than 198X and may reach a frame even if
198X's Unity startup does not.

This experiment will ask the signed-in Steam client to install AppID `8400`
through Steam's own `steam://install/8400` route, then test the installed
executable with the Steam-downloaded Proton 11.0 (ARM64) package. The game
download is an intentional device-state change requested for this comparison;
no existing game, prefix, account, or shader-cache data will be removed.

## Run identity

Run ID: `proton-arm64-20260810T033239Z-geometry-wars-install-and-launch`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `5c2ee7d`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Steam AppID `8400`, expected name `Geometry Wars: Retro Evolved`;
- expected executable `steamapps/common/Geometry Wars/GeometryWars.exe`;
- Proton package AppID `4628740`, Steam directory `Proton 11.0 (ARM64)`;
- Termux:X11 display geometry `1280x960` through the existing one-click APK.

This document was committed and pushed before requesting the download or
changing the device's compatibility mapping.

## Controlled variables

The first game run will keep the successful Phase 8 prerequisite and change
only the game executable:

1. deploy the committed chroot-visible `proton11_arm64` wrapper around the
   Steam-owned Proton 11 ARM64 package;
2. create only the empty Wine key
   `HKLM\\Hardware\\Description\\System\\CentralProcessor\\0`, because
   Phase 8 proved that its absence aborts bundled FEX before the game loads;
3. run `GeometryWars.exe` directly through `proton runinprefix` using a fresh
   AppID-8400 compatdata path and run-specific Proton log directory;
4. do not set `VK_ICD_FILENAMES` in this first comparison, preserving the
   Phase 8 direct environment so a result is attributable to the game rather
   than to a simultaneous Vulkan-ICD change;
5. capture the fresh launcher readiness marker, process lifetime, Proton/Wine/
   FEX log, return status, and repeated same-run screenshots.

If Geometry Wars reaches the same Vulkan/llvmpipe boundary, the next separate
experiment may add the launcher's Freedreno ICD environment. If it reaches a
game frame, the result will establish a useful rendering baseline before that
ICD experiment. CPU-feature register values will not be invented in this run.

## Acceptance and cleanup

Installation success requires a new Steam-owned `appmanifest_8400.acf`, the
expected executable, and recorded package size/hash evidence. Launch success
requires a real `GeometryWars.exe` process and a same-run frame that is not
the unchanged Steam UI; a Proton log alone is only a startup-boundary result.

Before and after every bounded run, the exact Nova/X11 and rootfs cleanup
helpers will be used. The final checks must show no matching Steam, Wine, FEX,
Gamescope, Termux:X11, relay, mount, or rootfs temporary socket. The installed
Geometry Wars files and its AppID-8400 compatdata will be retained for follow-up
experiments. The wrapper is retained intentionally for the persistent 198X
Proton 11 ARM64 selection; only generated relay/state files and run-specific
log/staging artifacts are disposable.

## Result

Installation succeeded through Steam's own download path. The device created
`steamapps/appmanifest_8400.acf` with build ID `251921`, a 59,509,904-byte
download, and a 66,019,943-byte installed depot. The installed directory is
approximately 63 MB. The downloaded `GeometryWars.exe` is a PE32 x86 binary;
its recorded SHA-256 is
`457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`.

The first empty-prefix initialization timed out with Proton's bundled FEX
before creating a complete `syswow64` tree. A second attempt using Proton's
new default AppID-8400 prefix reached a relative `kernel32.dll` link that was
not usable from the copied compatdata location. For the final launch check,
AppID 8400 used a copy of the already working Proton 11 ARM64 198X prefix,
then received the empty CPU registry section declared above. The 198X source
prefix was not modified. This makes the final result a valid executable/runtime
comparison, but not a clean-prefix initialization result.

The final bounded direct launch used the fresh launcher namespace and:

```text
direct-run.sh 24737 24749 run
Proton: proton-11.0-1-beta5-unstripped
SteamGameId: 8400
return status: 240
```

This run passed the prior blocker layers. The Proton log records successful
loads of `GeometryWars.exe`, builtin `kernel32.dll`, `d3d9.dll`, `wined3d.dll`,
the native `d3dx9_32.dll`, and `XINPUT1_3.dll`. Wine selected
`llvmpipe (LLVM 21.1.5, 128 bits)` after Vulkan physical-device enumeration
reported `res -3`. FEX then reported unsupported host atomics and repeated
unaligned-atomic handling before an exception at `0x7000000000`; Wine ended
with an invalid exception frame. No Geometry Wars frame appeared: the live and
post-run 1280x960 screenshots are byte-identical Steam UI screenshots, both
SHA-256
`aa3322f560145a9334d766dc8960c914bd16ad9c870adf1643efe6bec485fe24`.

Therefore Geometry Wars is a useful negative comparison: Proton 11 ARM64,
FEX, Wine, the 32-bit executable, Direct3D 9 translation, and the X11 session
all reached their startup boundary, but the game did not render. The next
focused experiment should isolate the FEX/32-bit exception or try the
launcher's Freedreno Vulkan ICD in a separate run; this result does not justify
returning to the Gamescope-to-AHardwareBuffer path yet.

## Persistent device state after cleanup

The Proton 11 ARM64 wrapper is intentionally retained at
`compatibilitytools.d/proton-11-arm64`, with toolmanifest SHA-256
`ca2f1ec4ef6cf41cd11ab1899d13d1cc1d3278b406fbe13341c6052f75f8a9cb`. The Steam
compatibility mapping now selects `proton11_arm64` for AppID `1086010` (198X);
the resulting `config.vdf` SHA-256 is
`6edb1d6ae4526128fd36ab977ef9438533d6dea0cd1332f6f50714aee111e556`.
The pre-change config captured before this mapping had SHA-256
`3cd755af6a0e65fdeb4226d0355a1d1885fe36d6a1ffd8508eef6e53bac66fd4`.

The exact X11 cleanup reported `nova_x11_cleanup=pass` and the rootfs cleanup
reported `nova_runtime_cleanup=pass`; no matching game, Wine, FEX, Steam,
Gamescope, or X11 processes remained afterward. The run-specific launcher
state, Geometry experiment staging directory, and direct Proton log directory
were removed. The Geometry Wars install and AppID-8400 compatdata remain for a
later launch experiment.
