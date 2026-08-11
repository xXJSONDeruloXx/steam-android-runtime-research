# AYN Thor rootless public-seed refresh recovery — predeclaration — 2026-08-11

Run identity: `thor-rootless-public-seed-refresh-recovery-20260811T234742Z`;
sub-run: `R37-public-seed-refresh-recovery`.

Status: predeclared as the single next experiment after [doc
504](504-ayn-thor-rootless-public-client-normalized-equivalence-result-2026-08-11.md).
This is a credential-free public-client provenance recovery gate. It is not a
SteamUI, Vulkan, `/dev/shm`, D-Bus, Runtime 4, Proton, Gamescope/AHardwareBuffer,
or APK experiment.

## Question and controlled change

R36 could not start because the preserved rooted tree no longer reconstructs the
required 3,457,524,736-byte updater-derived seed. R37 changes only the starting
public payload: it uses the verified older public bootstrap seed already present
in the repository, lets the normal ARM64 public updater refresh a fresh
app-owned copy, and tests whether the resulting tree can be normalized back to
the expected current public-beta fixture.

The only permitted output normalization is the one public generated file
already identified by R35:

```text
./steamrtarm64/.cef-dev-tools-size.vdf
size=71
sha256=d82fc37374e2668f6569102bd2ed13b8d21ebad019c5d1bf7fb825617d0d32a4
```

The original file must remain in the fresh R37 scope as evidence until the
normalized archive gate completes. No other file may be removed, patched, or
renamed. R37 must not launch Steam from the normalized result.

## Fixed inputs and scopes

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
rootless_outer_uid=10138
rootless_guest_mode=PRoot -0
seed_archive=android/nova-lab/build/steam-bootstrap/steam-home.tar.gz
seed_archive_bytes=1756623692
seed_archive_sha256=1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124
```

Use fresh exact scopes:

```text
/data/local/tmp/thor-rootless-public-seed-refresh-recovery-20260811T234742Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r37-public-seed-refresh-recovery/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Reuse only the pinned Holo rootfs, 161-package UI/audio closure, PRoot,
app-owned provider files, current APK helper assets, inherited Android network,
and direct TCP Termux:X11 transport. Recreate Steam state, logs, resolver,
temporary directories, X11, sockets, listener, screenshots, and readiness from
scratch. Keep all Vulkan selectors, loader diagnostics, Mesa overrides, CEF
flags, `/dev/shm`, machine-id, D-Bus, Runtime 4, Proton, FEX, Gamescope, and
AHardwareBuffer changes absent.

## Updater and normalization contract

Use the R35 normal public updater command and environment, including omission of
`-nobootstrapperupdate` and `-cef-disable-gpu`:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
DISPLAY=127.0.0.1:77
VK_DRIVER_FILES=unset
VK_ICD_FILENAMES=unset
VK_LOADER_DEBUG=unset
LD_PRELOAD=unset
MESA_LOADER_DRIVER_OVERRIDE=unset
GALLIUM_DRIVER=unset
LIBGL_ALWAYS_SOFTWARE=unset
```

```text
/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui
```

Before any device mutation, verify the seed bytes/hash, app UID/SELinux
identity, free space, sibling checkout revision, rooted rollback paths, and
Termux properties hash. Capture updater version/manifest and selected native
hashes before and after refresh. Capture a screenshot only as transport
evidence; do not call it a Steam frame.

After the updater completes, create the fresh sanitized archive with the same
exclusions as R36. Quarantine only the named `.cef-dev-tools-size.vdf` file and
recreate the normalized archive. The expected normalized gate is:

```text
expected_normalized_bytes=3457525760
expected_normalized_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
expected_tar_entries=21513
expected_regular_files=19633
expected_symlinks=369
expected_forbidden_filename_scan=empty
```

## Classification

1. `invalid` for wrong device, hash, UID, stale or mutated scope,
   authentication exposure, helper drift, preserved-root mutation, or an
   undeclared service/variable.
2. `recovery-pass-exact-public-client` if the normalized archive matches the
   expected fixture and the named public marker is the only difference.
3. `recovery-pass-different-public-client` if the updater completes but any
   other public-only difference remains; record the complete difference and
   stop.
4. `recovery-fail` if the updater or archive gate fails.

No classification authorizes a SteamUI or OOBE claim. A separate fresh
predeclaration is required to launch the recovered client.

## Cleanup and authentication boundary

Capture evidence before teardown. Terminate only the verified R37 X11 PID and
force-stop only the R37 session packages that were started. Remove only the
three R37 scopes, restore Termux properties byte-for-byte, verify no matching
Steam/PRoot/webhelper/X11 process and no 6077 listener, and verify both rooted
rollback paths. Do not broad-pkill, clear app data, delete the rooted runtime,
or remove `/data/local/tmp/nova-active-runtime`.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read, copied,
backed up, committed, or exported.
