# Nova rootless R10 — resolver and short-temp result — 2026-08-11

Run ID: `nova-rootless-r10-resolver-temp-20260811T073059Z`
Sub-run: `R10-rootless-x11-resolver-temp-steam-handoff`
Status: resolver, HTTPS, and short-PRoot-path gates passed; the Steam client
manifest handoff passed; the bulk client update stalled after 108,440 KB and
no first Steam frame was reached.

## Result

R10 cleared both R9 blockers without changing the Steam command or adding a
Gamescope/AHardwareBuffer path. A fresh app-owned resolver made guest DNS and
HTTPS work, and the short PRoot temporary directories avoided the prior
`proot-shm-helper: Temporary path too long` warning.

The unchanged client command was:

```text
/opt/nova-steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck
```

Steam resolved and downloaded the current public-beta manifest:

```text
Downloaded new manifest: /steam_client_steamdeck_publicbeta_linuxarm64 version 1786141909, installed version 0, existing pending version 0
Downloading update (108440 of 657758 KB)...
```

It created 12 package files totaling 78,967,416 bytes in the app-owned Steam
client package directory, then stopped making progress. The Steam and child
updater processes remained alive while the visible HTTPS connections moved to
`CLOSE_WAIT`; no new log line or package file appeared during the observation
window. The exact PRoot/Steam tree was then terminated and the run was cleaned
under the lifecycle contract.

## Gate evidence

The fresh APK was installed in place with `adb install -r` and its installed
base APK was pulled only for artifact verification:

```text
versionName=0.3 versionCode=3
apk_sha256=cff152751344ed96d41f1ec4ef7c0e8683ec6241807cb77c27919a1b92b9522e
```

The APK service started a new Termux-owned `:77` server on
`127.0.0.1:6077`. After an exact cleanup/restart of the probe's stale TCP
clients, the unchanged app-UID transport probe passed:

```text
nova_rootless_transport=pass uid=10128 x11_package=com.termux.x11 termux_base=1 transport=loopback-tcp host=127.0.0.1 port=6077
nova_rootless_transport_network=android-inherited-namespace
```

Fresh Android evidence reported validated Wi-Fi on `wlan0`, address
`192.168.0.23/24`, gateway `192.168.0.1`, and DNS server `192.168.0.1`.
The app-UID shell TCP probe to `client-update.steamstatic.com:443` returned
status `0`. R10 staged the app-owned resolver:

```text
nameserver 192.168.0.1
resolv_conf_sha256=b015772310392b7bd9127d8ea899e133a456346d6812dd2b7c77bec1d443cd68
```

The route shadow preserved the app-visible connected route and recorded
`default_route=absent`, as in R9. It did not fabricate a gateway.

The verified Holo archive extraction and complete 161-package closure passed:

```text
nova_rootless_rootfs_archive=pass rootfs=files/r10/guest-rootfs
nova_rootless_guest_rootfs=pass rootfs=files/r10/guest-rootfs-closure
```

Supervisor preflight passed with the explicit bindings:

```text
DISPLAY=127.0.0.1:77
NOVA_ROOTLESS_RESOLV_CONF=files/r10/resolv.conf
NOVA_ROOTLESS_PROOT_TMP_DIR=files/r10/proot-tmp
NOVA_ROOTLESS_TMP_DIR=files/r10/tmp
```

Inside that exact guest, `getent hosts client-update.steamstatic.com` returned
`valve.map.fastly.net`, and the bounded HTTPS request returned `http_code=200`.
The Steam logs contained no `XOpenDisplay failed` and no temporary-path warning.

## Failure classification

R10 is not a DNS or basic Android-network failure. It is also not the R9
display-port failure: the Steam updater reached the X11-backed process path
and successfully downloaded the manifest. The first new blocker is the native
Steam updater's bulk package-transfer lifecycle under PRoot: after the initial
package set, its child updater stopped advancing while its visible HTTPS
connections were left in `CLOSE_WAIT`. No SteamUI, CEF, Vulkan, Gamescope,
authentication, or OOBE claim is justified from this run.

The correlated capture was a black Termux:X11 surface with an X cursor and no
usable updater frame. The updater's missing seed-side font/assets explain why
that capture is not a positive display result; the network and manifest logs
are the authoritative evidence for this run.

## Artifacts and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `06ed9d2` (`docs: predeclare rootless R10 resolver run`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `cff152751344ed96d41f1ec4ef7c0e8683ec6241807cb77c27919a1b92b9522e`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- PRoot: SHA-256
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader: SHA-256
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- `libandroid-shmem.so`: SHA-256
  `84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731`.
- `libtalloc.so.2.4.3`: SHA-256
  `3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb`.
- Debian GTK2 assets: SHA-256
  `d035cfd259b330a641a6b7310748ba2f42903b795d4923fa4fb23bacb872ac07` and
  `f55a9800d3721b1de246e4bfaf94a63ca50efdfa49eb5fa2362ed4fa79258299`.
- Display process: Termux-owned `termux-x11 com.termux.x11 :77 -listen tcp
  -ac`; the server was stopped after evidence capture.
- No Steam authentication data was read, copied, exported, or backed up.

## Cleanup verification

Only the declared R10 scopes were removed:

```text
/data/local/tmp/nova-rootless-r10-resolver-temp-20260811T073059Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10/
/data/data/com.termux/files/home/.nova-rootless/
```

After cleanup, all three scopes were absent, port `6077` was closed, and no
R10 PRoot/Steam/Termux:X11 process remained. Free space recovered to
`86070708 KiB`. The rooted rollback paths remained present:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Next boundary

Predeclare one retry with the resolver, short temp paths, display, seed, and
Steam flags unchanged, but omit the diagnostic `/proc/net` route-shadow bind.
The shadow exposes only `route` and `ipv6_route`, so the native updater cannot
inspect the guest's normal `/proc/net/tcp` view. This is a hypothesis, not a
conclusion; if the same post-manifest stall remains without the shadow, the
next test should isolate the CDN package transfer with a bounded guest curl
against one exact package URL before changing Steam or PRoot behavior.
