# Nova rootless R3 — Steam bootstrap update result — 2026-08-11

Run: `nova-rootless-r3-20260811T040543Z`
Sub-run: `R3e-dev`
Status: Steam bootstrap/update passed; post-update client relaunch remains a
separate fresh-state gate.

## Evidence

After the `/dev` bind fix, the clean ARM64 seed reached the real Steam
bootstrapper and downloaded the full current client update over the Android
network namespace. The fresh guest log recorded:

```text
Downloading update (664432 of 664432 KB)...
Download Complete.
Extracting package...
Installing update...
Cleaning up...
Update complete, launching...
Shutdown
```

The app-private client tree grew to approximately 3.0 GiB and contains
`package/steam_client_linuxarm64.installed`. The process ended without a
matching R3 PRoot/Steam process remaining. ADB briefly disappeared during the
long write/extract phase and then returned; the on-device bootstrap log proves
the update completed after the transport recovered.

The rootless X11 server remained separate and reachable on `127.0.0.1:6077`.
No rooted Steam data or authentication secret was read or copied.

## Boundary

This proves networked Steam client bootstrap/update through rootless PRoot,
`/dev`, `/proc`, SysV IPC, the Steam home link, and direct Termux:X11. It does
not yet prove the updated client’s UI, QR/OOBE, Runtime 4, Proton, Vulkan,
audio, controller input, or a game frame. The next replay must use a fresh
home/state and fresh logs against the already-updated client.
