# Nova rootless R14 — supervisor preflight predeclaration — 2026-08-11

Run ID: `nova-rootless-r14-supervisor-preflight-20260811T094222Z`
Sub-run: `R14-rootless-supervisor-preflight-and-id`
Status: predeclared after R13b closed extraction, package activation, and
symlink-aware idempotence.

## Controlled change

R14 advances only to the rootless supervisor boundary. Recreate the same
app-owned Holo archive extraction and 161-plus-two package closure, then run
`nova-rootless-proot-supervisor.sh preflight` against the activated closure
and one bounded guest `/usr/bin/id` command through `run --`.

The supervisor must use a fresh app-owned home, state, resolver file, short
PRoot temporary paths, and the staged public Steam client tree. No Steam
client command, SteamUI, Proton, Gamescope, controller bridge, audio bridge,
network transfer, or authentication data is part of this run.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code under test: commit `cd1cc7a` (`fix: accept symlinked rootless closure
  markers`); current branch includes the pushed R13b result.
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
- Steam client input: 51 files, approximately 330120 KiB; use the same R13
  key hashes.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r14-supervisor-preflight-20260811T094222Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r14/
/data/data/com.termux/files/home/.nova-rootless/
```

Retain the current static launcher assets. Preserve and verify the rooted
rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Supervisor environment

Use fresh app-owned paths and a resolver file populated from the device's
currently validated Android DNS:

```text
NOVA_ROOTLESS_PROFILE=files/launcher/nova-rootless-profile.tsv
NOVA_ROOTLESS_ROOTFS=files/r14/guest-rootfs-closure
NOVA_ROOTLESS_PROOT_BIN=files/r14/proot/proot
NOVA_ROOTLESS_PROOT_LOADER=files/r14/proot/loader
NOVA_ROOTLESS_PROOT_LIB_DIR=files/r14/proot/lib
NOVA_ROOTLESS_STATE=files/r14/state
NOVA_ROOTLESS_HOME=files/r14/home
NOVA_ROOTLESS_STEAM_CLIENT=files/r14/steam-client
NOVA_ROOTLESS_RESOLV_CONF=files/r14/resolv.conf
NOVA_ROOTLESS_PROOT_TMP_DIR=files/r14/proot-tmp
NOVA_ROOTLESS_TMP_DIR=files/r14/tmp
DISPLAY=127.0.0.1:77
```

Do not bind `/proc/net` or a SteamLinuxRuntime_4 shadow in this preflight;
those are later, separately attributable variables.

## Procedure and acceptance

1. Reread the lifecycle contract and verify clean R14 scopes/process/listener,
   free space, 19-file bootstrap state, and rollback state.
2. Install/hash-verify the pinned APK and start rootless X11. Recreate the
   unchanged archive and package-closure gates into `files/r14/` and verify
   all executable/input hashes.
3. Create the fresh app-owned home/state/resolver paths and run:

   ```text
   nova-rootless-proot-supervisor.sh preflight
   nova-rootless-proot-supervisor.sh run -- /usr/bin/id
   ```

   Require `nova_rootless_preflight=pass`, app UID rather than root in the
   supervisor record, the declared rootfs/proot/state/home/client paths, free
   space, resolver, short-temp paths, and a successful guest identity command.
   Require the home `.steam/steam -> /opt/nova-steam` link to remain inside the
   app-owned run scope.
4. Stop X11 through the APK, remove only the R14 runtime/Termux scopes, and
   verify no PRoot/helper residue, rollback preservation, and free space. Do
   not start Steam.

## Interpretation

A pass proves the activated rootless closure can be entered through the
supervisor with app-owned state and no privileged escape hatch. A failure is
classified as preflight path/ownership, resolver, temporary-directory,
runtime-version, or PRoot guest-exec behavior. Do not add Steam or networking
variables in the same run.
