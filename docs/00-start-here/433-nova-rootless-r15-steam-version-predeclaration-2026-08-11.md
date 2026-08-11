# Nova rootless R15 — Steam version predeclaration — 2026-08-11

Run ID: `nova-rootless-r15-steam-version-20260811T094945Z`
Sub-run: `R15-rootless-supervisor-steam-version`
Status: predeclared after R14 passed supervisor preflight and a bounded guest
identity command.

## Controlled change

R15 keeps the complete R14 provisioning and supervisor environment unchanged
and runs exactly one public ARM64 Steam seed command through the supervisor:

```text
/opt/nova-steam/steamrtarm64/steam --version
```

This is a runtime/loader boundary only. Do not start SteamUI, use
`-gamepadui`, perform a client update, open a display window, log in, launch
Proton, or read/copy/export authentication data. Do not bind `/proc/net` or a
SteamLinuxRuntime_4 shadow.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code under test: commit `cd1cc7a` (`fix: accept symlinked rootless closure
  markers`); current branch includes the R14 result.
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
- Public Steam client input: 51 files, approximately 330120 KiB. Key hashes:
  `steamrtarm64/steam`:
  `cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85`;
  `steamrtarm64/steamui.so`:
  `972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0`;
  `steamrtarm64/steamwebhelper`:
  `3901a2af2b9348a4b6381162c3913d607fcf7e959996b8388fd571f4a0d1cd8f`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r15-steam-version-20260811T094945Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r15/
/data/data/com.termux/files/home/.nova-rootless/
```

Retain the static APK launcher assets. Preserve and verify the rooted rollback
paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Supervisor environment

Use the exact R14 environment with only the run scope changed:

```text
NOVA_ROOTLESS_PROFILE=files/launcher/nova-rootless-profile.tsv
NOVA_ROOTLESS_ROOTFS=files/r15/guest-rootfs-closure
NOVA_ROOTLESS_PROOT_BIN=files/r15/proot/proot
NOVA_ROOTLESS_PROOT_LOADER=files/r15/proot/loader
NOVA_ROOTLESS_PROOT_LIB_DIR=files/r15/proot/lib
NOVA_ROOTLESS_STATE=files/r15/state
NOVA_ROOTLESS_HOME=files/r15/home
NOVA_ROOTLESS_STEAM_CLIENT=files/r15/steam-client
NOVA_ROOTLESS_RESOLV_CONF=files/r15/resolv.conf
NOVA_ROOTLESS_PROOT_TMP_DIR=files/r15/proot-tmp
NOVA_ROOTLESS_TMP_DIR=files/r15/tmp
DISPLAY=127.0.0.1:77
```

## Procedure and acceptance

1. Reread the lifecycle contract and verify clean R15 scopes/process/listener,
   free space, 19-file bootstrap state, and rollback state.
2. Install/hash-verify the pinned APK and start rootless X11. Recreate the
   unchanged archive extraction, package closure, symlink-aware idempotence,
   and supervisor preflight gates into `files/r15/`.
3. Run the declared `steam --version` command through the supervisor, capturing
   exact stdout, stderr, exit status, supervisor log, and any child process
   residue. A pass is a successful version response with no unexpected
   updater/display/runtime side effect; a failure must identify the first
   loader, runtime, IPC, or Steam prerequisite boundary.
4. Stop X11 through the APK, remove only the R15 runtime/Termux scopes, and
   verify no PRoot/Steam/helper residue, rollback preservation, and free space.

## Interpretation

A pass authorizes a separate SteamUI/X11 predeclaration. A failure remains a
runtime/loader result; do not add login, network, Proton, Gamescope, or
authentication variables in the same run.
