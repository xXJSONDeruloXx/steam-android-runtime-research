# Nova rootless R13 — guest package closure predeclaration — 2026-08-11

Run ID: `nova-rootless-r13-guest-package-closure-20260811T092749Z`
Sub-run: `R13-rootless-holo-closure-after-app-bootstrap`
Status: predeclared after R12f closed the app-owned archive bootstrap and APK
asset-cache boundaries.

## Controlled change

R13 advances one stage: use the freshly extracted app-owned Holo rootfs as the
read-only source for `nova-rootless-prepare-guest-rootfs.sh`, installing the
already pinned 161-package Holo SteamUI/audio closure plus the two pinned
Debian GTK2 compatibility packages into a new app-owned candidate. The helper
must activate the candidate only after all hashes, package, library, and
`steamui.so` checks pass.

The R12f APK asset replacement, `/usr/lib` bootstrap layout, Holo archive,
PRoot/loader/lib inputs, display transport, Steam client input, and network
behavior remain unchanged. No Steam process or authentication data is part of
this run.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code under test: commit `561158e` (`fix: replace stale rootless bootstrap
  assets`); current predeclaration includes the pushed R12f result.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5d178365526fa7e18272ed75bcf73f463d62edd8437a646c4b7d0b78a4819313`.
- Bootstrap manifest: 18 payload entries, SHA-256
  `8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 package entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Debian external manifest: two package entries, SHA-256
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.
- Staged package input: 163 files, approximately 199308 KiB; each package
  is verified against the manifests on-device.
- Staged Steam client input: 51 files, approximately 330120 KiB. Key hashes:
  `steamrtarm64/steam`:
  `cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85`;
  `steamrtarm64/steamui.so`:
  `972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0`;
  `steamrtarm64/steamwebhelper`:
  `3901a2af2b9348a4b6381162c3913d607fcf7e959996b8388fd571f4a0d1cd8f`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r13-guest-package-closure-20260811T092749Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r13/
/data/data/com.termux/files/home/.nova-rootless/
```

Retain the current static APK launcher assets for inspection. Preserve and
verify the rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Reread the lifecycle contract and verify clean R13 scopes/process/listener,
   free space, APK asset count, and rollback state.
2. Install/hash-verify the pinned APK and start rootless X11. Require the
   R12f asset gate: exactly 19 bootstrap files, no obsolete regular libraries,
   and a fresh app-UID transport pass.
3. Stage the pinned archive, PRoot/loader/lib closure, all 163 manifest-listed
   package files, and the 51-file Steam client input into fresh R13 state.
   Verify the archive and executable hashes at the app UID.
4. Run `nova-rootless-extract-rootfs.sh prepare` into
   `files/r13/guest-rootfs`, then run the unchanged
   `nova-rootless-prepare-guest-rootfs.sh prepare` with:

   ```text
   NOVA_ROOTLESS_SOURCE_ROOTFS=files/r13/guest-rootfs
   NOVA_ROOTLESS_GUEST_ROOTFS=files/r13/guest-rootfs-closure
   NOVA_ROOTLESS_PROOT_BIN=files/r13/proot/proot
   NOVA_ROOTLESS_PROOT_LOADER=files/r13/proot/loader
   NOVA_ROOTLESS_PROOT_LIB_DIR=files/r13/proot/lib
   NOVA_ROOTLESS_STATE=files/r13/state
   NOVA_ROOTLESS_STEAMUI_PACKAGE_DIR=files/r13/steamui-packages
   NOVA_ROOTLESS_STEAMUI_HOLO_MANIFEST=files/launcher/nova-rootless-steamui-holo-packages.tsv
   NOVA_ROOTLESS_STEAMUI_EXTERNAL_MANIFEST=files/launcher/nova-rootless-steamui-external-assets.tsv
   NOVA_ROOTLESS_STEAM_CLIENT=files/r13/steam-client
   ```

   Acceptance is `nova_rootless_guest_rootfs=pass`, the
   `gtk2_and_ui_audio_closure=pass` marker, required GTK2/audio libraries,
   `steamui_patch=0`, `rooted_runtime_modified=0`, and an atomically activated
   `guest-rootfs-closure`. The rooted rollback path must not appear as a
   source.
5. Stop X11 through the APK, remove only the R13 runtime/Termux scopes, and
   verify no process/listener residue, rollback preservation, and free space.
   Do not start Steam.

## Interpretation

A pass closes the app-owned Holo package-closure stage and permits the next
rootless supervisor/preflight boundary. A failure must be classified as
manifest/input verification, guest pacman/deb installation, library closure,
or atomic activation. Do not change the archive, PRoot, display, Steam, or
network variables in the same run.
