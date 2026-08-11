# Nova rootless R3 — Steam home layout boundary — 2026-08-11

Run: `nova-rootless-r3-20260811T040543Z`
Sub-run: `R3c-proc`
Status: `/proc` visibility passed; Steam reached its standard home-layout
check and stopped before UI.

## Result

With `--sysvipc` and the new `/proc` bind, the clean ARM64 Steam seed reached
its own startup banner:

```text
Startup - Steam Client launched with: '/opt/nova-steam/steamrtarm64/steam' '--version'
```

The next failure was:

```text
src/steamexe/main.cpp (1397) : Assertion Failed: Steam data link does not exist, client is misconfigured, cannot continue: /home/nova/.steam/steam
```

This is a rootless filesystem-layout omission, not a rendering or Vulkan
failure. The fresh R3c home had no authentication data and no Steam data link.

## R3d change

The supervisor now idempotently creates the app-owned guest link:

```text
/home/nova/.steam/steam -> /opt/nova-steam
```

It accepts only that exact existing symlink, refuses an unexpected symlink,
and refuses to replace a real file or directory. This keeps a clean rootless
home safe while matching the conventional Steam layout used by the comparison
launcher.

## Evidence boundary

R3c proves fresh `/proc/self` visibility and Steam startup through the home
layout check. It does not prove Steam UI, QR/OOBE, Runtime 4, Proton, Vulkan,
WSI, audio, controller input, networking inside Steam, or a game frame.
