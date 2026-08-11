# Nova rootless R11 — single CDN payload result — 2026-08-11

Run ID: `nova-rootless-r11-cdn-single-payload-20260811T082140Z`
Sub-run: `R11-rootless-x11-resolver-temp-single-steam-cdn-payload`
Status: the representative guest CDN transfer passed; no Steam client was
launched; the exact run was cleaned completely.

## Result

R11 replaced the native Steam updater with one bounded guest transfer of the
first package URL that R10/R10b had queued. All Android, Termux:X11, resolver,
PRoot, Holo, and package-closure gates passed. The guest downloaded the exact
payload successfully:

```text
URL:
https://client-update.steamstatic.com/tenfoot_images_all.zip.vz.193cb8c4eb4446698ea2c0a9e8c4e6b6a623dac7_5572671
curl_exit=0
HTTP/1.1 200 OK
Content-Length: 5572671
observed_size=5572671
sha256=e1fee3beffa9d08a415a35ddc7d3141af6c44269c67e67aa0a3eea6e56889bd7
```

The file was written through the guest `/run/nova` bind to the app-owned
path:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r11/state/run/nova/cdn/tenfoot_images_all.zip.vz.193cb8c4eb4446698ea2c0a9e8c4e6b6a623dac7_5572671
```

This proves the rootless guest can resolve, connect to, and fully read at
least this Steam CDN payload. The R10/R10b native updater stall is therefore
not explained by an inability to fetch this representative package. The next
diagnostic should target the updater's multi-request/socket/file-commit
lifecycle, not another display or Gamescope patch.

R11 did not launch Steam and makes no claim about SteamUI, OOBE, Vulkan,
Gamescope, authentication, controller, audio, or Proton.

## Gate evidence

The fresh device was Retroid Pocket Nova, serial `675a2365`, Android API 33,
`arm64-v8a`. The installed APK matched the pinned build:

```text
android/nova-lab/build/nova-lab-debug.apk
sha256=cff152751344ed96d41f1ec4ef7c0e8683ec6241807cb77c27919a1b92b9522e
```

The APK started a fresh Termux-owned X11 server on `:77` and the app-UID
loopback transport probe passed:

```text
Rootless X11 requested on :77
Rootless X11 ready on 127.0.0.1:6077
nova_rootless_transport=pass uid=10128 x11_package=com.termux.x11 termux_base=1 transport=loopback-tcp host=127.0.0.1 port=6077
nova_rootless_transport_network=android-inherited-namespace
```

Fresh Android evidence reported validated Wi-Fi on `wlan0`, address
`192.168.0.23/24`, gateway and DNS `192.168.0.1`, with the app UID reaching
`client-update.steamstatic.com:443` at TCP status `0`. The app-owned resolver
hash was:

```text
nameserver 192.168.0.1
resolv_conf_sha256=b015772310392b7bd9127d8ea899e133a456346d6812dd2b7c77bec1d443cd68
```

The fresh Holo archive was verified and the complete 161-package closure was
installed into app-owned R11 state:

```text
rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
nova_rootless_rootfs_archive=pass rootfs=files/r11/guest-rootfs
nova_rootless_guest_rootfs=pass rootfs=files/r11/guest-rootfs-closure
```

Supervisor preflight passed without a `NOVA_ROOTLESS_PROC_NET` binding:

```text
DISPLAY=127.0.0.1:77
NOVA_ROOTLESS_RESOLV_CONF=files/r11/resolv.conf
NOVA_ROOTLESS_PROOT_TMP_DIR=files/r11/proot-tmp
NOVA_ROOTLESS_TMP_DIR=files/r11/tmp
```

Inside the exact guest, `getent hosts client-update.steamstatic.com` returned
`2a04:4e42:d::850 valve.map.fastly.net client-update.steamstatic.com`. A
bounded HEAD request returned `HTTP/1.1 200 OK` and the declared content
length. The subsequent full `curl --fail --location` transfer exited `0` and
the app-owned file size and SHA-256 matched the captured result above.

## Extractor boundary discovered during the run

The first R11 archive attempt used the script's direct app-UID zstd plus
Android toybox `tar` path. The pinned archive was verified, but toybox tar
rejected Holo symlink and metadata entries, and the script correctly cleaned
its staging directory:

```text
nova_rootless_rootfs_archive=fail reason=archive_extract
```

The retry used the preserved versioned Holo rootfs only as a read-only PRoot
`bsdtar` bootstrap:

```text
NOVA_ROOTLESS_BOOTSTRAP_ROOTFS=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
```

That path passed extraction and was not modified. This is a productization
caveat: a genuinely clean device with no rooted rollback image still needs an
app-owned bootstrap extractor (or a bundled equivalent) to avoid depending on
the rooted path for Holo archive extraction. It is separate from the CDN
transfer result and should be solved before claiming a fully independent
rootless first-run provisioner.

## Artifacts and provenance

- Branch: `feat/rootless-steamclienttermux-profile`.
- Run code state: commit `c0b3d28` (`docs: predeclare rootless R11 CDN payload
  test`).
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- Public ARM64 Steam seed was staged unchanged but intentionally not run.
- No Steam authentication data was read, copied, exported, or backed up.

## Exact cleanup verification

Only these R11 scopes were removed:

```text
/data/local/tmp/nova-rootless-r11-cdn-single-payload-20260811T082140Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r11/
/data/data/com.termux/files/home/.nova-rootless/
```

The APK stop action requested the Termux:X11 stop, followed by force-stopping
the Nova app. Verification returned:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_scope=absent
app_scope=absent
termux_scope=absent
rollback_rootfs=present
active_marker=present
free_space=86064708 KiB
```

The rooted rollback paths remained untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Next boundary

Predeclare a bounded updater-lifecycle comparison using only already-verified
payload URLs: first sequential single-request downloads, then a controlled
small parallel batch if the sequential path passes. Record per-request status,
bytes, digest, connection states, and file-commit timing. Keep Steam itself
out of that first comparison so a transport or file-lifecycle failure remains
separable from Steam's child updater protocol. In parallel, productize an
app-owned `bsdtar` bootstrap so rootless provisioning no longer needs the
preserved rooted image as an extractor source.
