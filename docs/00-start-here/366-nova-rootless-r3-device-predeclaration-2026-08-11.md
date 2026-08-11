# Nova rootless R3 device predeclaration — 2026-08-11

Run ID: `nova-rootless-r3-20260811T040543Z`
Status: predeclared; no prior R2 process, log, socket, or readiness result is
evidence for this run.

## Device and branch

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `6d7dafd` (`fix: harden rootless session log caps`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `e4fa393a018e2b35311a124848e6e17a852ce2c54d3f72a85b9f4084e4fa6830`.
- Rooted happy path: outside this run; preserve `/data/local/tmp/nova-holo-rootfs`,
  `/data/local/tmp/nova-active-runtime`, rooted Steam data, and display `:0`.
- Rootless display: fresh Termux:X11 `:77`, loopback TCP port `6077`.

## Exact rootless scope

All mutable state must remain under the app UID's new private tree:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r3-20260811T040543Z/
  home/
  steam-client/
  state/
  proot/
  artifacts/
```

The Holo rootfs is a read-only input:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
```

The previous `nova-rootless-r2-20260810T230711Z` app tree, temporary pushed
artifact tree, and dead `:77` PID/log are stale inputs. They must be captured
as needed and removed by exact path before R3 launch; no broad `/data/local/tmp`
or rooted-runtime cleanup is allowed.

## Selected artifacts

- Holo rootfs SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot binary SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- `libandroid-shmem.so` SHA-256:
  `84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731`.
- `libtalloc.so.2` SHA-256:
  `3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb`.
- Steam seed SHA-256:
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- `nova-zip-rebase` SHA-256:
  `3c76e5c886ef8eb38187b4639132837567676808500943236c68543b4ae417bc`.
- SteamRT3C archive SHA-256:
  `f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0`.

Runtime 4 ARM64 and Proton 11 ARM64 remain separate required artifacts. The
SteamRT3C archive is not interchangeable with Runtime 4 and cannot close the
Runtime 4 gate.

## Run sequence

1. Verify exact R2 scope is stopped and clean, then create the R3 app-private
   tree. Do not copy rooted Steam data or authentication secrets.
2. Start a fresh Termux:X11 `:77` through the installed APK bridge and record
   a new process/log baseline and listener check.
3. Snapshot the app-UID route view into R3 state and record whether a default
   route is visible.
4. Stage the hash-verified PRoot files and clean Steam seed, rebase/extract the
   seed, and run supervisor `preflight`, guest `id`, and a native ARM64 Steam
   boundary check.
5. If Steam reaches login, use only a normal QR login. Do not import the
   rooted session.
6. Do not claim Runtime 4/Proton, PulseAudio, game first-frame, controller,
   or audio success unless each has a fresh artifact and log gate.

## Cleanup and rollback

On every exit, stop only R3 `:77`/PRoot/Steam paths, verify port `6077` is
closed, pull fresh logs, and remove only R3 app-private state and temporary
R3 pushes. The known-good rooted runtime remains the rollback baseline.
