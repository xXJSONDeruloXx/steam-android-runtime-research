# Nova rootless R9 — Termux:X11 and network handoff result — 2026-08-11

Run ID: `nova-rootless-r9-x11-network-20260811T070826Z`
Sub-run: `R9-rootless-x11-network-steam-handoff`
Status: Termux:X11 transport and Steam updater window creation passed; the
guest network resolver and a rootless shared-memory temporary-path boundary
stopped the updater before its manifest handoff.

## Result

The current APK was installed in place without clearing Nova data and verified
on the device. The APK bridge started a fresh Termux-owned display `:77`; the
app-UID transport probe passed over loopback TCP:

```text
nova_rootless_transport=pass uid=10128 x11_package=com.termux.x11 termux_base=1 transport=loopback-tcp host=127.0.0.1 port=6077
nova_rootless_transport_network=android-inherited-namespace
```

The app-UID route snapshot also passed, but recorded no visible default route:

```text
nova_rootless_proc_net=pass destination=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r9-x11-network-20260811T070826Z/state/config/proc-net default_route=absent
```

The unchanged Holo `bsdtar` bootstrap extractor and complete 161-package guest
closure passed. Supervisor preflight passed with
`DISPLAY=127.0.0.1:77`. The actual Steam command was:

```text
/opt/nova-steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck
```

Unlike R8, Steam did not report `XOpenDisplay failed`; it created its updater
window through the TCP X11 endpoint. It then stopped with exit status `254`:

```text
proot-shm-helper: Temporary path too long
[2026-08-11 07:16:04] Manifest download: send request
[2026-08-11 07:16:04] Download failed: http error 0 (client-update.steamstatic.com/steam_client_steamdeck_stable_linuxarm64)
[2026-08-11 07:16:04] Error: Steam needs to be online to update.
```

The correlated 1280x960 capture showed the Termux:X11 surface with the X
cursor but no usable Steam updater frame. No Steam process remained after the
exit.

## Network classification

This is not a raw Android connectivity failure. Android's connectivity state
reported validated Wi-Fi on `wlan0`, default gateway `192.168.0.1`, and DNS
server `192.168.0.1`. The app UID's direct TCP probe to
`client-update.steamstatic.com:443` returned exit `0`.

Inside the Holo guest, however:

```text
cat: /etc/resolv.conf: No such file or directory
curl: (6) Could not resolve host: client-update.steamstatic.com
```

The rootfs has neither `/etc/resolv.conf` nor the referenced systemd-resolved
stub path. The guest therefore cannot resolve the Steam update host even
though the Android app UID has network access. The app-visible route snapshot
also lacks the default route, so it remains evidence rather than a complete
guest network configuration.

## Shared-memory/path classification

The `proot-shm-helper: Temporary path too long` warning appears only after the
X11 updater window is created and correlates with the long run-specific
`PROOT_TMP_DIR` under the app-private R9 path. It is a separate rootless
shared-memory path issue, not evidence against the X11 TCP connection. The
next experiment should shorten the app-owned state path or add an explicit
short temporary-path contract, while preserving the same guest rootfs and
display variables.

## Artifacts and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `3ad7ad5` (`docs: predeclare rootless R9 X11 network run`).
- Installed APK SHA-256:
  `1c246f292053b0e7463874ff376c4c75c5f180e61d0e767c78297481db302507`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- Display: Termux:X11 `:77`, loopback `127.0.0.1:6077`, launched by the APK
  bridge; exact process observed as `termux-x11 com.termux.x11 :77 -listen
  tcp -ac`.
- No Steam authentication data was read, copied, exported, or staged.

## Cleanup verification

Only the declared R9 scopes were removed:

```text
/data/local/tmp/nova-rootless-r9-x11-network-20260811T070826Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r9-x11-network-20260811T070826Z/
/data/data/com.termux/files/home/.nova-rootless/
```

After cleanup, all three scopes were absent, the `:77` listener was closed,
no PRoot/Steam/Termux `:77` process remained, free space was `86079660 KiB`,
and the rooted rollback paths were still present:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The latest APK remains installed in place; it is not a rootless Steam home and
contains no copied authentication state.

## Next boundary

R9 closes the APK-to-Termux:X11 transport and the first rootless X11 window
creation boundary. The next narrow implementation should add two optional,
app-owned bindings to the supervisor: a short `PROOT_TMP_DIR` path and a
validated guest `/etc/resolv.conf` sourced from Android's current DNS state.
Then rerun the same public seed and Big Picture command with one variable
changed at a time before attempting SteamUI/OOBE.

