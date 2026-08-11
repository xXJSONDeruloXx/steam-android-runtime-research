# Nova rootless R3 — `/dev` path boundary — 2026-08-11

Run: `nova-rootless-r3-20260811T040543Z`
Sub-run: `R3d-steamhome`
Status: Steam home layout passed; the next guest device-layout fix is staged
for R3e.

## Result

The supervisor created and verified:

```text
/home/nova/.steam/steam -> /opt/nova-steam
```

Steam then reached its platform initialization and stopped at:

```text
src/tier0/platform_posix.cpp (841) : s_dev_urandom_fd >= 0
src/tier0/platform_posix.cpp (841) : Fatal assert; application exiting
```

This is the next missing standard Linux guest device boundary. It occurred
after the SysV IPC, `/proc`, and Steam-home fixes, before UI or graphics.

## R3e change

The supervisor now binds the app-visible host `/dev` at `/dev` in every bind
combination, alongside `/proc` and the validated `/proc/net` overlay. R3e must
repeat the fresh guest probes and native Steam command with no other variable
change.

## Evidence boundary

R3d proves PRoot identity, `/proc` visibility, the conventional Steam data
link, and the native Steam path up to platform device initialization. It does
not prove Steam UI, QR/OOBE, Runtime 4, Proton, Vulkan, WSI, audio, controller
input, networking inside Steam, or a game frame.
