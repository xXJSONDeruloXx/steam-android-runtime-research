# Nova rootless R22 — `-noverifyfiles` launch-flag result — 2026-08-11

Run ID: `nova-rootless-r22-noverifyfiles-steam-lifecycle-20260811T115353Z`;
sub-run: `R22-rootless-supervisor-steam-noverifyfiles`.

Status: complete; `-noverifyfiles` bypassed the updater and exposed a fresh
SteamUI media-library ABI failure.

## Result

R22 launched the actual ARM64 client with only:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam -noverifyfiles'
```

The fresh updater log proves that verification was skipped:

```text
Verification skipped
Verification complete
```

Steam then reached its X11 update UI and tried to load `steamui.so`, but the
media dependency failed:

```text
dlmopen /opt/nova-steam/steamrtarm64/steamui.so failed:
/opt/nova-steam/steamrtarm64/libvideo.so: undefined symbol:
av_malloc_tracked, version LIBAVUTIL_60
dlmopen steamui.so failed:
/opt/nova-steam/steamrtarm64/libvideo.so: undefined symbol:
av_malloc_tracked, version LIBAVUTIL_60
Failed to load steamui.so - dlerror(): (null)
Fatal error: Failed to load steamui.so
```

No `steamwebhelper` process or SteamUI frame appeared. This is a precise
guest-library ABI boundary before webhelper, not a Vulkan/WSI or compositor
failure.

## ELF evidence

Fresh device artifacts were captured before teardown:

```text
libvideo.so
size=9698888
sha256=e62d1affedcd0c5f26caf496c7c191a62bdf3556bd759fe28862840bfa13b375
undefined symbols:
  av_malloc_tracked@LIBAVUTIL_60
  av_mallocz_tracked@LIBAVUTIL_60

guest-rootfs-closure/usr/lib/libavutil.so.60
size=1181744
sha256=d0198cf82adcc29aa60263fd9dc0d048f4675d30725f5713a6faeefbc92cc411
defined symbols observed:
  av_malloc@@LIBAVUTIL_60
  av_mallocz@@LIBAVUTIL_60
  av_malloc_array@@LIBAVUTIL_60
  av_malloc_tracked: absent
  av_mallocz_tracked: absent

steamui.so
size=38532968
sha256=972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0
```

The missing symbols are not a display-surface error and should not be
addressed with a SteamUI view patch or a guessed symbol shim. The next task
is to identify the intended `libavutil` provider/version and provenance from
the Steam client, Holo package closure, and SteamClientTermux prior art.

## Controlled profile and setup evidence

The run kept the R19/R21 stable/no-link profile: Holo ARM64 rootfs, 161-package
closure, app-UID PRoot, resolver, `/dev` and `/proc` binds, fresh Termux:X11
at `127.0.0.1:6077`, guest display `:77`, no top-level client symlink, no
other sibling flags, no Runtime 4, Proton, route/audio helper, SteamUI patch,
DLL alias, Gamescope, AHardwareBuffer, game, or authentication variable.

Provisioning passed with the app-private `bsdtar` bootstrap:

```text
rootfs archive sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
proot sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
loader sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
rootfs extraction=pass
guest closure=pass
preflight=pass free_kib=80203720
package/beta=absent
```

The APK was `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
`5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08e257a682`.

Host-side evidence:

```text
/tmp/nova-r22-supervisor-preflight.log
size=767
sha256=22c59e38b4e1342b4d47260b77d7ae8bbd9bbde57057d86a4ad0f37cd8d1a907

/tmp/nova-r22-steam-noverifyfiles-command.log
size=3592
sha256=ec6d3286de3424be19a7a74a6a22edc37e471c005ba3a1cf2242daaf8f951ccf

/tmp/nova-r22-noverifyfiles-failure.png
PNG 1280x960
sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818

/tmp/nova-r22-libvideo.so
size=9698888
sha256=e62d1affedcd0c5f26caf496c7c191a62bdf3556bd759fe28862840bfa13b375

/tmp/nova-r22-libavutil.so.60
size=1181744
sha256=d0198cf82adcc29aa60263fd9dc0d048f4675d30725f5713a6faeefbc92cc411
```

The screenshot showed the Nova launcher surface and is not SteamUI evidence.

## Cleanup and rollback

The exact R22 scopes were removed:

```text
/data/local/tmp/nova-rootless-r22-noverifyfiles-steam-lifecycle-20260811T115353Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r22/
/data/data/com.termux/files/home/.nova-rootless/
```

The exact Termux:X11 PID `29424` was terminated after `am force-stop` left it
alive. Post-cleanup verification reported:

```text
Steam/SteamUI/webhelper/PRoot/termux-x11/Xwayland processes=none
127.0.0.1:6077 listener=absent
remote_r22=absent
app_r22=absent
termux_rootless=absent
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs=present
/data/local/tmp/nova-active-runtime=present
```

No Steam authentication secret was read, copied, exported, or backed up.

## Decision and next step

Retain `-noverifyfiles` as a useful diagnostic entry point, not as a success
flag. Do not add the remaining launch flags, patch SteamUI, or synthesize the
missing symbols yet. First perform a host/source provenance audit of
`libvideo.so` and the `libavutil.so.60` provider, compare the sibling's
successful runtime closure, and predeclare the smallest closure correction.
After the ABI boundary is understood, rerun the same noverify profile before
testing the remaining sibling flags.
