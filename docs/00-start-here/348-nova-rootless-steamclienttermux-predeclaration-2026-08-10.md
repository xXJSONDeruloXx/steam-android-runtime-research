# Nova rootless SteamClientTermux profile — predeclaration

Status: branch-start predeclaration; no rootless Steam session has been run.
The branch starts from the pushed rooted bootstrap/OOBE baseline at `bc3e724`.

## Branch and preservation boundary

- Branch: `feat/rootless-steamclienttermux-profile`
- Parent: `main` at `bc3e724`
- Rooted rollback/happy path: unchanged and still represented by the direct
  Holo ARM64 glibc + Termux:X11 profile
- Rooted device state: the current signed-in Steam session is a comparison
  baseline only; its Steam data and authentication state must not be copied
  into the rootless profile
- Rootless data: a separate app-owned or user-owned runtime, Steam home, logs,
  sockets, and compatibility data

The existing rooted profile remains the acceptance baseline for display,
network, controller, audio, QR/OOBE, and signed-in Big Picture. Rootless work
must be additive and profile-selectable; it must not change
`/data/local/tmp/nova-holo-rootfs`, the active rooted marker, or the rooted APK
launcher behavior.

## Hypothesis

The native ARM64 Steam client can run without Magisk if the Holo/glibc rootfs
and Steam data are moved into a user-owned directory and entered through a
patched ARM64 PRoot boundary modeled on
[`steamclienttermux`](https://github.com/huntergdavis/steamclienttermux). The
rootless path must retain Android's existing network namespace and use a
user-owned X11/audio/input boundary; it cannot assume `chroot`, mounts,
`/dev/uinput`, or DRM/KMS.

The target project proves a useful runtime contract: patched PRoot, official
ARM64 Proton 11/Steam Linux Runtime 4 registration, private `/proc/net`
compatibility, loopback PulseAudio TCP, and bounded session logs. It does not
prove that Nova's APK UID can attach to the already-installed Termux:X11
server.

## Initial preflight finding

The attached device currently reports `com.termux.x11` and Nova, but no
`com.termux` base package. The rooted launcher starts X11 by invoking
Termux:X11's `CmdEntryPoint` through `app_process` with the APK on
`CLASSPATH`. A non-root Nova app UID cannot read that APK path:

```text
package:com.termux.x11
package:com.xjsonderulo.steamandroid.novalab
app_cannot_read_apk
```

Therefore the rootless branch must not reuse the rooted `CLASSPATH` launch
command. The first display experiment must explicitly test one of these
boundaries:

1. an exported Termux:X11 activity/server with a socket path that the rootless
   supervisor can access;
2. a user-installed Termux base plus Termux:X11, with the patched PRoot
   launched inside Termux; or
3. a future Nova-owned presentation/socket bridge.

Until one passes, a rootless process/rootfs smoke test is useful but is not
evidence of rootless Steam display success.

## Bounded experiment queue

### R0 — app/user process and rootfs boundary

Build or acquire the pinned ARM64 PRoot artifact outside Git, recording its
source commit, ordered patch-set hash, and binary SHA-256. Use a fresh
app-owned/user-owned Holo rootfs staging directory; do not copy rooted Steam
authentication data. Prove, without `su`:

- PRoot starts and exits cleanly as the app/user UID;
- the Holo dynamic loader, `/bin/sh`, `id`, `uname`, and `/proc/self/status`
  work through the guest view;
- Android DNS/HTTPS and the current default network are reachable;
- the guest can create private `/tmp`, D-Bus, and log paths; and
- no mount, uinput, rootfs, or rooted runtime process is touched.

Failure at this gate is a process-boundary result, not a Steam or Vulkan
result.

### R1 — rootless X11 attachment

Keep the display mode constant at direct X11. Test the selected X11 boundary
with a synthetic X client before Steam:

- record the X server package/version, display/socket path, ownership, mode,
  and transport;
- prove a rootless client can connect and render a changing test frame;
- preserve the rooted session separately and use a fresh rootless process/log
  baseline; and
- stop only the rootless process tree and verify no socket leak.

Do not treat launching the Termux:X11 Activity as proof that the X socket is
reachable from the Nova app UID.

### R2 — native ARM64 Steam UI

Use a fresh rootless Steam home and the same Steam ARM64 seed contract. Hold
display, CEF, network, and resolution variables constant. Require fresh Steam,
SteamUI, and webhelper logs, OOBE/QR evidence, and a clean stop. Any manual
login must happen in the rootless home; no rooted Steam files may be copied.

### R3 — official Runtime 4/Proton 11

Only after R2 passes, reproduce the target's explicit manifests in an isolated
profile:

- Proton 11 ARM64 AppID `4628740`, depot `4628741`;
- Steam Linux Runtime 4 ARM64 AppID `4185400`, depot `4185401`; and
- Proton's `require_tool_appid=4185400` relationship.

Run `_v2-entry-point --verb=run -- /bin/true` first, then one small game with
the rooted baseline's display/input/audio variables unchanged. A wrapper-only
success or an old rooted Steam log is not acceptance.

## Explicit non-goals for this branch start

- Do not modify or delete the rooted runtime, active marker, or signed-in Steam
  data.
- Do not export, back up, or copy Steam authentication secrets.
- Do not add Gamescope/AHardwareBuffer, DRM/KMS, or a second compositor to R0.
- Do not fake Wi-Fi/Bluetooth devices; Android's inherited socket path is the
  network data plane.
- Do not call `su` from a rootless profile, even as a fallback.
- Do not vendor Steam, Proton, runtime, game, or large PRoot binaries into
  this repository.

The first implementation should therefore be the smallest profile-aware
rootless supervisor/probe that can fail closed at R0/R1, followed by a fresh
rootless Steam UI run only after those boundaries are proven.
