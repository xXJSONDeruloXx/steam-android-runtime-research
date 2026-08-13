# Nova rooted Runtime 4 root `bwrap` proxy — 2026-08-13

## Purpose

The real Steam client runs as UID 501 on Nova, while Android denies that UID
the user namespace needed by Pressure Vessel's `bwrap`. The narrow experiment
was to keep Steam, Proton, and the game identity unchanged and route only the
Pressure Vessel `bwrap` request through a root process already authorized by
the rooted launcher.

This is an infrastructure result, not a game success. No GameNative payload or
Steam authentication data was used.

## Provenance

- Nova checkout: `feat/rooted-cef-gpu-games`, baseline `d48ea9f807677b7cc272ced29b5a976f7c670dbc`, with the proxy work uncommitted when this record was made.
- Sibling checkout: `/Users/kurt/Developer/steamclienttermux`, clean `main` at `8d14c10195b34fe2714ba59df1680df27a852532`.
- Device: Nova serial `d234a848`, rooted Android 13.
- Rootfs: `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs`.
- Proxy binary: `android/nova-lab/build/nova-runtime4-bwrap-proxy`, SHA-256
  `35808f6e03021a5d92f216ec9f94c9f0979e295e45bfdbea9e1e3abbf1b66ee3`.
- Client protocol: `nova-runtime4-bwrap-proxy-client.py`, SHA-256
  `e3194bfd31b8e23449d2ab537b9b8c9beb45ef298d4bce8eb381eb33876e46b9`.

## Findings

1. A fresh UID 501 invocation of the official Runtime 4 `srt-bwrap` failed at
   the Android user-namespace boundary:

   ```text
   bwrap: Creating new namespace failed, likely because the kernel does not support user namespaces.
   ```

2. Binding the rootfs onto itself in the private mount namespace was required
   for a root `bwrap` invocation to pass its `/` propagation setup. The helper
   now exposes this only with `NOVA_X11_BIND_ROOT_MOUNT=1`.

3. Running the whole Steam client as root exited before a valid Steam UI/game
   handoff, so it was discarded. The accepted design keeps Steam UID 501 and
   starts a root proxy from the already-root launcher.

4. The proxy forwards the exact `bwrap` argv, environment, and inherited file
   descriptors. The environment is required because Pressure Vessel resolves
   commands through `PATH`; the descriptor table is required because Runtime 4
   passes its generated argument list through a memfd (for example,
   `--args 22`). Descriptor restoration uses a high temporary range and is
   collision-safe before `bwrap` execs.

## Fresh smoke

Run ID: `nova-runtime4-root-proxy-real-20260813T`.

The command ran the existing rooted Geometry Wars Proton harness in
`runtime4-smoke` mode as UID 501, with:

```text
NOVA_X11_BIND_ROOT_MOUNT=1
NOVA_X11_ROOT_PROXY=1
PRESSURE_VESSEL_BWRAP=/opt/nova-kgsl-driver/nova-runtime4-bwrap-root.sh
STEAM_ARM64_REAL_BWRAP=/opt/nova-steam/runtime/SteamLinuxRuntime_4-arm64/pressure-vessel/libexec/steam-runtime-tools-0/srt-bwrap
```

The fresh run crossed the actual Runtime 4 entry point and completed with
status 0. Expected rooted-guest warnings remained (locale generation, missing
gid 20 record, and the absent X11 filesystem socket while the abstract socket
was available), but there was no user-namespace error and no bad-descriptor
failure.

After the run, the exact proxy, `srt-bwrap`, Proton, Wine, FEX, and
`winedevice` process scan was empty, and the private proxy socket was absent.
The run-scoped compatibility and Proton-log directories were removed.

## Boundary

This proves the official Runtime 4 `bwrap` privilege boundary can be crossed
without replacing Nova's rooted direct-X11 architecture or running Steam as
root. It does not prove a game frame. The next fresh experiment is the real
Steam client launching installed 8-Bit Bayonetta, followed by Geometry Wars
under the same proxy profile if the first game still fails.
