# Nova rootless Steam SDL3 provider host audit — 2026-08-11

This is a host-only follow-up to the R24 result in [doc
458](458-nova-rootless-r24-matched-media-suite-result-2026-08-11.md). It does
not change the device, the rooted rollback runtime, or any repository launch
script.

## Question

R24 staged the complete seven-file Valve FFmpeg family and reached SteamUI's
dynamic loader, but `steamui.so` stopped on:

```text
undefined symbol: SDL_TryLockJoysticks, version SDL3_0.0.0
```

The question is whether this is another mixed provider boundary with a
narrow, provenance-backed client-side fix, or whether more SteamUI patching is
required.

## Provider comparison

The raw stable ARM64 client used by R24 has no `libSDL3.so*` in
`steamrtarm64/`. R24 therefore resolved `steamui.so`'s `NEEDED libSDL3.so.0`
from the Holo closure's `/usr/lib/libSDL3.so.0`.

| Provider | Source | Size | SHA-256 | Build identity |
|---|---|---:|---|---|
| Valve | `android/nova-lab/build/steam-bootstrap/home/.local/share/Steam/steamrtarm64/libSDL3.so.0` | 3,291,064 | `b0edc01af34ad08c496928c647edc20a3f2f3bdb22f4a460a902759d0183ef52` | BuildID `770307233f40ce08305b01190036c3c12e668551` |
| Holo | `sdl3-3.2.26-1-aarch64.pkg.tar.zst`, extracted `usr/lib/libSDL3.so.0.2.26` | 2,861,576 | `86cbccde8ffafaf24e1f2509ecc49193940153bc0450f6ab3dcb50c7eecfb7d2` | BuildID `7fd7fe39fbae25b86cb1b234a08d3586e1656052` |

The Holo package itself is pinned by the existing manifest entry:

```text
package=sdl3-3.2.26-1-aarch64.pkg.tar.zst
package_sha256=575ba9be1c53fb7551fe559bd259323d1b3cc27f2ed231114a4fa66e1ed10ad4
```

The Valve file comes from the completed ARM64 Steam bootstrap used for the
R22–R24 host audits. Its associated `steamui.so` and `libvideo.so` are byte
identical to the raw stable R24 inputs:

```text
steamui.so size=38532968 sha256=972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0
libvideo.so size=9698888 sha256=e62d1affedcd0c5f26caf496c7c191a62bdf3556bd759fe28862840bfa13b375
```

## ABI evidence

R24's `steamui.so` has these SDL3 references:

```text
SDL_TryLockJoysticks@@SDL3_0.0.0  UND
SDL_UnlockJoysticks@@SDL3_0.0.0   UND
```

The Holo provider exports `SDL_LockJoysticks` and
`SDL_UnlockJoysticks`, but not `SDL_TryLockJoysticks`. The Valve provider
exports all three:

```text
Valve: SDL_LockJoysticks       SDL3_0.0.0
Valve: SDL_TryLockJoysticks    SDL3_0.0.0
Valve: SDL_UnlockJoysticks     SDL3_0.0.0
Holo:  SDL_LockJoysticks       SDL3_0.0.0
Holo:  SDL_UnlockJoysticks     SDL3_0.0.0
```

The Valve provider has this dynamic dependency set:

```text
NEEDED libdl.so.2
NEEDED ld-linux-aarch64.so.1
NEEDED libEGL.so.1
NEEDED libm.so.6
NEEDED libpthread.so.0
NEEDED libc.so.6
SONAME libSDL3.so.0
RUNPATH $ORIGIN
```

The existing Holo/UI-audio closure already includes `libglvnd-1.7.0-3`, whose
`libEGL.so.1` is present as the normal `libEGL.so -> libEGL.so.1 ->
libEGL.so.1.1.0` chain. No second provider is justified by this dependency
inspection. The Valve SDL3 file's `$ORIGIN` runpath also keeps its own lookup
scope beside the client libraries rather than requiring a global preload.

## Decision

The failure is a real provider mismatch, not an SDL3 source/API absence in
SteamUI and not a controller transport result. A single exact Valve
`libSDL3.so.0` staged beside the existing raw `steamui.so`, `libvideo.so`, and
seven-file FFmpeg family is the smallest justified next device experiment.

Do not stage `libsdl3-compat.so`, use `LD_PRELOAD`, replace Holo's SDL3
package, copy the entire completed bootstrap, or patch `steamui.so`. Keep the
Holo `libEGL`/Mesa closure, direct Termux:X11 profile, `-noverifyfiles` flag,
and all R24 setup and cleanup scopes unchanged. The next run must record
whether this one-file provider crosses SteamUI and, if it does, the next first
loader or lifecycle boundary.
