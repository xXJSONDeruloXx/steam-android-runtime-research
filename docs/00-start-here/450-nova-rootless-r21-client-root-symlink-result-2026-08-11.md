# Nova rootless R21 — client-root seed symlink result — 2026-08-11

Run ID: `nova-rootless-r21-client-root-symlink-20260811T114233Z`; sub-run:
`R21-rootless-supervisor-steam-client-root-symlink`.

Status: complete; the explicit top-level seed symlink allowed the client to
start, but it did not change the updater-to-client handoff.

## Result

R21 added exactly one layout entry to the fresh stable seed:

```text
/opt/nova-steam/steam -> steamrtarm64/steam
```

It then launched without flags:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steam'
```

The symlink allowed the native `steam` process and its child updater to run.
The stable client downloaded all `664432 KB`, extracted and installed the
update, and logged:

```text
Update complete, launching...
Shutdown
ProcessNextMessage: socket disconnected
No more messages are expected - exiting
```

After the update, the top-level `steam` symlink had been replaced by a
directory containing `cached/` and `games/`; it was not a runnable top-level
client entry. No subsequent native Steam process, `steamwebhelper`, SteamUI
log, or visible Steam frame appeared. R21 therefore reproduces R19's
post-update boundary and does not fix it.

## Prior-art path correction

The sibling source uses:

```text
client_root=$base/client
client=$client_root/steamrtarm64
exec "$client/steam" ...
```

Therefore the successful sibling executable is
`<client_root>/steamrtarm64/steam`, which R19 already invoked as
`/opt/nova-steam/steamrtarm64/steam`. R20's top-level `/opt/nova-steam/steam`
test and R21's symlink are seed-layout probes, not evidence that Nova was
using the wrong native ARM64 executable path. The remaining unexplained
variable is the target launch-flag contract and/or the updater's relaunch
behavior after installation.

## Controlled profile and evidence

The run kept the R19 stable/no-link profile, including the Holo rootfs, the
161-package closure, app-UID PRoot, resolver, `/dev` and `/proc` binds, fresh
Termux:X11 at `127.0.0.1:6077`, guest display `:77`, no beta selector, no
Runtime 4, Proton, route/audio helper, SteamUI patch, DLL alias, Gamescope,
AHardwareBuffer, game, or authentication variable. The sole intended change
was the top-level client symlink.

Provisioning passed with the app-private `bsdtar` bootstrap:

```text
rootfs archive sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
proot sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
loader sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
rootfs extraction=pass
guest closure=pass
preflight=pass free_kib=80221384
package/beta=absent
```

The APK was `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
`5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08e257a682`.

Host-side evidence:

```text
/tmp/nova-r21-supervisor-preflight.log
size=767
sha256=5b9f4b75a6b74f081a7fecc9d231287e2c08b89709f95a3155774a55b2dafe0c

/tmp/nova-r21-steam-client-root-symlink-command.log
size=79593
sha256=745d5673f5173067dbccfc0de4754cad88ede1cf891846070a3ad76f7085e7be

/tmp/nova-r21-postupdate.png
PNG 1280x960
sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
```

The post-update installed manifest was 1,549,381 bytes with SHA-256
`ed6fc7a4d5817febe80dff6ef14014d97f47e9b03cde89a36fe1a90407ca0fe0`.
The screenshot showed the Nova launcher surface and is not SteamUI evidence.

## Cleanup and rollback

The exact R21 scopes were removed:

```text
/data/local/tmp/nova-rootless-r21-client-root-symlink-20260811T114233Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r21/
/data/data/com.termux/files/home/.nova-rootless/
```

The exact Termux:X11 PID `25692` was terminated after `am force-stop` left it
alive. Post-cleanup verification reported:

```text
Steam/SteamUI/webhelper/PRoot/termux-x11/Xwayland processes=none
127.0.0.1:6077 listener=absent
remote_r21=absent
app_r21=absent
termux_rootless=absent
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs=present
/data/local/tmp/nova-active-runtime=present
```

No Steam authentication secret was read, copied, exported, or backed up.

## Decision and next step

Do not retain the top-level `steam` symlink in the baseline. R19 and R21 now
agree on the actual ARM64 executable and the same updater handoff boundary;
R20/R21 also close the raw-seed top-level path as an explanation. The next
fresh experiment should add only one target-derived launch flag, beginning
with `-noverifyfiles`, then capture whether the post-update client or
`steamwebhelper` appears. Keep the other flags, Runtime 4, Proton, service
helpers, Gamescope/AHardwareBuffer, and game launch deferred until that result
is documented.
