# Nova rootless R20 — client-root Steam entry-point result — 2026-08-11

Run ID: `nova-rootless-r20-client-root-entry-steam-lifecycle-20260811T113042Z`;
sub-run: `R20-rootless-supervisor-steam-client-root-entry`.

Status: complete; the audited client-root entry point is absent from the
fresh stable seed, so PRoot stopped at `exec` before the updater or Steam ran.

## Result

R20 kept the R19 stable/no-link rootless profile and changed only the native
command from the seed entry point to the entry point used by the audited
SteamClientTermux launcher:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steam'
```

The fresh stable seed does not contain `/opt/nova-steam/steam`. PRoot exited
immediately with:

```text
/bin/sh: line 1: /opt/nova-steam/steam: No such file or directory
```

No updater, native Steam process, `steamwebhelper`, SteamUI log, or visible
Steam frame was produced. The host input confirms the same shape before
device staging:

```text
/tmp/nova-r10-input-final.LnvYB3/steam-client/steam             absent
/tmp/nova-r10-input-final.LnvYB3/steam-client/steamrtarm64/steam present
steamrtarm32 -> steamrtarm64
```

This is a seed-layout boundary, not evidence against the client-root launch
contract after an update. R19 reached the updater using
`steamrtarm64/steam`; R20 never reached that updater because the audited
client-root path is created only after the seed has been bootstrapped or is
provided by a separate launcher layout.

## Provisioning and controlled profile

The first R20 extraction invocation accidentally omitted the bundled
app-private `bsdtar` bootstrap and toybox `tar` rejected Holo symlink/systemd
entries. The exact R20 scope was corrected by restoring the same bootstrap
fixture used by R19; the second extraction and closure run passed. This did
not change the client command or any runtime variable.

The accepted run had:

- stable ARM64 client with `package/beta` absent;
- Holo rootfs archive SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`;
- PRoot SHA-256
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`;
- PRoot loader SHA-256
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`;
- rootfs extraction pass and 161-package Holo/UI-audio closure pass;
- fresh Termux:X11 at `127.0.0.1:6077`, guest display `:77`;
- only `$HOME/.steam/steam -> /opt/nova-steam`;
- no extra launch flags, Runtime 4, Proton, route/audio helper, SteamUI
  patch, DLL alias, Gamescope, AHardwareBuffer, game, or authentication
  variable;
- supervisor preflight pass with `80226880 KiB` free.

The APK was `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
`5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08e257a682`.

Host-side evidence:

```text
/tmp/nova-r20-supervisor-preflight.log
size=767
sha256=6de8cc9a0cee4e3ff5fc9501b99393fa4c048e79c87eea7ef0834ea5c2d5f910

/tmp/nova-r20-steam-client-root-entry-command.log
size=879
sha256=37d410560513537020a15075281f83e8479ee2c7374146d40b5158c95aed78c5

/tmp/nova-r20-steam-client-root-entry-failure.png
PNG 1280x960
sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
```

The screenshot is the Nova launcher surface and is a negative display
artifact, not SteamUI readiness evidence.

## Cleanup and rollback

The exact R20 scopes were removed:

```text
/data/local/tmp/nova-rootless-r20-client-root-entry-steam-lifecycle-20260811T113042Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r20/
/data/data/com.termux/files/home/.nova-rootless/
```

The exact Termux:X11 PID `21650` was terminated after `am force-stop` left it
alive. Post-cleanup verification reported:

```text
Steam/SteamUI/webhelper/PRoot/termux-x11/Xwayland processes=none
127.0.0.1:6077 listener=absent
remote_r20=absent
app_r20=absent
termux_rootless=absent
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs=present
/data/local/tmp/nova-active-runtime=present
```

No Steam authentication secret was read, copied, exported, or backed up.

## Decision and next step

Do not add the top-level link silently to the baseline. R20 establishes that
the sibling's `$client/steam` command cannot be tested against the raw stable
seed without an explicit layout preparation step. The next fresh experiment
may predeclare exactly one such layout change:

```text
/opt/nova-steam/steam -> /opt/nova-steam/steamrtarm64/steam
```

It should then run `/opt/nova-steam/steam` without sibling flags and observe
whether the updater handoff differs from R19. Keep all launch flags, Runtime
4, Proton, route/audio helpers, Gamescope/AHardwareBuffer, and game launch
deferred until a fresh `steamwebhelper`/SteamUI frame exists.
