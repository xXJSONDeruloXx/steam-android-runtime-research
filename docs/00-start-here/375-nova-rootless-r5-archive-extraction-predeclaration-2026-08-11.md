# Nova rootless R5 — app-private Holo archive extraction — 2026-08-11

Run ID: `nova-rootless-r5-20260811T051530Z`
Status: predeclared; R4 processes, logs, temporary paths, and readiness are
not evidence for this run.

## Purpose and boundary

R4 proved that the existing extracted Holo tree contains root-only files and
cannot be copied faithfully by the Nova app UID. R5 tests the clean rootless
source path: take the pinned Holo `system.rootfs.zst` archive, verify it in the
app process, extract it directly into app-private staging, and then pass that
app-owned rootfs to the already-pushed SteamUI closure helper.

This run must not read or modify the rooted extracted image, use `su`, copy
Steam authentication state, patch SteamUI, or change Gamescope/AHardwareBuffer.
The first UI gate remains the ARM64 `steamui.so` load; later display, OOBE,
QR-login, network, audio, controller, Proton, and game results are separate.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `b92f9b6` (`feat: add rootless Holo archive extraction`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `a6a98a0011c0cef31befa7f09dfc987d4e9d8fd093e35a9d19279988c035fbc1`.
- Holo archive URL:
  `https://holo-packages.steamos.cloud/holo-core-aarch64-preview/mash-20251118.3/system.rootfs.zst`.
- Holo archive size: `384971555` bytes.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- SteamUI Holo manifest SHA-256:
  `6583d0a34da45418d82dba9afa369acc22881fc318550b1a4c876c4235241fae`.
- External GTK2 manifest SHA-256:
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.

## Exact mutable scope

All new state must remain under:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r5-20260811T051530Z/
  rootfs-archive/system.rootfs.zst
  guest-rootfs/
  home/
  state/
  proot/
  scripts/
  steam-client/
  steamui-packages/
```

The archive decompressor writes a temporary uncompressed tar under `state/`
and deletes it before activation. The hidden archive staging directory is a
child of the R5 tree's parent and is renamed into `guest-rootfs/` only after
validation. The rooted paths remain immutable inputs outside this run:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
/data/local/tmp/nova-holo-rootfs
```

## Run sequence

1. Verify exact R4 cleanup and rooted rollback presence. Install the pinned
   APK in place and record the installed hash.
2. Place the verified archive in the R5 app-private `rootfs-archive/` path.
   A device-side download may replace this transfer in a later provisioning
   pass, but the helper must apply the same size and SHA-256 gate.
3. Stage PRoot, its loader/libs, the 44 Holo UI/audio packages, the two
   Debian GTK2 packages, the profile, and both manifests under R5. Verify
   package counts and hashes as the app UID.
4. Run `nova-rootless-extract-rootfs.sh prepare` as the app UID. Require the
   `rootless_archive_extract=1` and `rooted_runtime_modified=0` marker plus
   the required Holo glibc/pacman paths. Confirm the candidate is app-owned.
5. Run `nova-rootless-prepare-guest-rootfs.sh prepare` against that candidate.
   Require the GTK2/GDK/PipeWire/Pulse libraries and a clean `ldd steamui.so`
   check before activation.
6. If the candidate gate passes, start a fresh Termux:X11 display `:78` on
   loopback port `6078`, capture its fresh process/log baseline, and run the
   updated ARM64 Steam client through the rootless supervisor. Do not reuse
   display `:77`.

## Acceptance and evidence

R5 is an archive-provisioning pass only if fresh evidence shows:

- archive size and SHA-256 verification passed;
- atomic candidate activation completed with the rootless marker;
- the candidate is owned by the app UID and does not contain a copied rooted
  Steam home or authentication data;
- all 44 Holo and 2 Debian packages pass their manifest checks;
- `ldd steamui.so` has no missing libraries after closure installation; and
- the client reaches a newer loader boundary than R3’s missing GTK2 failure.

If extraction, package installation, or the loader fails, record that exact
boundary and stop. Do not fall back to the unreadable rooted tree or patch
SteamUI.

## Cleanup and rollback

Capture fresh R5 output before teardown. Stop only R5 PRoot/Steam paths and
display `:78`, verify port `6078` is closed, remove only the R5 app-private
tree and explicitly named temporary push path, and verify the rooted runtime
paths remain present. Authentication secrets and rooted Steam data are never
exported, backed up, or copied.
