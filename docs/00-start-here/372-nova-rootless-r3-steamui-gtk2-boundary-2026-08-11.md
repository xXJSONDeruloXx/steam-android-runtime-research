# Nova rootless R3 — updated SteamUI GTK2 boundary — 2026-08-11

Run: `nova-rootless-r3-20260811T040543Z`
Sub-run: `R3f-updated`
Status: the updated ARM64 Steam client verified successfully, then stopped
before UI because the Holo guest is missing GTK2.

## Result

R3f used a new app-private home and state against the already-updated client
tree produced by R3e. The client tree contains
`package/steam_client_linuxarm64.installed`; the update itself is therefore
not being repeated in this sub-run. The fresh supervisor log recorded:

```text
nova_rootless_preflight=pass uid=10128 rootfs=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs proot=files/nova-rootless-r3-20260811T040543Z/proot/bin/proot
nova_rootless_state=files/nova-rootless-r3-20260811T040543Z/subruns/r3f-updated/state home=files/nova-rootless-r3-20260811T040543Z/subruns/r3f-updated/home steam_client=files/nova-rootless-r3-20260811T040543Z/subruns/r3f-updated/steam-client
nova_rootless_free_kib=77898508
nova_rootless_proc_net=files/nova-rootless-r3-20260811T040543Z/subruns/r3f-updated/state/config/proc-net
nova_rootless_exec=proot display=127.0.0.1:77
```

The updated client launched through the same direct Termux:X11 profile and
reached its normal verification boundary. Its process output then stopped at
the first guest-side UI dependency:

```text
Startup - updater built Aug 3 2026...
Steam Client launched ...
Verification complete
UpdateUI: skip show logo
Destroy window
dlmopen /opt/nova-steam/steamrtarm64/steamui.so failed: libgtk-x11-2.0.so.0: cannot open shared object file: No such file or directory
dlmopen steamui.so failed: libgtk-x11-2.0.so.0: cannot open shared object file: No such file or directory
Failed to load steamui.so - dlerror(): (null)
Shutdown
Fatal error: Failed to load steamui.so
```

The client bootstrap log independently records `Verification complete` and
`Shutdown` at `2026-08-11 04:33:55`; no authentication or Steam data was
imported.

## Package-closure check

The immutable Holo rootfs used as the R3 input does not contain any of these
candidate libraries:

```text
absent=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/usr/lib/aarch64-linux-gnu/libgtk-x11-2.0.so.0
absent=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/usr/lib/libgtk-x11-2.0.so.0
absent=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/usr/lib/aarch64-linux-gnu/libgtk-3.so.0
```

The current direct Termux:X11 package manifest includes X11 client libraries
but no GTK2 package. This makes the failure a concrete guest package-closure
boundary, not a Gamescope/AHardwareBuffer, Vulkan, WSI, network, or Steam
authentication failure.

## Evidence boundary and next step

R3f proves the rootless path through Android networking, PRoot SysV IPC,
`/proc`, `/dev`, the conventional Steam home link, Steam client update, and
post-update client verification. It does not yet prove a SteamUI frame,
QR/OOBE, Runtime 4, Proton, Vulkan, audio, controller input, or a game frame.

The next change is to add a verified GTK2 package and its complete ARM64
dependency closure through the authoritative Holo provisioning path. It must
be staged as a new rootless candidate or overlay; the known-good rooted Holo
rootfs remains immutable rollback input. The next launch must use fresh
R3-derived home/state and a new sub-run identity.
