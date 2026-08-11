# AYN Thor rootless public-client provenance refresh — predeclaration — 2026-08-11

Run identity: `thor-rootless-public-client-provenance-refresh-20260811T223004Z`;
sub-run: `R35-public-client-provenance-refresh`.

Status: predeclared as the single next experiment after [doc
500](500-ayn-thor-rootless-current-tree-cef-disable-gpu-invalid-fixture-result-2026-08-11.md).
This is a cold, credential-free client-provenance experiment. It is not the
R34 CEF A/B and must not be used to claim anything about Vulkan, SteamUI, or
OOBE.

## Question and controlled change

R34 cannot run until the exact R33 public client archive is available. The
preserved rooted tree currently reproduces a sanitized archive with hash
`3b54ebe8…`, while R33 and the R34 gate require `9a3507ce…`. The exact
client bytes may be recoverable by allowing the public ARM64 Steam updater to
refresh a fresh app-owned copy of the sanitized tree.

R35 changes only the **client-provenance method**:

> Start from a fresh sanitized public ARM64 client tree and allow the normal
> public updater to run in that fresh app-owned tree. Do not use authenticated
> Steam state, the preserved rooted Steam home, or the stable seed as the
> source of mutable client state.

The updater may change many public client files by design; that is the
provenance operation being measured. No Vulkan/provider/CEF/session-service
hypothesis is tested in R35. The resulting tree is only eligible for R34 after
its complete sanitized archive is hashed and the result is classified.

## Fixed identity and fresh scopes

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
rootless_outer_uid=10138
rootless_guest_mode=PRoot -0
```

Use fresh scopes:

```text
/data/local/tmp/thor-rootless-public-client-provenance-refresh-20260811T223004Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r35-public-client-refresh/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The app-owned mutable Steam tree, updater logs, temporary paths, X11 server,
socket/listener, screenshots, and readiness baselines must all be fresh. The
rooted runtime is a read-only provenance source only; do not start the rooted
launcher or allow the updater to write into it.

## Fixed sanitized inputs

The starting public tree must be created from the preserved rooted tree with
the established exclusion list:

```text
appcache/
config/
logs/
steamapps/
userdata/
.crash
local.vdf
update_hosts_cached.vdf
ssfn*
loginusers.vdf
steam.token
user*.vdf
localconfig.vdf
sharedconfig.vdf
```

The pre-refresh reconstructed seed is expected to be:

```text
seed_archive_bytes=3457524736
seed_archive_sha256=3b54ebe8dd92ebbe304376335d59da28ebd88b1467999d39fee1c07ec98cee9a
seed_tar_entries=21513
seed_forbidden_filename_scan=empty
```

If the seed itself does not match, classify the run invalid before updater
launch. Do not silently substitute the stable seed or a different client tree.

Use the pinned Holo/PRoot inputs already verified for R34:

```text
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
```

R35 does not need to select the Turnip provider. Keep
`VK_DRIVER_FILES`, `VK_ICD_FILENAMES`, and `VK_LOADER_DEBUG` unset unless
the updater process itself proves that a selector is required for an
independent infrastructure reason. Do not add Mesa overrides, software-GL
variables, `LD_PRELOAD`, `/dev/shm), D-Bus, Runtime 4, Proton, FEX,
Gamescope, or SteamUI changes.

## Updater launch contract

Use the same app-UID PRoot, Holo guest, inherited Android network, fresh
resolver, and direct TCP Termux:X11 transport, but intentionally allow the
normal bootstrap/update handoff by omitting `-nobootstrapperupdate`:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
DISPLAY=127.0.0.1:77
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
VK_DRIVER_FILES=unset
VK_ICD_FILENAMES=unset
VK_LOADER_DEBUG=unset
LD_PRELOAD=unset
MESA_LOADER_DRIVER_OVERRIDE=unset
GALLIUM_DRIVER=unset
LIBGL_ALWAYS_SOFTWARE=unset
```

The updater command is:

```text
/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui
```

Do not add `-cef-disable-gpu` in R35. That flag belongs to the still-unrun R34 A/B and must remain isolated from the provenance refresh.

## Evidence and classification

Capture before launch:

- branch/HEAD, device identity, app UID and SELinux identity;
- seed archive size/hash/entry count and forbidden-name scan;
- Holo, PRoot, provider, and selected client hashes;
- exact environment/command, fresh free space, and exact scopes;
- fresh X11 PID/listener, xprop handshake, X11 artifact identity, and consent
  dialog state.

Capture during and after the updater:

- updater/bootstrap logs, manifest/channel/version lines, and process state;
- whether the updater completes, restarts, stalls, or exits;
- post-update selected client hashes;
- a newly generated sanitized archive using the same exclusions;
- resulting archive size/hash/entry count and a forbidden-name scan;
- no SteamUI/Vulkan/OOBE conclusion unless a later Steam run is separately
  predeclared.

Classify only as:

1. **refresh-pass-exact-client** — the post-refresh sanitized archive is exactly
   `3457525760` bytes with SHA-256
   `9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb), and
   the selected public hashes match R33.
2. **refresh-pass-different-public-client** — the updater completes and produces
   a different sanitized public archive. Record all hashes and stop; do not
   use it as R34 without a new full-tree equivalence predeclaration.
3. **refresh-fail** — updater or rootless infrastructure fails before producing
   a verified post-refresh archive.
4. **invalid** — any auth-state exposure, wrong device/UID, stale scope,
   missing seed gate, preserved-root mutation, undeclared helper/service, or
   lifecycle/fixture change invalidates the run.

## Cleanup and authentication boundary

Use exact-scope cleanup before launch and on every exit. Restore Termux settings
byte-for-byte, terminate only the verified R35 X11 process, remove only the
R35 device/app/helper scopes, verify no matching Steam/PRoot/webhelper/X11
process or port 6077 listener remains, and verify both rooted rollback paths.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read,
copied, backed up, committed, or exported.
