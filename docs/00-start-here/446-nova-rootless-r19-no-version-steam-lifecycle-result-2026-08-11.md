# Nova rootless R19 — no-version native Steam lifecycle result — 2026-08-11

Run ID: `nova-rootless-r19-no-version-steam-lifecycle-20260811T111816Z`;
sub-run: `R19-rootless-supervisor-steam-stable-no-version`.

Status: complete; the no-version command passed rootfs, package, network, and
stable-client update work, but the updater exited at its post-update launch
boundary before starting SteamUI.

## Result

R19 removed only the diagnostic `--version` argument from the R17 stable/no-link
profile. The fresh app-UID run extracted the Holo rootfs, installed the full
161-package Holo/UI-audio closure, passed supervisor preflight, downloaded the
stable ARM64 client manifest, and installed the 664,432 KiB update. The updater
then logged:

```text
Update complete, launching...
Shutdown
ProcessNextMessage: socket disconnected
No more messages are expected - exiting
```

The same invocation did not produce a subsequent native Steam process,
`steamwebhelper`, SteamUI log, or visible Steam frame. It also did not emit
the R18b `bin/vgui2_s.dll` fatal. This makes the observed boundary updater to
post-update client relaunch, before SteamUI and before Vulkan/WSI or game
startup. It is not a SteamUI or compositor result.

Removing `--version` therefore avoided the previously observed module-fatal
path in this run, but did not prove that the ordinary native client lifecycle
works. Because the post-update process never appeared, R19 cannot distinguish
an executable-path/relaunch-contract issue from a later client initialization
issue.

## Controlled profile and evidence

The run kept the following unchanged:

- Valve stable ARM64 client, version `1785799196`, with `package/beta` absent
  from both staged and app-owned trees;
- Holo ARM64 rootfs archive and the 161-package closure;
- app-UID PRoot, loader, resolver, `/dev` and `/proc` binds, and app-owned
  state;
- fresh Termux:X11 at `127.0.0.1:6077`, guest display `:77`;
- only the supervisor-created `$HOME/.steam/steam -> /opt/nova-steam` link;
- no SteamUI patch, DLL alias, Runtime 4, Proton, route shadow, PulseAudio
  change, Gamescope, AHardwareBuffer, game, or authentication variable.

The exact command was:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam'
```

The preflight and closure evidence was:

```text
nova_rootless_rootfs_archive=pass
nova_rootless_guest_rootfs=pass
nova_rootless_preflight=pass
nova_rootless_free_kib=80212608
steam_home_links=$HOME/.steam/steam -> /opt/nova-steam
package/beta=absent
```

The client updater reported the stable manifest at version `1785799196`,
downloaded all `664432 KB`, extracted and installed it, and wrote the updated
installation manifest:

```text
files/r19/steam-client/package/steam_client_linuxarm64.installed
size=1549381
sha256=ed6fc7a4d5817febe80dff6ef14014d97f47e9b03cde89a36fe1a90407ca0fe0
```

Host-side evidence retained for this result:

```text
/tmp/nova-r19-supervisor-preflight.log
size=767
sha256=d0bef3dc460941f38736bb37803f9a69e9ce8adb3ef6448bf0f3ba760f14d6b8

/tmp/nova-r19-steam-stable-no-version-command.log
size=1013
sha256=196f7121bc94f32a1cc79c04a1b359bfcd41c6f4f55f56143fae8a70c2b328c2

/tmp/nova-r19-steam-stable-no-version-postupdate.png
PNG 1280x960
sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
```

The screenshot showed the Nova launcher surface rather than Steam; it is a
negative display artifact, not a SteamUI readiness result. Fresh Steam logs
were inspected before teardown and ended at the updater shutdown boundary;
no authentication file was read or retained.

## Cleanup and rollback

The exact mutable scopes were removed:

```text
/data/local/tmp/nova-rootless-r19-no-version-steam-lifecycle-20260811T111816Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r19/
/data/data/com.termux/files/home/.nova-rootless/
```

The exact Termux:X11 PID `17352` was terminated after `am force-stop` left it
alive. Post-cleanup verification reported:

```text
Steam/SteamUI/webhelper/PRoot/termux-x11/Xwayland processes=none
127.0.0.1:6077 listener=absent
remote_r19=absent
app_r19=absent
termux_rootless=absent
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs=present
/data/local/tmp/nova-active-runtime=present
```

The rooted rollback runtime was not modified. No Steam authentication secret
was read, copied, exported, or backed up.

## Decision and next step

Do not promote R19 as a SteamUI pass and do not add any module alias or view
patch. The stable/no-link filesystem remains the clean baseline, while R19
shows that the native client update path itself is healthy and the next
failure is the post-update relaunch handoff.

After this result is committed and pushed, predeclare a fresh R20 that changes
only the native executable path to match the audited SteamClientTermux
contract (`/opt/nova-steam/steam`, still without extra flags). If that crosses
the updater boundary, test the sibling's four launch flags as a separately
declared profile. Keep the `.steam` link set, Runtime 4, Proton, route/audio
helpers, Gamescope/AHardwareBuffer, and game launch deferred until a fresh
`steamwebhelper`/SteamUI frame exists.
