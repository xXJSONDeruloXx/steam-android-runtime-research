# Nova rootless R23 — matched Valve `libavutil.so.60` result — 2026-08-11

Run ID: `nova-rootless-r23-matched-libavutil-steamui-20260811T120951Z`;
sub-run: `R23-rootless-supervisor-matched-libavutil`.

Status: complete; the single matched Valve provider crossed the R22
`libvideo.so` symbol failure, then exposed the next mixed-FFmpeg ABI boundary.

## Result

R23 kept the R22 profile and staged exactly one additional regular file beside
the raw stable ARM64 client:

```text
/opt/nova-steam/steamrtarm64/libavutil.so.60
sha256=606c4eb6c7ca987f5b71a4cd0a60d5eeefb11fe97fd60c69c4dfca8afca42f9a
size=887984
```

The paired raw-seed `libvideo.so` remained unchanged:

```text
sha256=e62d1affedcd0c5f26caf496c7c191a62bdf3556bd759fe28862840bfa13b375
```

The declared command reached and passed the R22 failure:

```text
Verification skipped
Verification complete
```

SteamUI then failed at the next dependency:

```text
dlmopen /opt/nova-steam/steamrtarm64/steamui.so failed:
/usr/lib/libavcodec.so.62: undefined symbol: av_amf_to_av_format,
version LIBAVUTIL_60
dlmopen steamui.so failed: /usr/lib/libavcodec.so.62: undefined symbol:
av_amf_to_av_format, version LIBAVUTIL_60
Failed to load steamui.so - dlerror(): (null)
Fatal error: Failed to load steamui.so
```

This proves the client-side `libavutil.so.60` was selected for
`libvideo.so`; the new failure comes from leaving Holo's `libavcodec.so.62`
and the rest of Holo FFmpeg in place. Holo's `libavutil.so.60` exports
`av_amf_to_av_format` but not Steam's tracked allocator symbols, while the
Valve `libavutil.so.60` exports the tracked allocator symbols but is not the
provider expected by Holo's `libavcodec.so.62`. A single-file substitution is
therefore not a stable closure.

No `steamwebhelper` process or SteamUI frame appeared. The screenshot showed
the Nova launcher surface, not SteamUI.

## Provisioning and evidence

The app-owned R23 run passed the rootfs and 161-package closure gates. The
first closure attempt was correctly rejected only because the temporary input
directory was read-only; after making that exact input directory app-owned,
the unchanged closure passed. No source script, Holo package, or supervisor
was changed.

```text
rootfs archive sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
closure packages=161
preflight free_kib=81191804
DISPLAY=127.0.0.1:77
Termux:X11=127.0.0.1:6077, pid=4917
package/beta=absent
```

Fresh host artifacts pulled before teardown:

```text
/tmp/nova-r23-steam-noverifyfiles-command.log
  size=3772
  sha256=fca4d19ea152e8844aae012a2590b07ed9fade245c1098fe1744a1efebe4337d
/tmp/nova-r23-bootstrap_log.txt
  size=683
  sha256=f4fc0b0c4c81116bbac9f3e8a4d72447ff010885fc997fae819d2c208d847a3a
/tmp/nova-r23-updateui_child.txt
  size=552
  sha256=356e116b0725ad14bbeb2249089633aa8a94e758ce161a2698420b7bbe0b5667
/tmp/nova-r23-matched-libavutil-failure.png
  PNG 1280x960, size=102456
  sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
/tmp/nova-r23-supervisor-preflight.log
  size=779
  sha256=1fc763ea312400693a48285c99b5e4df90a1f1c4b6c9c8465be4ee0c5df204df
```

## Cleanup and rollback

The exact scopes were removed:

```text
/data/local/tmp/nova-rootless-r23-matched-libavutil-steamui-20260811T120951Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r23/
/data/data/com.termux/files/home/.nova-rootless/
```

Post-cleanup verification reported:

```text
remote_r23=absent
app_r23=absent
termux_rootless=absent
port_6077=absent
matching exact Steam/SteamUI/webhelper/PRoot/termux-x11/Xwayland processes=none
rollback_rootfs=present
rollback_active=present
free_kib=86108192
```

No Steam authentication secret was read, copied, or exported.

## Decision and next step

Retain the matched Valve `libavutil.so.60` finding, but do not ship it alone.
The next host audit must enumerate the complete Valve ARM64 media closure
from the completed bootstrap—at least `libavcodec.so.62`, `libavformat.so.62`,
`libswresample.so.6`, `libswscale.so.9`, `libavfilter.so.11`, and their
`libvpx.so.6` dependency—and compare it with the raw seed and Holo closure.
Then predeclare a fresh run that stages the smallest complete matched family
beside `libvideo.so`. Do not add a preload adapter, patch SteamUI, or test
another launch flag until that family is understood.
