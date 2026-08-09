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

## First UI-profile attempt — `gpu-20260809T233330Z-x11-socket-startup`

The first one-click hardware-profile attempt stopped at the X11 server gate;
Steam was never launched. The wrapper recorded:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_gamepad=pass
nova_launcher_input_allow=event9
nova_launcher_x11_pid=22956
nova_launcher_start=fail reason=x11_socket_not_ready
```

The fresh server log and Activity-start log were empty. The exact cleanup
helper still returned `nova_x11_cleanup=pass`, and the root runtime cleanup
returned `nova_runtime_cleanup=pass`; no Steam, X11, Gamescope, or rootfs
temporary probe process remained. The failure is classified as one-click
Termux:X11 startup ordering, not as a Vulkan or Steam rendering result.

The wrapper previously waited for `X0` before opening
`com.termux.x11/com.termux.x11.MainActivity`. The established display bring-up
sequence opens that Activity first, then starts `CmdEntryPoint`; the wrapper is
now corrected to use that order. This source fix must be rebuilt and pushed
before repeating the hardware UI profile.

## Second UI-profile attempt — `gpu-20260809T233603Z-steam-hardware-accel`

The corrected one-click wrapper reached the full X11 and Steam-client launch
boundary, but the hardware Steam profile crashed before a usable UI:

```text
nova_launcher_ready=pass display=:0 geometry=1280x960
client_hardware_accel=1
client_mesa_driver=unset
client_gallium_driver=unset
client_libgl_always_software=unset
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_flags_final=... -no-cef-sandbox -fullscreen -fulldesktopres
client_started=pass
client_status=139
```

The fresh Termux:X11 server log reached `CmdEntryPoint`, Android Adreno EGL,
the 1280×960 surface, and `XCB connection is successfull`. Steam's fresh
stderr then reported its startup banner, failure to create the Mesa shader
cache under the Steam home, and a segmentation fault. The Steam webhelper did
not produce a fresh run entry, so this is not a successful Steam UI or CEF
rendering result. Steam's crash handler reported
`CrashID=bp-23f05aec-44f9-4a53-983b-c908b2260809`; the minidump was
`/tmp/dumps03/crash_20260809233609_3.dmp`, 201152 bytes, SHA-256
`7a75608de12e921fdf049dfe0549d1dd0055c33ee497a75403c3b6a7455655fd`.

Provenance for this run:

- installed APK SHA-256:
  `78b19472bf711ebdac7e56c4338c2e6589afce8b2ef62339da6c3e85d32b65c4`;
- packaged one-click wrapper SHA-256:
  `e56991b69f18214d280b1d06df417697fc384d270c0cce024e1271f5b7c62386`;
- packaged Steam client SHA-256:
  `f97a94c7f5927efa9774f8e24eefc47e259e8f38870f1c708a16479dceee4f89`;
- rootfs Steam executable SHA-256:
  `6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf`.

Fresh artifact hashes:

| Artifact | SHA-256 |
| --- | --- |
| root launcher log | `9921cd49db610686f0b8f38dd667beda6788869894dc96e8d94976eaee96b94e` |
| Termux:X11 server log | `1a16b2a1bd7d8c496665aa58a95cc4b2a1bd980e06da3a26a2d8550d88752c24` |
| direct client log | `35a425887db5ff616ffda3cc5520c428ede55f31423af7131d1808386f1f8b7e` |
| Steam stderr | `99ce4d0fb5151d6923e2f7365cad4eb4b4385a93ffcde59aa880c4eb2fec6ab5` |
| relay log | `cb2344204db9a3863bd33a3e141cfee4b63d032c8ce81bb1dd31b4b3332859a5` |

The relay initialized but recorded `uinput_event_forwarded=none`; no physical
or synthetic button event was generated or tested. Exact runtime cleanup
returned `nova_runtime_cleanup=pass`, and no matching Steam, X11, Gamescope,
or rootfs runtime process remained afterward. Hardware mode is therefore
rejected as a product default for now. The next useful experiment is to
separate the CEF GPU flag from the Mesa/Vulkan environment, because this run
changed both at once; the software profile remains the known-good fallback.

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
