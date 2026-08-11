# Nova rootless SteamClientTermux upstream audit — 2026-08-11

Status: complete as a host-side comparison. No Nova device run was performed
for this audit; the attached device was not available when the comparison was
finished. The existing R31 provider-selector predeclaration remains unchanged
and is still the next device experiment.

## Reviewed provenance

The public prior-art checkout was refreshed from:

```text
https://github.com/huntergdavis/steamclienttermux
```

The reviewed upstream revision is:

```text
c0ada6ea2f56a96872af2190f69f4b5385c68ee2
Add credential-free Chromium callback probes
```

The sibling checkout used for earlier Nova comparison remains clean at
`8d14c10195b34fe2714ba59df1680df27a852532`. The current upstream revision is
the authoritative source for this audit; no upstream files or binaries were
copied into the Nova tree.

The audit covered the README, architecture and technical log, the ARM64
launcher, provider verification, D-Bus/PulseAudio/route helpers, Runtime 4
shadow preparation, the compatibility-tool manifest, the full production
PRoot patch list, and the newest credential-free Chromium probes.

## What the upstream stack actually proves

The upstream project is a layered ARM64 Linux stack:

```text
Android / Termux
        |
Termux:X11 + private PulseAudio
        |
Debian/glibc PRoot with Android-specific PRoot corrections
        |
native ARM64 Steam + software CEF
        |
Runtime 4 + Proton 11 ARM64 + FEX/Wine + private Turnip
```

The important point is that the working result comes from several independent
contracts. `VK_DRIVER_FILES` is only one part of its graphics setup. The
launcher also supplies a private Mesa library directory, `LIBGL_DRIVERS_PATH`,
`MESA_LOADER_DRIVER_OVERRIDE=kgsl`, `TU_DEBUG=noconform`, and a WSI present-mode
selection. It disables CEF GPU compositing while leaving the game Vulkan path
enabled. Those facts make the upstream result useful prior art, but they do
not justify adding all of those variables to the still-open R31 A/B.

## Findings mapped to Nova's current boundaries

### 1. Private session D-Bus is the closest direct match

Nova R30 reached native SteamUI and webhelper, then logged both:

```text
Cannot spawn a message bus without a machine-id
/run/dbus/system_bus_socket: No such file or directory
```

The upstream launcher starts a private `dbus-daemon --session` before Steam,
passes only its address as `DBUS_SESSION_BUS_ADDRESS`, records the daemon PID,
and removes that exact state on exit. Its rationale is also specific: allowing
Steam's updater to auto-start D-Bus can retain an updater pipe and delay launch
for minutes. This is a strong later Nova experiment because it does not require
a machine-id, Android system-bus integration, `su`, or a change to SteamUI.

It must remain separate from `/dev/shm`: the two failures are independently
observed in Nova and must not be combined in the first follow-up.

### 2. `/dev/shm` is a real native-webhelper prerequisite

Nova R30 explicitly failed to create shared memory under `/dev/shm`. Upstream
uses a shared temporary namespace for the later Pressure Vessel/game path, but
that is not evidence that the same mechanism fixes Nova's native webhelper.
For Nova, the clean next shared-memory test is an app-owned directory exposed
specifically at guest `/dev/shm`, with a write/create/unlink smoke test and no
machine-id or D-Bus change in the same run.

If R31 establishes Vulkan-provider progress, `/dev/shm` remains the next
independently justified boundary under the existing decision tree. Do not
replace that with a broad shared-`/tmp` or Runtime 4 import.

### 3. The provider selector is not the complete upstream graphics contract

Upstream's effective provider environment is:

```text
LD_LIBRARY_PATH=<private Mesa>/usr/lib/aarch64-linux-gnu
VK_DRIVER_FILES=<private Mesa>/icd.d/freedreno-private.json
LIBGL_DRIVERS_PATH=<private Mesa>/usr/lib/aarch64-linux-gnu/dri
MESA_LOADER_DRIVER_OVERRIDE=kgsl
TU_DEBUG=noconform
MESA_VK_WSI_PRESENT_MODE=mailbox
```

The Nova R31 predeclaration intentionally tests only the selector spelling:

```text
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

with the exploratory Mesa variables still unset. This is the correct A/B
boundary: R31 can tell us whether the loader selector alone changes the R30
behavior. If it does not, a future provider-complete experiment should add
only the missing provider contract in a new predeclaration. It should not be
retrofit into R31 after launch.

The upstream ICD also points at the private Mesa library by an explicit path;
Nova's ICD points at `/opt/nova-kgsl-driver/libvulkan_freedreno.so`. Therefore
the upstream file is a contract reference, not a drop-in artifact.

### 4. Patched PRoot is aimed primarily at the Runtime 4/Proton boundary

The production upstream patch set addresses two groups of behavior:

- Android-facing IPC behavior: robust-list registration and fuller SysV
  semaphore/shared-memory semantics, including wakeups for blocked `semop`;
- Pressure Vessel behavior: `.l2s` pseudo-hardlinks, explicit `EXDEV` copy
  fallback, escaped mountinfo paths, detached-pivot handling, stacked runtime
  mounts, and literal `/proc/net` directory binding.

Those fixes explain how upstream crossed its later Runtime 4 and Proton
boundaries. Nova R30 already crossed the old `vgui2_s` native SteamUI loader
fatal with the current stock rootless supervisor, so wholesale PRoot import is
not the next native SteamUI experiment. It becomes justified only after the
provider, `/dev/shm`, and D-Bus prerequisites are independently classified, or
when a real Runtime 4/Pressure Vessel launch reaches the corresponding
failure.

### 5. Synthetic `/proc/net` is for Wine's Windows network view, not Steam's
native downloads

Upstream's route shadow is carefully derived from the Android Wi-Fi interface,
netmask, and gateway, then bound as a private `/proc/net` directory. Its
credential-free Proton probe showed why: Android can permit sockets and DNS
while denying `/proc/net/route`, causing Wine `GetAdaptersAddresses` and
Network List Manager to report the machine offline.

Nova's current native Steam UI has already downloaded a game successfully.
That makes the route shadow a later Proton/game experiment, not the present
native SteamUI blocker. If a future game launch reports offline or Wine returns
error 50, this is the strongest upstream-informed network follow-up; it should
also be preserved through Pressure Vessel rather than treated as a general
Android network fix.

### 6. PulseAudio is a later game-audio contract

Upstream starts or reuses a private PulseAudio server, exposes a loopback TCP
endpoint at `tcp:127.0.0.1:4713`, and verifies it before launch. It then places
`PULSE_SERVER` in the game environment. Its Superflight evidence shows that
the endpoint and the per-game environment variable are both necessary.

Nova's delayed UI sounds do not establish a game audio path. Keep the existing
rootless PulseAudio helper as a separate later experiment; do not mix it into
R31 or use it to explain Vulkan enumeration.

### 7. CEF software mode is relevant, but not yet the R31 variable

Upstream reports stale/partial X11 surfaces and bad hit testing with CEF GPU
compositing, and therefore launches Steam with `-cef-disable-gpu` and
`-no-cef-sandbox`. It also uses `-chromeosnopreallocate` to avoid slow PRoot
file preallocation.

Nova already uses `-no-cef-sandbox`; R30's first direct webhelper failure is
earlier and explicit: `/dev/shm` is absent. Adding CEF flags to R31 would make
the provider-selector A/B ambiguous. If `/dev/shm` and D-Bus are later fixed
but the UI still has stale surfaces, upstream's software-CEF flags become a
reasonable narrowly scoped UI experiment. The user's preference against
patching Steam views is preserved; the upstream CEF switch is a launch
contract, not a SteamUI patch.

### 8. The newest Chromium probes do not address Nova's present boundary

Upstream's current `c0ada6e` adds credential-free Windows message-loop and
Chromium renderer probes. They separate FEX/Wine callback behavior from a
specific Rockstar CEF failure. That is good diagnostic method and may help
later with game launch, but it does not change Nova's current native Steam
provider, `/dev/shm`, or D-Bus evidence.

## Decision for the next Nova approach

1. Keep and run R31 exactly as predeclared: same R30 client/layout/runtime,
   same pinned provider files, and only `VK_DRIVER_FILES` added. Do not import
   the broader upstream Mesa environment into that run.
2. If R31 reaches Vulkan enumeration, predeclare `/dev/shm` as the one next
   variable, then classify the result before adding D-Bus.
3. If R31 remains at R30's Vulkan failure, predeclare a provider-complete
   environment experiment rather than guessing about Android device access.
4. Once the native boundary is measured, add a fresh private session D-Bus
   experiment. Keep `/dev/shm` and D-Bus as separate A/Bs.
5. Only after those native prerequisites are closed should the project import
   the upstream Runtime 4/Pressure Vessel PRoot corrections. Then use the
   route shadow for Wine's network API, and the PulseAudio TCP contract for
   game audio.

No device result, Vulkan classification, or authentication state was read or
changed during this audit. No upstream code, Steam data, credentials, or
binary artifacts were copied into the Nova repository.

## Upstream references

- [SteamClientTermux README](https://github.com/huntergdavis/steamclienttermux)
- [ARM64 launcher](https://raw.githubusercontent.com/huntergdavis/steamclienttermux/main/bin/steam-arm)
- [Architecture](https://raw.githubusercontent.com/huntergdavis/steamclienttermux/main/docs/ARCHITECTURE.md)
- [Technical log](https://raw.githubusercontent.com/huntergdavis/steamclienttermux/main/docs/TECHNICAL_LOG.md)
- [PRoot patch provenance](https://raw.githubusercontent.com/huntergdavis/steamclienttermux/main/patches/README.md)
- [Synthetic `/proc/net` helper](https://raw.githubusercontent.com/huntergdavis/steamclienttermux/main/bin/prepare-proc-net-shadow.sh)
- [PulseAudio TCP helper](https://raw.githubusercontent.com/huntergdavis/steamclienttermux/main/bin/prepare-pulseaudio-tcp.sh)
- [Runtime 4 shadow preparation](https://raw.githubusercontent.com/huntergdavis/steamclienttermux/main/scripts/prepare-arm64-runtime-shadow.sh)
