# Nova rootless R14 — supervisor preflight result — 2026-08-11

Run ID: `nova-rootless-r14-supervisor-preflight-20260811T094222Z`
Sub-run: `R14-rootless-supervisor-preflight-and-id`
Status: supervisor preflight and bounded guest identity passed; the exact run
was cleaned.

## Result

R14 recreated the app-owned archive and package closure, then entered the
activated candidate through the rootless supervisor without a privileged
escape path:

```text
nova_rootless_preflight=pass uid=10128 rootfs=files/r14/guest-rootfs-closure proot=files/r14/proot/proot
nova_rootless_state=files/r14/state home=files/r14/home steam_client=files/r14/steam-client
nova_rootless_free_kib=80286560
nova_rootless_proot_tmp_dir=files/r14/proot-tmp
nova_rootless_guest_tmp_dir=files/r14/tmp
nova_rootless_resolv_conf=files/r14/resolv.conf
nova_rootless_exec=proot display=127.0.0.1:77
uid=0(root) gid=0(root) groups=0(root),1004,1007,1011,1015,1028,1078,1079,3001,3002,3003,3006,3009,3011,3012,50128
```

The Android process UID recorded by preflight was `10128`; the guest-side
`id` output is the expected PRoot root identity. The fresh home contained only
the app-owned `.steam/steam -> /opt/nova-steam` link. The resolver was the
currently validated Android Wi-Fi DNS `192.168.0.1`, and the short app-owned
temporary paths were created with restrictive permissions.

Two setup-only corrections occurred before the accepted retry: the declared
empty `files/r14/home` directory had not yet been created, and the first
resolver write lost its separating space due to shell quoting. The resulting
failures were `missing_directory:files/r14/home` and
`resolv_conf_has_no_nameserver`; creating the declared directory and writing
the validated `nameserver 192.168.0.1` line produced the accepted run. No code,
runtime, package, or network variable changed.

No Steam command, SteamUI, Proton, Gamescope, controller bridge, audio bridge,
network transfer, or authentication data was used.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Predeclaration: `431-nova-rootless-r14-supervisor-preflight-
  predeclaration`.
- Code under test: commit `cd1cc7a` (`fix: accept symlinked rootless closure
  markers`); predeclaration commit `2d7a6e2`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08ad8e257a682`.
- Bootstrap manifest: 18 payload entries, SHA-256
  `8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Debian external manifest: two entries, SHA-256
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.
- Steam client input: 51 files, approximately 330120 KiB; same R13 key
  hashes were verified at the app UID.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- Fresh app-UID Termux:X11 transport passed on `127.0.0.1:6077`.
- The rooted rollback image was not used or modified. No Steam
  authentication data was read, copied, exported, or backed up.

## Exact cleanup verification

Only these R14 run scopes were removed:

```text
/data/local/tmp/nova-rootless-r14-supervisor-preflight-20260811T094222Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r14/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK launcher assets were retained. After cleanup:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_r14=absent
app_r14=absent
termux_rootless=absent
rollback_rootfs=present
active_marker=present
free_space=86113180 KiB
```

## Decision and next boundary

The rootless activated closure now passes extraction, package installation,
idempotent replay, supervisor preflight, and a guest exec. The next separate
experiment may run the public Steam seed's `steam --version` through this
supervisor, still without SteamUI, login, or game launch. Keep the state,
resolver, display, and package variables fixed and document the first runtime
or loader boundary.
