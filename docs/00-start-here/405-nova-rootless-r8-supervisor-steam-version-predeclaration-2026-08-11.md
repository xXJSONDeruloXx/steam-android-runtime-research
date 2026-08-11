# Nova rootless R8 — supervisor and Steam version predeclaration — 2026-08-11

Run ID: `nova-rootless-r8-supervisor-steam-version-20260811T064948Z`
Sub-run: `R8-supervisor-steam-version`
Status: predeclared; R7g passed and its exact app-private and remote trees were
removed before this run.

## Purpose and controlled change

R7g proved the app-owned Holo archive, the complete 161-package Holo closure,
the Debian GTK2/audio assets, and the public ARM64 SteamUI dependency
boundary. R8 keeps those inputs unchanged and adds only the rootless
supervisor boundary:

1. run the supervisor `preflight` contract;
2. run the public seed's
   `/opt/nova-steam/steamrtarm64/steam --version` through the supervisor; and
3. capture fresh, run-scoped stdout, stderr, and supervisor state.

This run must not start Termux:X11, an X11 display, SteamUI, Gamescope, a
controller bridge, a login session, or a game. It must not patch SteamUI,
modify the rooted runtime, or copy authentication data.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `2b9143b` (`docs: record rootless R7g closure pass`).
- Rebuilt APK/assets SHA-256:
  `1c246f292053b0e7463874ff376c4c75c5f180e61d0e767c78297481db302507`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo SteamUI manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.

The APK artifact is a provenance record for the current helper/assets build;
this low-level run stages its files manually under the app UID and does not
replace the installed application package. A later UI run will explicitly
install and verify the APK before claiming an app-path result.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r8-supervisor-steam-version-20260811T064948Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r8-supervisor-steam-version-20260811T064948Z/
```

The app-private tree contains only the R8 rootfs archive, extracted guest and
closure candidates, PRoot loader/library inputs, profile/scripts, public Steam
seed, supervisor state, and fresh run logs. The supervisor's app-owned home is
new and contains no prior Steam data.

Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Environment and acceptance

The supervisor must receive absolute app-private paths for the R8 scope:

```text
NOVA_ROOTLESS_PROFILE=$BASE/scripts/nova-rootless-profile.tsv
NOVA_ROOTLESS_ROOTFS=$BASE/guest-rootfs-closure
NOVA_ROOTLESS_PROOT_BIN=$BASE/proot/proot
NOVA_ROOTLESS_PROOT_LOADER=$BASE/proot/loader
NOVA_ROOTLESS_PROOT_LIB_DIR=$BASE/proot/lib
NOVA_ROOTLESS_STATE=$BASE/state
NOVA_ROOTLESS_HOME=$BASE/home
NOVA_ROOTLESS_STEAM_CLIENT=$BASE/steam-client
DISPLAY=:77
```

Acceptance is limited to a fresh `preflight` pass and one bounded
`steam --version` invocation through PRoot. The result must capture the exit
status, version output if present, fresh supervisor state/log paths, and any
loader, runtime, IPC, or display prerequisite failure. A successful version
command is not a Steam UI or rendering result; it only authorizes a separate
Termux:X11 predeclaration.

## Cleanup

After the result is captured, remove only the exact R8 app-private and remote
trees above. Verify no matching PRoot, Steam, or helper process remains, then
verify the rooted rollback paths still exist. Commit and push the result before
starting any X11 session.

