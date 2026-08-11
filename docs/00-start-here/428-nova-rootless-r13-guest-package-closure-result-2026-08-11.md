# Nova rootless R13 — guest package closure result — 2026-08-11

Run ID: `nova-rootless-r13-guest-package-closure-20260811T092749Z`
Sub-run: `R13-rootless-holo-closure-after-app-bootstrap`
Status: package closure and atomic activation passed; a follow-up idempotence
check exposed a symlink-aware marker-test bug. The exact run was cleaned.

## Result

R13 successfully prepared an app-owned guest-rootfs candidate from the fresh
R12f archive extraction. The pinned 161-package Holo UI/audio closure and the
two Debian GTK2 compatibility packages installed under PRoot, and the helper
activated `guest-rootfs-closure` only after its checks passed:

```text
source_rootfs=files/r13/guest-rootfs
holo_manifest=files/launcher/nova-rootless-steamui-holo-packages.tsv
external_manifest=files/launcher/nova-rootless-steamui-external-assets.tsv
gtk2_source=debian-bookworm
rooted_runtime_modified=0
steamui_patch=0
gtk2_and_ui_audio_closure=pass
```

The required GTK2, GDK-pixbuf, ATK, PipeWire, and PulseAudio paths were
present. The app-owned package input contained 163 files (161 Holo packages
plus two Debian packages); the activated candidate contained 301 pacman local
package records, including the original Holo base and the installed closure.
The extracted candidate occupied approximately 2,092,768 KiB.

The same helper's idempotence path is not yet correct for this valid candidate.
A read-only rerun returned:

```text
nova_rootless_guest_rootfs=fail reason=refusing_existing_destination:files/r13/guest-rootfs-closure
```

The marker and libraries were present, but the two top-level GTK2 paths are
absolute symlinks:

```text
/usr/lib/libgtk-x11-2.0.so.0 -> /usr/lib/aarch64-linux-gnu/libgtk-x11-2.0.so.0
/usr/lib/libgdk-x11-2.0.so.0 -> /usr/lib/aarch64-linux-gnu/libgdk-x11-2.0.so.0
```

The normal acceptance gate deliberately uses a symlink-aware check and passed;
the early “already staged” shortcut uses only `-e`, which cannot resolve those
guest-absolute targets from the Android app namespace. This is a helper
idempotence bug, not a package, archive, PRoot, Steam, network, or display
failure.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Predeclaration: `427-nova-rootless-r13-guest-package-closure-
  predeclaration`.
- Code under test: commit `561158e` (`fix: replace stale rootless bootstrap
  assets`); predeclaration commit `dcb0312`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5d178365526fa7e18272ed75bcf73f463d62edd8437a646c4b7d0b78a4819313`.
- Bootstrap manifest: 18 payload entries, SHA-256
  `8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Debian external manifest: two entries, SHA-256
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.
- Steam client input: 51 files, approximately 330120 KiB. Key hashes:
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
- Fresh app-UID Termux:X11 transport passed on `127.0.0.1:6077`.
- No Steam process or Steam authentication data was touched. The rooted
  rollback image was not used or modified.

## Exact cleanup verification

Only these R13 run scopes were removed:

```text
/data/local/tmp/nova-rootless-r13-guest-package-closure-20260811T092749Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r13/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK launcher assets were retained. After cleanup:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_r13=absent
app_r13=absent
termux_rootless=absent
rollback_rootfs=present
active_marker=present
free_space=86096104 KiB
```

## Decision and next boundary

Keep the package closure, Debian overlay, and atomic activation result. Fix
only the existing-destination check to accept valid guest symlinks (`-e ||
-L`), predeclare a repeat of the closure idempotence gate, and do not start
Steam until that repeat is documented. After it passes, the next separate
boundary is rootless supervisor preflight against the activated closure.
