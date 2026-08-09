# Nova Termux:X11 hardware-acceleration capability probe — 2026-08-09

Status: experiment predeclared; no device result yet.

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

The result will be appended to this record with exact APK/rootfs/ICD
provenance, command output hashes, and post-stop cleanup evidence before the
next hardware-profile run.
