# Nova rootless R24 — matched Valve media-suite result — 2026-08-11

Run ID: `nova-rootless-r24-matched-media-suite-steamui-20260811T122724Z`;
sub-run: `R24-rootless-supervisor-matched-media-suite`.

Status: complete; the seven-file Valve media family removed the R22/R23
FFmpeg allocator and provider failures, but SteamUI stopped at a new SDL3 ABI
boundary before a Steam frame was created.

## Result

R24 kept the R22/R23 rootless direct-X11 profile unchanged and staged exactly
the seven regular Valve ARM64 media files declared in [doc
457](457-nova-rootless-r24-matched-media-suite-predeclaration-2026-08-11.md)
beside the raw stable client's `libvideo.so`. `package/beta` was absent, the
raw stable client remained build `1785799196`, and `libvideo.so` retained its
raw-seed hash:

```text
libvideo.so
size=9698888
sha256=e62d1affedcd0c5f26caf496c7c191a62bdf3556bd759fe28862840bfa13b375
```

The launch command reached the X11 updater and passed the previous media
boundaries:

```text
Verification skipped
Verification complete
Using update UI: xwin
Create window
```

SteamUI then failed while loading the client-side `steamui.so`:

```text
dlmopen /opt/nova-steam/steamrtarm64/steamui.so failed:
/opt/nova-steam/steamrtarm64/steamui.so: undefined symbol: SDL_TryLockJoysticks, version SDL3_0.0.0
dlmopen steamui.so failed: dlerror(): (null)
Failed to load steamui.so - dlerror(): (null)
Shutdown
```

This is a new dynamic-loader dependency failure, not a Vulkan, WSI, X11
surface, Gamescope, or AHardwareBuffer result. No `steamwebhelper` process,
SteamUI frame, Vulkan initialization, or game launch was reached. The
seven-file FFmpeg closure is therefore sufficient to cross the R22/R23 media
failures but is not sufficient to load the current `steamui.so` against the
Holo closure.

## Provisioning and evidence

The app-owned preparation gates passed without changing a repository script or
the preserved rooted runtime:

```text
rootfs archive size=384971555
rootfs archive sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
Holo/UI-audio package closure=161 packages
preflight free_kib=81205164
DISPLAY=127.0.0.1:77
Termux:X11=127.0.0.1:6077, pid=7721
package/beta=absent
```

The first automated X11 readiness poll reported a timeout because its remote
`awk` expression was over-escaped. Direct inspection immediately afterward
found the fresh `termux-x11` PID and the listening `127.0.0.1:6077` socket; the
Steam result above is therefore classified against a live fresh X11 session.

Fresh host artifacts captured before teardown:

```text
/tmp/nova-r24-steam-noverifyfiles-command.log
  size=3534
  sha256=5335319221f8f3b2d261bcdcd11d836288cd636474fb844a18611a6933b9c703
/tmp/nova-r24-bootstrap_log.txt
  size=683
  sha256=53f94214668b1b616197425c0e1064267af4822a85c7f22d1b0df2350003718a
/tmp/nova-r24-updateui_child.txt
  size=288
  sha256=8ba97a901c6925bc1e146cb92cbd59fe422b862f2a3dc9ae410ebd2efb20f686
/tmp/nova-r24-supervisor-preflight.log
  size=779
  sha256=de3b705521a51fd801e924bbe2e318bf282f8e65907dc7fbb5bb23ff4bf26628
/tmp/nova-r24-rootless-supervisor.log
  size=1604
  sha256=43195a96c30f77782e43f94275a2a5790e3cb32022add503aa07474c98dc1a7b
/tmp/nova-r24-matched-media-suite-failure.png
  PNG 1280x960, size=102456
  sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
```

The screenshot is the Nova launcher surface rather than SteamUI, matching the
absence of a loaded Steam window. The captured `bootstrap_log.txt` records the
same `-noverifyfiles` command, skipped verification, and shutdown; the
`updateui_child.txt` records the fresh X11 update-window creation.

## Cleanup and rollback

The exact R24 scopes were removed:

```text
/data/local/tmp/nova-rootless-r24-matched-media-suite-steamui-20260811T122724Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r24/
/data/data/com.termux/files/home/.nova-rootless/
```

Post-cleanup verification reported:

```text
remote_r24=absent
app_r24=absent
termux_rootless=absent
listening_port_6077=absent
matching exact Steam/SteamUI/webhelper/PRoot/termux-x11/Xwayland processes=none
rollback_rootfs=present
rollback_active=present
free_kib=86128436
```

An immediate `/proc/net/tcp` snapshot still showed one loopback connection in
TCP state `06` (`TIME_WAIT`) for the former display port; there was no listener
or owning process. This is normal kernel connection teardown, not a leaked
Termux:X11 bridge socket. No Steam authentication secret was read, copied, or
exported.

## Decision and next step

Retain the seven-file Valve media family as a valid closure improvement, but do
not add more files or aliases on the device yet. The next step is a host-only
SDL3 provider audit: compare the `SDL_TryLockJoysticks@@SDL3_0.0.0` export and
the complete SDL3 dependency family in the completed Valve ARM64 bootstrap
with the Holo package closure and the raw stable seed. Then predeclare one
fresh run that changes only the smallest justified SDL3 family. Do not patch
SteamUI, add a preload, reintroduce the exploratory FFmpeg adapter, or advance
to Runtime 4/Proton until the native SteamUI load boundary is crossed.
