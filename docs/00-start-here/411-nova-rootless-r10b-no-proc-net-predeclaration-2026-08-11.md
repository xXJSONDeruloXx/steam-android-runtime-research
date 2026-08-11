# Nova rootless R10b — no `/proc/net` shadow retry predeclaration — 2026-08-11

Run ID: `nova-rootless-r10b-no-proc-net-20260811T080512Z`
Sub-run: `R10b-rootless-x11-resolver-temp-no-proc-net`
Status: predeclared; the R10 result and cleanup were pushed before this
single-variable retry.

## Controlled change

R10 proved the Android-derived resolver, guest DNS/HTTPS, X11 transport, Holo
archive, 161-package closure, short PRoot temp path, and Steam manifest handoff.
The native updater then stalled at 108,440 of 657,758 KB with visible HTTPS
connections in `CLOSE_WAIT`.

R10b keeps every R10 input and command unchanged but omits the diagnostic
`/proc/net` route-shadow bind from the supervisor. The shadow exposes only
`route` and `ipv6_route` over the guest's normal `/proc/net` directory; this
retry tests whether the native updater needs its ordinary `/proc/net/tcp`
view to reap or manage its CDN sockets. The route snapshot may still be
captured for evidence, but it must not be passed as `NOVA_ROOTLESS_PROC_NET`.

No Gamescope/AHardwareBuffer, SteamUI patch, authentication data, controller,
audio, Proton, or Steam command change is allowed in this run.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `e322df9` (`docs: record rootless R10 resolver result`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `cff152751344ed96d41f1ec4ef7c0e8683ec6241807cb77c27919a1b92b9522e`.
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
- Debian GTK2 assets remain the two R10-verified files and hashes.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r10b-no-proc-net-20260811T080512Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10b/
/data/data/com.termux/files/home/.nova-rootless/
```

Rooted rollback paths remain outside scope and must be verified before and
after the run:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The app-owned resolver remains:

```text
nameserver 192.168.0.1
```

It must be regenerated only after fresh Android connectivity evidence confirms
the current validated DNS server. The exact supervisor environment is the R10
environment minus `NOVA_ROOTLESS_PROC_NET`:

```text
DISPLAY=127.0.0.1:77
NOVA_ROOTLESS_RESOLV_CONF=files/r10b/resolv.conf
NOVA_ROOTLESS_PROOT_TMP_DIR=files/r10b/proot-tmp
NOVA_ROOTLESS_TMP_DIR=files/r10b/tmp
```

## Sequence and acceptance

1. Reread the lifecycle contract. Verify the exact R10b app/remote/Termux
   scopes are absent, no matching PRoot/Steam/`:77` process remains, free
   space is sufficient, and both rooted rollback paths exist.
2. Install and verify the pinned APK in place, start a fresh Termux-owned
   `:77` through the APK, and require the app-UID loopback transport pass.
3. Capture current Android validated Wi-Fi/DNS state, stage the resolver, and
   capture the route snapshot without binding it into the guest.
4. Repeat the pinned Holo archive extraction and complete 161-package closure
   into fresh app-owned R10b candidates. Do not reuse R10 data or Steam files.
5. Require supervisor preflight to pass and confirm that its output contains no
   `nova_rootless_proc_net=` line. Run guest `getent` and bounded HTTPS before
   Steam, retaining the same manifest URL and display/flags.
6. Run:

   ```text
   /opt/nova-steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck
   ```

   Acceptance is a completed manifest/package update and a fresh updater or
   SteamUI frame. If the updater again stalls, record the exact progress,
   package count/bytes, socket states, and first Steam log boundary; do not
   change another variable in this run.
7. Stop the exact PRoot/Steam tree, stop Termux `:77` through the APK, remove
   only the declared R10b scopes, and verify no process/listener residue or
   rooted rollback change.

If R10b passes the bulk update, the next run may classify SteamUI/OOBE. If it
does not, the next single-variable diagnostic is a bounded guest curl of one
exact pending CDN package URL, not another Steam or compositor patch.
