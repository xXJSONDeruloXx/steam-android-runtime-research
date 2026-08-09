# Nova Termux:X11 hardware-acceleration capability probe — 2026-08-09

Status: capability pass; opt-in Steam/X11 hardware profile is authorized for a
separate bounded UI experiment. The software-rendered product default remains
unchanged.

## Question

The direct Termux:X11 Steam client currently forces `swrast`, `softpipe`,
`LIBGL_ALWAYS_SOFTWARE=1`, and `-cef-disable-gpu` so that the signed-in Steam
UI can start. That proves display/lifecycle progress but does not satisfy the
end-state hardware-accelerated graphics requirement. This probe asks the
narrower question first: can the already-installed Nova rootfs and KGSL
sidecar enumerate the Adreno Vulkan device inside the same private namespace
used by Steam?

## Profiles

Each profile will be a fresh bounded run with the exact Nova cleanup contract,
the device locked/asleep if it remains that way, and no physical or synthetic
input:

1. rootfs `vulkaninfo` with the default loader environment;
2. rootfs `vulkaninfo` with the explicit
   `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json` ICD;
3. the explicit ICD profile under the exact Steam UID/GID plus audio group
   `501:20:1005`.

The command will run through `nova-x11-private-namespace.sh chroot-dev`, so
`/dev`, `/proc`, and the rootfs mount helper match the direct Steam launch.
The probe is capability evidence only: it cannot claim that X11 GLX, CEF,
Steam UI composition, Gamescope presentation, or a game render path works.

## Acceptance and next decision

The explicit profile passes only if `vulkaninfo` completes successfully and
reports a physical Qualcomm/Adreno device through the freedreno ICD. A loader
or device failure will be recorded as the hardware boundary and the default
software X11 path will remain unchanged. A pass authorizes a separately
identified opt-in Steam/X11 hardware profile that removes the software-forcing
variables; it does not change the product default until a fresh Steam/X11 UI
run proves that the display remains stable.

## Result — `gpu-20260809T232612Z-vulkan-capability`

The attached Nova was clean before the matrix and remained locked/asleep. No
APK or Steam session was launched, and no physical or synthetic input was
sent. The probe used the installed app-owned namespace helpers so that the
mount topology matched the direct Steam path.

Provenance:

- installed launcher APK: `/data/app/…/base.apk`, SHA-256
  `0ea67e39b3e0068eb78386cf3ddaac68e643ba2053361f23f0b3faf0213be4e8`;
- private namespace helper SHA-256
  `d870910b03678bb56001e424d5bcd9f1ae8ef4e6c39817e3488ded250aabc937`;
- rootfs ICD `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`, SHA-256
  `337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70`;
- rootfs ICD library `/opt/nova-kgsl-driver/libvulkan_freedreno.so`, SHA-256
  `a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810`;
- rootfs `/usr/bin/vulkaninfo`, SHA-256
  `bdbfc42831e7d03e83264d062a8dc749defec28ebc51c282d8e77434c4483623`.

The four profiles were run through `chroot-dev` with the app mount helper:

```text
root/default:  VK_ICD_FILENAMES unset; exit 1; no valid GPUs
steam/default: VK_ICD_FILENAMES unset; exit 1; no valid GPUs
root/explicit: VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json; exit 0
steam/explicit: same ICD, setpriv 501:20:1005; exit 0
```

The successful explicit profiles both reported:

```text
deviceName    = Turnip Adreno (TM) 740
driverID      = DRIVER_ID_MESA_TURNIP
driverName    = turnip Mesa driver
driverInfo    = Mesa 25.2.7
```

SHA-256 of the complete combined stdout/stderr for the corresponding
`vulkaninfo --summary` invocations:

| Profile | Output SHA-256 |
| --- | --- |
| root/default loader | `31d44d050a37ff5cf741a6cbb621815c2c7a39194df777b86eea68822fad0eed` |
| Steam `501:20:1005`/default loader | `31d44d050a37ff5cf741a6cbb621815c2c7a39194df777b86eea68822fad0eed` |
| root/explicit ICD | `b47ed9416897668741353e54970bcd12278a201f75ea55610116f27433848aa4` |
| Steam `501:20:1005`/explicit ICD | `b47ed9416897668741353e54970bcd12278a201f75ea55610116f27433848aa4` |

The exact cleanup helper returned:

```text
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

The post-run process and temporary-rootfs checks returned no matching
processes or temporary probe files. This resolves the capability question but
not the display question: `vulkaninfo` does not prove X11 GLX, CEF GPU
composition, Steam UI stability, Gamescope presentation, or game rendering.

## Next bounded experiment

Add an explicit opt-in hardware profile to the direct Steam client. It will
set the validated ICD, remove the software-forcing Mesa variables, and omit
`-cef-disable-gpu`; the existing default will continue to force `swrast`,
`softpipe`, and software CEF. Run that profile as a fresh Steam/X11 session,
capture the visible UI and fresh client logs, and revert to the default profile
on any instability. Do not call the hardware path product-ready based on this
capability pass alone.

The profile gate is now implemented in the direct client and one-click root
launcher. The default values are:

```text
NOVA_ANDROID_LAUNCHER_HARDWARE_ACCEL=0
NOVA_ANDROID_LAUNCHER_VULKAN_ICD=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

For the bounded hardware experiment, invoke the root launcher with
`NOVA_ANDROID_LAUNCHER_HARDWARE_ACCEL=1`. It passes
`NOVA_TERMUX_X11_STEAM_HARDWARE_ACCEL=1` and the explicit
`NOVA_TERMUX_X11_STEAM_VULKAN_ICD` into the private namespace. Invalid mode or
relative ICD values fail before launch. Local `sh -n` and invalid-value tests
passed; no device hardware-profile run has started yet.
