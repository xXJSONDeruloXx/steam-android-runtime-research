# Nova rootless R4 — SteamUI guest-rootfs closure — 2026-08-11

Run ID: `nova-rootless-r4-20260811T050124Z`
Status: predeclared; R3 logs, processes, display `:77`, and readiness are not
evidence for this run.

## Purpose and boundary

R3 reached the updated ARM64 Steam client verification boundary and failed to
load `steamui.so` because the immutable Holo guest did not contain GTK2. R4
tests one narrowly scoped remedy: construct a new app-owned copy-on-write
guest rootfs, install the pinned incremental Holo UI/audio closure, extract
two verified Debian bookworm ARM64 GTK2 compatibility packages, and rerun the
SteamUI loader boundary.

This is a rootless package-closure experiment. It does not patch SteamUI,
modify the rooted runtime, import Steam authentication data, change Gamescope
or AHardwareBuffer, or claim that GTK2 loading proves a frame, OOBE, QR login,
audio, controller input, Proton, or a game launch.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `dd461ef` (`fix: reconcile Holo SteamUI artifact hashes`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `dbea499d4227a3a16df5d10473f2dbf7fc6ba2534098e85f0d11d2f5b0e04675`.
- Immutable Holo input rootfs:
  `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs`,
  expected SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package channel:
  `https://holo-packages.steamos.cloud/holo-core-aarch64-preview/mash-20251118.3`.
- Incremental Holo manifest:
  `android/nova-lab/rootless/nova-rootless-steamui-holo-packages.tsv`, 44
  packages, manifest SHA-256
  `6583d0a34da45418d82dba9afa369acc22881fc318550b1a4c876c4235241fae`.
- External compatibility manifest:
  `android/nova-lab/rootless/nova-rootless-steamui-external-assets.tsv`,
  manifest SHA-256
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.
  It pins Debian bookworm `libgtk2.0-0` and `libgtk2.0-common` only; the
  source URLs and package SHA-256/size values are in the manifest.
- PRoot package and loader remain the verified R3 artifacts; Steam seed and
  SteamRT/Proton remain separate gates and are not reclassified by R4.

## Exact mutable scope

The new run must use only this app-private tree:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r4-20260811T050124Z/
  guest-rootfs/
  home/
  state/
  proot/
  steam-client/
  steamui-packages/
  logs/
```

The helper may use an adjacent hidden staging directory while copying, then
atomically renames it to `guest-rootfs/` after all package, library, and
`ldd steamui.so` checks pass. The rooted rollback paths remain out of scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
/data/local/tmp/nova-holo-rootfs
```

Do not copy or inspect rooted Steam authentication data. Use a fresh home and
state directory. A normal QR re-login remains the only permitted login path.

## Run sequence

1. Verify the exact R3 scope is stopped and remove only stale R3/R4 temporary
   paths after collecting any required logs. Verify the rooted rollback paths
   still exist and are unchanged.
2. Install the branch APK in place and record the installed artifact hash.
3. Download the 44 Holo archives from the pinned Holo channel and the two
   Debian packages from their manifest URLs. Verify every size and SHA-256
   before pushing them to the R4 package directory.
4. Verify app UID, free space, source/destination distinction, PRoot, and all
   package hashes. Copy the Holo rootfs to the R4 staging path and install the
   Holo archives with guest `pacman --noconfirm --needed -U`.
5. Extract the Debian data archives, add only the required ARM64 GTK2 loader
   links and library search path, and validate GTK2, GDK, GDK-Pixbuf, ATK,
   PipeWire, PulseAudio, and `ldd steamui.so`.
6. Start a fresh Termux:X11 display `:78` on loopback TCP port `6078` if the
   Steam loader gate passes. Record a fresh process/log baseline before the
   client launch. Do not reuse `:77`.
7. Run the updated ARM64 Steam client through the rootless supervisor. The
   first acceptance boundary is a fresh `steamui.so` load without a missing
   shared library. Only if that passes may the run proceed toward a frame and
   QR/OOBE.

## Acceptance and evidence

R4 is a package-closure pass only if all of these are fresh and run-scoped:

- the candidate rootfs marker contains `rooted_runtime_modified=0` and
  `steamui_patch=0`;
- all 44 Holo and two Debian artifacts pass their declared hashes and sizes;
- the candidate contains the required libraries and `ldd steamui.so` has no
  `not found` entries;
- the client reaches the SteamUI loader boundary without the R3 GTK2 error;
- the exact R4 logs and process/display identity are captured.

Any later display, OOBE, network, audio, controller, Proton, or game result
must be recorded as a separate boundary in a follow-up result document. A
missing ARM64 dependency, package-manager failure, or loader error is a
useful result and must not be worked around by patching SteamUI.

## Cleanup and rollback

On success, failure, interruption, or manual stop: capture fresh R4 logs,
terminate only processes whose command lines contain the R4 state/client paths
or exact display `:78`, verify port `6078` and the R4 process set are gone, and
remove only the R4 app-private tree and explicitly named temporary push paths.
Do not remove the immutable Holo input, rooted display `:0`, rooted Steam data,
or any other experiment's state. If the candidate is useful, preserve its
manifest and result document before cleanup; the source Holo rootfs remains the
rollback baseline.
