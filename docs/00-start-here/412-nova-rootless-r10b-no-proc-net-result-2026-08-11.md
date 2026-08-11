# Nova rootless R10b — no `/proc/net` shadow result — 2026-08-11

Run ID: `nova-rootless-r10b-no-proc-net-20260811T080512Z`
Sub-run: `R10b-rootless-x11-resolver-temp-no-proc-net`
Status: the controlled retry reached the same native Steam updater blocker;
the declared run was cleaned completely.

## Result

R10b kept the R10 resolver, short PRoot temporary paths, Holo closure, public
ARM64 Steam seed, Termux:X11 transport, display flags, and Steam command
unchanged. It omitted only `NOVA_ROOTLESS_PROC_NET`, so the guest retained the
normal `/proc/net` view instead of receiving the R9/R10 route-only shadow.

The retry cleared the same pre-Steam gates and downloaded the same current
public-beta manifest, but it still did not reach SteamUI or a first updater
frame. Progress stopped at:

```text
Downloaded new manifest: /steam_client_steamdeck_publicbeta_linuxarm64 version 1786141909, installed version 0, existing pending version 0
Downloading update (117109 of 657758 KB)...
```

The package directory contained 11 downloaded payload files totaling
78,967,395 bytes and the pre-existing 21-byte `beta` marker. After the last
progress line, the child updater remained alive and slept on its Unix control
socket; its per-process `/proc/net/tcp` view showed no active CDN connection.
There was no later package, log, or SteamUI frame during the observation
window. The route shadow is therefore not the cause of the post-manifest
stall. The next diagnostic should isolate one exact CDN package transfer,
without changing the Steam command or adding compositor code.

This run makes no claim about Vulkan, Gamescope, Steam authentication, OOBE,
controller, audio, or Proton. The foreground Termux:X11 capture was a black
surface with only the X cursor, not a usable updater or Steam frame.

## Gate evidence

The fresh Android run used serial `675a2365`, Retroid Pocket Nova, Android API
33, and `arm64-v8a`. The pinned APK was installed in place:

```text
android/nova-lab/build/nova-lab-debug.apk
sha256=cff152751344ed96d41f1ec4ef7c0e8683ec6241807cb77c27919a1b92b9522e
```

The APK started a fresh Termux-owned X11 server:

```text
Rootless X11 requested on :77
Rootless X11 ready on 127.0.0.1:6077
termux-x11 com.termux.x11 :77 -listen tcp -ac
```

The unchanged app-UID transport probe passed:

```text
nova_rootless_transport=pass uid=10128 x11_package=com.termux.x11 termux_base=1 transport=loopback-tcp host=127.0.0.1 port=6077
nova_rootless_transport_network=android-inherited-namespace
```

Fresh Android evidence again reported validated Wi-Fi on `wlan0`, address
`192.168.0.23/24`, gateway `192.168.0.1`, and DNS server `192.168.0.1`.
The app-UID TCP probe to `client-update.steamstatic.com:443` returned status
`0`. The staged resolver was:

```text
nameserver 192.168.0.1
resolv_conf_sha256=b015772310392b7bd9127d8ea899e133a456346d6812dd2b7c77bec1d443cd68
```

The route snapshot still reported `default_route=absent`, but it was captured
only as evidence and was not bound into the guest. Supervisor preflight passed
with no `nova_rootless_proc_net=` line. Its effective bindings were:

```text
DISPLAY=127.0.0.1:77
NOVA_ROOTLESS_RESOLV_CONF=files/r10b/resolv.conf
NOVA_ROOTLESS_PROOT_TMP_DIR=files/r10b/proot-tmp
NOVA_ROOTLESS_TMP_DIR=files/r10b/tmp
```

Inside the exact guest, DNS resolved through the staged resolver:

```text
2a04:4e42:d::850 valve.map.fastly.net client-update.steamstatic.com
```

A bounded guest `curl -I -L` returned `HTTP/1.1 200 OK` from the same Steam
update endpoint. Holo archive extraction and the complete package closure both
passed:

```text
nova_rootless_rootfs_archive=pass rootfs=files/r10b/guest-rootfs
nova_rootless_guest_rootfs=pass rootfs=files/r10b/guest-rootfs-closure
```

The unchanged Steam command was:

```text
/opt/nova-steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck
```

The captured Steam output contained no `XOpenDisplay failed` or long-temp
warning. It did contain the expected missing seed-side updater font/assets,
but the authoritative failure boundary is the native package transfer, not a
display assertion.

## Artifacts and provenance

- Branch: `feat/rootless-steamclienttermux-profile`.
- Run code state: commit `63be3b5` (`docs: predeclare rootless R10b no proc
  net retry`).
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- Debian GTK2 assets and `libandroid-shmem`/`libtalloc` artifacts were the
  R10-verified inputs; no artifact was changed for R10b.
- No Steam authentication data was read, copied, exported, or backed up.

## Exact cleanup verification

Only these R10b scopes were removed:

```text
/data/local/tmp/nova-rootless-r10b-no-proc-net-20260811T080512Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10b/
/data/data/com.termux/files/home/.nova-rootless/
```

The exact PRoot/Steam PIDs and X11 session PID were terminated. After cleanup:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_scope=absent
app_scope=absent
termux_scope=absent
rollback_rootfs=present
active_marker=present
free_space=86080888 KiB
```

The rooted rollback paths remained untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Decision and next boundary

The no-route-shadow hypothesis is disproved for the updater stall. Do not add
another Steam or Gamescope patch from this result. Predeclare a fresh bounded
guest `curl` against one exact pending CDN package URL, recording status,
bytes, hash, connection reuse, and timeout behavior under the same resolver,
PRoot temp paths, and X11 transport. If that transfer passes, the next
question is the native updater's multi-request/file-write lifecycle. If it
fails, the boundary is the rootless guest's CDN transfer path.
