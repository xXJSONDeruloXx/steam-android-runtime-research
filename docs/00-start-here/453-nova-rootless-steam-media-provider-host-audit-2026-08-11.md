# Nova rootless Steam media-provider host audit — 2026-08-11

Status: host-only audit complete; no Android device run or Steam-auth state was
read.

## Finding

R22 did not reveal an arbitrary Holo FFmpeg defect. The raw ARM64 seed bound at
`/opt/nova-steam` contains Steam's `libvideo.so`, but its
`steamrtarm64` directory contains no `libavutil.so*`. The Holo closure then
became the first provider of `libavutil.so.60`, and that provider does not
implement the ABI requested by the client media library.

The complete Valve ARM64 Steam bootstrap already staged in the ignored host
build tree contains the intended client-side provider in the same directory:

```text
steamrtarm64/libvideo.so
  NEEDED  libavutil.so.60
  RUNPATH $ORIGIN
  sha256=e62d1affedcd0c5f26caf496c7c191a62bdf3556bd759fe28862840bfa13b375

steamrtarm64/libavutil.so.60
  SONAME libavutil.so.60
  sha256=606c4eb6c7ca987f5b71a4cd0a60d5eeefb11fe97fd60c69c4dfca8afca42f9a
  size=887984
  BuildID=73e4b5aaa939aa29f04df2a9863e3e3db143add5
```

`nm -D` shows the matched Valve provider exports all three requested symbols
with the requested version:

```text
av_malloc_tracked@@LIBAVUTIL_60
av_mallocz_tracked@@LIBAVUTIL_60
av_register_malloc@@LIBAVUTIL_60
```

The R22 Holo provider was different:

```text
guest-rootfs-closure/usr/lib/libavutil.so.60
  sha256=d0198cf82adcc29aa60263fd9dc0d048f4675d30725f5713a6faeefbc92cc411
  size=1181744
  exports av_malloc@@LIBAVUTIL_60 and av_mallocz@@LIBAVUTIL_60
  does not export av_malloc_tracked, av_mallocz_tracked, or av_register_malloc
```

The client-side provider is therefore selected by the existing `$ORIGIN`
loader contract when it is present beside `libvideo.so`; it does not require a
SteamUI patch, a guessed `.so`/`.dll` alias, or `LD_PRELOAD`.

## Provenance

The matched provider is from the ignored, host-generated completed Steam
bootstrap at:

```text
android/nova-lab/build/steam-bootstrap/home/.local/share/Steam/steamrtarm64/libavutil.so.60
```

Its installed manifest records the Valve ARM64 public-beta client build
`1785979614`. The paired `libvideo.so` has the exact R22 hash above. The
bootstrap tree is derived from Valve's `steamdeck_publicbeta` ARM64 client
channel; it is not checked into this evidence repository and contains no
Steam authentication data.

The current research checkout is at `4a17a3b`; the inspected
SteamClientTermux checkout is at `8d14c10195b34fe2714ba59df1680df27a852532`.
SteamClientTermux's launcher places the client `steamrtarm64` directory first
in `LD_LIBRARY_PATH`, while its checked-in source does not provide a separate
media-library replacement. The Nova rooted launcher has the same client-first
ordering. The rootless supervisor currently passes no guest library ordering,
so R22 fell through to Holo `/usr/lib` when the client directory lacked the
provider.

The repository also contains an older exploratory
`libffmpeg-avutil-compat.so` adapter. Its ARM64 build exports the three names,
but it forwards the tracked allocators to Holo and intentionally discards the
registration callbacks. That is a compatibility workaround, not the matched
Valve closure, and remains out of the next test because the client provider is
available and the profile policy is to avoid patching this boundary first.

## Decision

The smallest next device experiment is a fresh R23 copy of the R22 profile
with exactly one staged client artifact: the verified Valve
`steamrtarm64/libavutil.so.60` above. Keep `-noverifyfiles` as the diagnostic
entry point, leave the Holo package closure and rootless supervisor unchanged,
do not preload the exploratory adapter, and require the same fresh
SteamUI/webhelper/X11 evidence and exact cleanup. If the matched provider
crosses the `steamui.so` load boundary, the next result can address the next
real lifecycle failure rather than another ABI guess.
