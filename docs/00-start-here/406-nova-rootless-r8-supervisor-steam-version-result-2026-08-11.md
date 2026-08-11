# Nova rootless R8 — supervisor and Steam version result — 2026-08-11

Run ID: `nova-rootless-r8-supervisor-steam-version-20260811T064948Z`
Sub-run: `R8-supervisor-steam-version`
Status: closure and supervisor preflight passed; the version-only Steam gate
reached the public seed updater and failed before reporting a version. The
exact R8 app-private and remote trees were cleaned after evidence capture.

## Result

The app-owned Holo archive was extracted atomically through the existing
versioned Holo `bsdtar` bootstrap path. The guest preparation helper then
installed all 161 pinned Holo packages with pacman, extracted the two pinned
Debian GTK2 assets, and activated `guest-rootfs-closure/`. The closure marker
reported `gtk2_and_ui_audio_closure=pass`; the public seed's `steamui.so` had
already passed the dependency check in the preceding R7g boundary.

The supervisor preflight passed as the app UID:

```text
nova_rootless_preflight=pass uid=10128 rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r8-supervisor-steam-version-20260811T064948Z/guest-rootfs-closure proot=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r8-supervisor-steam-version-20260811T064948Z/proot/proot
nova_rootless_free_kib=80369516
```

The bounded command was:

```text
/opt/nova-steam/steamrtarm64/steam --version
```

It launched the real ARM64 Steam executable through PRoot and reached Steam's
updater. It exited with status `254` without printing a version. The decisive
fresh output was:

```text
CBaseLinuxUpdateUI::BaseCreateWindow: XOpenDisplay failed
[2026-08-11 07:04:09] Manifest download: send request
[2026-08-11 07:04:09] Download failed: http error 0 (client-update.steamstatic.com/steam_client_linuxarm64)
[2026-08-11 07:04:09] Failed to load manifest
FatalError: Steam needs to be online to update.
```

The run therefore proves that the rootless supervisor can enter the public
Steam seed, but it does not yet prove a display-free version path. This seed
requires both a usable display for its updater UI and a working network path
before it can complete its self-update/bootstrap boundary.

## Staging corrections within the declared scope

No source helper or rooted runtime was changed. Three input/layout omissions
were corrected before the accepted supervisor attempt:

- The initial Toybox-only archive attempt reproduced the known Holo symlink
  listing failure (`usr/lib64`, ICU, and systemd slice entries). The accepted
  attempt used the already documented Holo `bsdtar` bootstrap input.
- The first R8 PRoot staging omitted the pinned `libandroid-shmem.so`; adding
  that declared Termux library restored the known PRoot closure.
- The app-owned seed tree was normalized to
  `steam-client/steamrtarm64/` with `steamrtarm32 -> steamrtarm64`, and the
  empty app-owned `home/` directory was created before the final preflight.

These were staging corrections, not new runtime behavior. The final accepted
closure and supervisor run used the exact declared helpers and artifacts.

## Artifacts and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `1bfae96` (`docs: predeclare rootless R8 supervisor run`).
- Rebuilt APK/assets SHA-256:
  `1c246f292053b0e7463874ff376c4c75c5f180e61d0e767c78297481db302507`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- `libandroid-shmem.so` SHA-256:
  `84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731`.
- `libtalloc.so.2.4.3` SHA-256:
  `3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb`.
- `nova-zstd` SHA-256:
  `a9a743377cbf0580f4ed02dc363e77a1cd275987283c1bc655e1ab17ca6629a4`.
- Final app-private run size: `4353911 KiB` before cleanup.

The run used no Steam home or authentication data. No X11 server, SteamUI
session, network observer, audio bridge, controller bridge, login, Proton, or
game was started. The rooted runtime was not modified.

## Cleanup verification

Only these declared trees were removed:

```text
/data/local/tmp/nova-rootless-r8-supervisor-steam-version-20260811T064948Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r8-supervisor-steam-version-20260811T064948Z/
```

After cleanup, both scopes were absent, `pidof proot steam steamwebhelper
steam_monitor` returned no process, free space was `86063284 KiB`, and both
rooted rollback paths remained present:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Classification and next boundary

R8 closes the rootless supervisor/Steam-entry boundary, not the display or
network boundary. The next experiment should add a fresh Termux:X11 endpoint
and the inherited Android network namespace together, while keeping the same
161-package closure, public seed, app-owned home, and no-auth policy. Its
acceptance should be the first Steam updater frame plus a successful client
manifest/update handoff; only after that should the run be allowed to classify
SteamUI startup or login.

