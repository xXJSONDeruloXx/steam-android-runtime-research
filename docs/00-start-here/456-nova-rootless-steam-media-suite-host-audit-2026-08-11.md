# Nova rootless Steam matched media-suite host audit — 2026-08-11

Status: host-only audit complete after R23; no Android device run.

## Minimum matched family

The completed Valve ARM64 bootstrap contains a self-consistent media family in
`steamrtarm64/`. The raw R22/R23 seed contains `libvideo.so` but none of these
seven provider files:

| File | Size | SHA-256 |
|---|---:|---|
| `libavcodec.so.62` | 2,781,800 | `f47a44246510d6aea528959046ab81496b610fd63d5c67abfc5da1e5ac1c17db` |
| `libavfilter.so.11` | 162,952 | `459d3433f802ad071c3ef8229bb1f19dbf7700d31a5c5f805fa02996758609e7` |
| `libavformat.so.62` | 1,024,816 | `c0383fdc0ee6ba7dc9d479d8fd8dd26f4ab38350d19f6555fbbc799f718cc025` |
| `libavutil.so.60` | 887,984 | `606c4eb6c7ca987f5b71a4cd0a60d5eeefb11fe97fd60c69c4dfca8afca42f9a` |
| `libswresample.so.6` | 88,464 | `d6cc3c9cc68bde026869491967784dd2dc89bfb328b6dd27ec016e53b8149bb3` |
| `libswscale.so.9` | 514,616 | `ef6354a7bad5aea551ee7ee6876e1ae195b00fb853ce6a070f3527c23bc6291a` |
| `libvpx.so.6` | 2,112,096 | `0e02a468d8647d6ede477cee83d8d9840590d6024def250dc63c4350f8017d37` |

`libvideo.so` declares these direct FFmpeg dependencies:

```text
libavcodec.so.62
libavformat.so.62
libswresample.so.6
libavutil.so.60
libswscale.so.9
libavfilter.so.11
RUNPATH $ORIGIN
```

The matched Valve `libavcodec.so.62` additionally declares
`libvpx.so.6`; its own `RUNPATH` is `$ORIGIN`. The seven-file set is therefore
the smallest client-directory family that prevents the loader from mixing
Valve `libvideo.so` with Holo's FFmpeg providers. The raw seed's `libaom.so.3`
and `libdav1d.so.6` are retained as unchanged inputs but are not newly staged
by this audit because they are not new direct dependencies of the matched
set.

## R23 explanation

R23 staged only the Valve `libavutil.so.60`. That correctly satisfied
`libvideo.so`'s tracked allocator symbols, but the loader then selected Holo's
`/usr/lib/libavcodec.so.62`, which requests:

```text
av_amf_to_av_format@LIBAVUTIL_60
```

The pinned Holo FFmpeg package defines that symbol in its own
`libavutil.so.60` (package SHA-256
`d0198cf82adcc29aa60263fd9dc0d048f4675d30725f5713a6faeefbc92cc411`), while
the matched Valve provider defines Steam's tracked allocator symbols instead.
R23 therefore proved that the single-file provider is an intentionally useful
diagnostic, but not a valid mixed closure.

## Provenance and scope

The files above are from the ignored completed Valve bootstrap at:

```text
android/nova-lab/build/steam-bootstrap/home/.local/share/Steam/steamrtarm64/
```

Its installed manifest records public-beta ARM64 client build `1785979614`.
The raw R23 stable client used build `1785799196`, but its `libvideo.so` has
the exact same SHA-256 as the completed bootstrap. This makes the seven-file
set a valid ABI experiment, not yet a final version-pinning decision. If the
family crosses SteamUI, acquire or generate the exact stable-build completion
before productizing the files.

The rootless Holo closure, supervisor, SteamUI, and existing exploratory
`libffmpeg-avutil-compat.so` remain unchanged. No Bionic library, preload
adapter, `.so`/`.dll` alias, authentication state, or device data is part of
this audit.

## Decision

Predeclare R24 with only these seven verified Valve files staged beside the raw
client's `libvideo.so`. Keep `-noverifyfiles`, the stable/no-link profile,
Termux:X11, resolver, and cleanup contract unchanged. The acceptance target is
crossing the SteamUI load boundary; any later failure is a separate result.
