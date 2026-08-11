# Nova rootless R10 — resolver and short-temp handoff predeclaration — 2026-08-11

Run ID: `nova-rootless-r10-resolver-temp-20260811T073059Z`
Sub-run: `R10-rootless-x11-resolver-temp-steam-handoff`
Status: predeclared; run only after this record and the implementation commit
are pushed.

## Hypothesis

R9 reached the Steam updater through the app-UID Termux:X11 TCP display, but
the Holo guest had no `/etc/resolv.conf`, and PRoot reported
`proot-shm-helper: Temporary path too long`. Android itself had validated Wi-Fi,
DNS, and direct TCP connectivity. R10 changes only these two rootless guest
contracts:

1. bind an app-owned resolver file containing the current Android DNS server;
2. use short app-owned host paths for `PROOT_TMP_DIR` and the guest `/tmp`,
   while explicitly setting guest `TMPDIR=/tmp`.

The resolver is not a new network tunnel. It is a narrowly scoped translation
of the Android connectivity state already observed in R9. The R10 run must
prove guest DNS before starting Steam and must retain the raw Android evidence
alongside the result.

## Exact source and artifacts

- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `ff870b8` (`feat: add rootless resolver and short temp bindings`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`.
- APK SHA-256:
  `cff152751344ed96d41f1ec4ef7c0e8683ec6241807cb77c27919a1b92b9522e`.
- Holo ARM64 archive: `android/nova-lab/build/holo-rootfs/system.rootfs.zst`.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Public ARM64 Steam seed SHA-256:
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- Rooted comparison/rollback paths that must remain untouched:
  `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs` and
  `/data/local/tmp/nova-active-runtime`.

## Declared device scope

The target is the attached Retroid Pocket Nova, serial `675a2365`, API 33,
`arm64-v8a`. The APK will be installed in place with `adb install -r` after
recording the installed package path and SHA-256. No Steam authentication data
will be read, copied, exported, or backed up.

The fresh app-owned scope is intentionally short to avoid recreating R9's path
length condition:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10/rootfs
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10/guest-rootfs
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10/proot-tmp
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10/tmp
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10/resolv.conf
/data/local/tmp/nova-rootless-r10-resolver-temp-20260811T073059Z
```

The resolver file will be staged only after a fresh Android connectivity
inspection. The R9 observation was `nameserver 192.168.0.1`; R10 must reject
the run if the fresh validated DNS state does not provide a current server.
The intended file is:

```text
nameserver <fresh-validated-Android-DNS-server>
```

The supervisor will receive these explicit bindings on every invocation:

```text
NOVA_ROOTLESS_RESOLV_CONF=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10/resolv.conf
NOVA_ROOTLESS_PROOT_TMP_DIR=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10/proot-tmp
NOVA_ROOTLESS_TMP_DIR=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r10/tmp
DISPLAY=127.0.0.1:77
```

## Sequence and acceptance

1. Reread the lifecycle contract and perform exact-scope cleanup. Verify no
   prior R10 process, listener, app scope, or report remains; verify the
   rooted rollback paths still exist and record free space.
2. Install/verify the APK and launch its rootless Termux:X11 path. Record the
   Termux-owned `:77` process, loopback listener, APK log, and artifact hash.
3. Capture fresh Android Wi-Fi/DNS evidence, stage the resolver file under the
   declared app scope, and run the transport and route probes.
4. Extract the pinned Holo archive through the rooted versioned `bsdtar`
   bootstrap without modifying the rooted source tree. Validate the complete
   161-entry Holo closure and stage the public ARM64 Steam seed.
5. Run supervisor preflight with the three explicit bindings. Require a pass,
   a short temp-path log, and a resolver log before invoking Steam.
6. Inside the guest, run `getent hosts client-update.steamstatic.com` and a
   bounded HTTPS probe before the Steam command. Record whether DNS and HTTPS
   succeed, whether the temporary-path warning is absent, and the exact Steam
   exit status/log boundary.
7. If the manifest handoff succeeds, continue only until a fresh Steam frame or
   a clearly classified next blocker. Do not claim SteamUI/OOBE success from an
   updater surface alone. If it fails, classify the first failure layer and
   stop rather than changing a second variable.
8. Stop Termux:X11 through the APK path, remove only the declared R10 app,
   Termux, and rooted temporary scopes, and verify no PRoot/Steam/X11 process,
   listener, or bridge residue remains. Preserve the versioned rooted rollback.

Acceptance for this run is ordered:

- Android network state and app-UID loopback X11 transport remain passing;
- guest resolver validation and HTTPS manifest reachability pass;
- `proot-shm-helper: Temporary path too long` is absent;
- Steam reaches a fresh updater handoff or produces a new, layer-specific
  failure record;
- cleanup and rollback verification pass.

The experiment does not modify Gamescope/AHardwareBuffer, patch Steam views,
or copy existing Steam data. SteamUI login/OOBE remains a later gate after the
network and PRoot path boundary is proven.
