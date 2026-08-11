# Nova rootless R3 — `/proc` path boundary — 2026-08-11

Run: `nova-rootless-r3-20260811T040543Z`
Sub-run: `R3b-sysvipc`
Status: SysV IPC flag fixed the first Steam initialization failure; the next
guest path fix is staged for R3c.

## R3b result

Adding `--sysvipc` to all supervisor bind combinations removed the previous
Steam errors about unimplemented thread primitives and semaphore creation.
The same clean seed and Holo rootfs then advanced to:

```text
src/steamexe/steamglobalinstance.cpp (384) : m_NamedPipe >= 0
src/steamexe/main.cpp (1330) : Plat_GetExecutablePath returned false
```

No Steam UI, Vulkan, or X11 client was reached. The PRoot process exited
without leaving a matching R3 process behind.

## Isolated guest observation

With the only supervisor change being `--sysvipc`, guest probes reported:

```text
cat: /proc/self/cmdline: No such file or directory
'/opt/nova-steam/steamrtarm64/steam'
```

The guest `/proc/self/cmdline` path was absent while the bound Steam file was
visible. That explains why Steam’s executable-path lookup fails independently
of the earlier IPC error. The comparison `steamclienttermux` launcher uses
`proot-distro`’s conventional `/proc` bind; Nova’s supervisor had only bound a
validated `/proc/net` shadow.

## R3c change

The supervisor now binds the app-visible host `/proc` at `/proc` before
overlaying the validated route shadow at `/proc/net`. This is a single
presentation-of-process-metadata change; it does not add `su`, `chroot`, or a
root-owned namespace. R3c must repeat the `/proc/self` probes and the native
Steam boundary with fresh state and a fresh `:77` process.

This does not claim the full comparison PRoot patch set. Robust-list emulation,
Pressure Vessel path handling, and Runtime 4 remain separate gates.
