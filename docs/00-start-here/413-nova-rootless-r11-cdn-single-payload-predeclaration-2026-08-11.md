# Nova rootless R11 — single CDN payload predeclaration — 2026-08-11

Run ID: `nova-rootless-r11-cdn-single-payload-20260811T082140Z`
Sub-run: `R11-rootless-x11-resolver-temp-single-steam-cdn-payload`
Status: predeclared after R10b's result and cleanup were committed and pushed.

## Question

R10 and R10b both passed Android Wi-Fi, app-UID X11 transport, guest DNS,
bounded HTTPS, Holo extraction, the complete 161-package closure, and Steam's
manifest download. Both then stalled during the native Steam client's
multi-request package update. R10 used a route-only `/proc/net` shadow; R10b
did not. R10b reproduced the stall, so the next boundary is one exact CDN
payload through the same rootless guest rather than another Steam or
compositor change.

This run tests only whether a representative package URL can be downloaded
to an app-owned guest-visible file, with its expected byte count and digest
recorded. It does not launch Steam, modify Steam data, run an updater, patch
SteamUI, or touch Gamescope/AHardwareBuffer.

## Controlled input

The exact payload is the first package listed by the R10b Steam manifest:

```text
https://client-update.steamstatic.com/tenfoot_images_all.zip.vz.193cb8c4eb4446698ea2c0a9e8c4e6b6a623dac7_5572671
```

The filename declares an expected payload size of `5,572,671` bytes and the
Steam CDN content identifier `193cb8c4eb4446698ea2c0a9e8c4e6b6a623dac7`.
R11 changes no resolver, PRoot, rootfs, package closure, X11, or Android
network behavior from R10b. The only behavioral change is replacing the
native Steam updater with a bounded guest `curl` of this one URL.

## Device, artifact, and safety boundary

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `cff152751344ed96d41f1ec4ef7c0e8683ec6241807cb77c27919a1b92b9522e`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

The run has one fresh mutable identity:

```text
/data/local/tmp/nova-rootless-r11-cdn-single-payload-20260811T082140Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r11/
/data/data/com.termux/files/home/.nova-rootless/
```

The rooted happy-path rollback remains protected and must be verified before
and after the run:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Do not read, copy, export, or back up Steam authentication data. Do not reuse
R10/R10b app-owned rootfs, state, home, or Steam files. The host staging input
may be reused as immutable source material after its hashes are rechecked.

## Procedure and acceptance

1. Reread the lifecycle contract. Verify no R11 scope, PRoot/Steam process,
   `:77` listener, or stale Termux helper remains; verify free space and both
   rooted rollback paths.
2. Install/verify the pinned APK, start a fresh Termux-owned `:77`, and require
   the app-UID loopback transport probe to pass.
3. Capture fresh Android validated Wi-Fi/DNS state. Stage only the current
   validated DNS server in the app-owned resolver and record its hash.
4. Extract the pinned Holo archive and complete the same 161-package closure
   into fresh app-owned `files/r11/guest-rootfs-closure`. Do not bind a
   `/proc/net` shadow.
5. Run supervisor preflight with the R10b bindings:

   ```text
   DISPLAY=127.0.0.1:77
   NOVA_ROOTLESS_RESOLV_CONF=files/r11/resolv.conf
   NOVA_ROOTLESS_PROOT_TMP_DIR=files/r11/proot-tmp
   NOVA_ROOTLESS_TMP_DIR=files/r11/tmp
   ```

   Require no `nova_rootless_proc_net=` line. Run guest `getent` and a
   bounded HEAD/HTTPS probe before the payload request.
6. Create `/run/nova/cdn` in the guest and run exactly one bounded transfer:

   ```text
   /usr/bin/curl --fail --location --connect-timeout 20 --max-time 180 \
     --output /run/nova/cdn/tenfoot_images_all.zip.vz.193cb8c4eb4446698ea2c0a9e8c4e6b6a623dac7_5572671 \
     https://client-update.steamstatic.com/tenfoot_images_all.zip.vz.193cb8c4eb4446698ea2c0a9e8c4e6b6a623dac7_5572671
   ```

   Capture curl's exit status, headers, elapsed behavior, app-owned file
   size, and SHA-256. A pass requires exactly 5,572,671 bytes and a stable
   digest; a failure must preserve the exact curl error and partial-file size.
7. Do not launch Steam after the payload test. Stop the exact X11 session,
   remove only the three R11 scopes, and verify no process/listener residue,
   rollback preservation, and recovered free space.

## Interpretation

- A complete payload proves the basic guest CDN transfer path and shifts the
  next investigation to the native updater's concurrency, socket reaping, or
  file-commit lifecycle.
- A timeout, short read, or digest/size mismatch makes the rootless guest CDN
  transfer itself the active blocker.
- Either result must be recorded and pushed before another variable is
  introduced. No Steam or Gamescope patch is justified by this predeclaration.
