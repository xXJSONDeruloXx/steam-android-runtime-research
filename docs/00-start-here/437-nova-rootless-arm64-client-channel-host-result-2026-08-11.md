# Nova rootless ARM64 client-channel host result — 2026-08-11

Status: host-only package investigation complete; no Android device run.

## Finding

The missing-module failure is tied to the current client build/channel
selection, not to a missing package entry that can be corrected by renaming a
library. The public-beta manifest currently resolves to build `1786141909`;
the stable ARM64 manifest resolves to build `1785799196`, the exact build used
by the successful SteamClientTermux SteamUI sessions.

Both ARM64-native package archives use the same intended Unix layout:

```text
steamrtarm64/steam
steamrtarm64/steamui.so
steamrtarm64/vgui2_s.so
steamrtarm64/steamwebhelper
```

Neither package contains `bin/vgui2_s.dll`. The current public-beta replay
requests that absent path after the updater window closes; the older stable
client's sibling logs proceed through GPU topology and SteamUI/webhelper
startup without that fatal request. This is evidence for testing the stable
client pairing, not permission to create a guessed `.so`-to-`.dll` alias.

## Verified manifests and payloads

The two Valve manifests were fetched from the official CDN and kept in host
temporary storage only:

| Channel | Manifest | Version | Manifest SHA-256 |
|---|---|---:|---|
| stable | `steam_client_linuxarm64` | `1785799196` | `a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91` |
| public beta | `steam_client_steamdeck_publicbeta_linuxarm64` | `1786141909` | `b81089d01988870f565fbc9f35b8de89b7f3658c4c5555bbe850ff742e3aef6f` |

The resolved ARM64-native VZ package metadata is:

```text
stable:
  bins_linuxarm64_linuxarm64.zip.vz.11771d05f91515ca5337eeb9baf835098df71d3a_60815678
  size=60815678
  sha2vz=38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148
  decoded_zip_size=337453898

public beta:
  bins_linuxarm64_linuxarm64.zip.vz.653c73a35bf37bc029dd9293ee0ad6b001ce94d1_60933249
  size=60933249
  sha2vz=cd206158065a03de4acfea77f7b30ec722f1d634cd15c1b468f1a724abf5618b
  decoded_zip_size=337965458
```

The VZ integrity hashes matched the manifest. Decoding used the format's
7-byte header and 10-byte footer and verified the embedded ZIP and entry
listing. The stable and public-beta archives each contain 55 entries and a
native `steamrtarm64/vgui2_s.so`; neither contains a `bin/` directory or a
`vgui2_s.dll` member.

The public-beta package's extracted native files differ from the R16 seed as
expected after the update. The R16 post-update failure used the public-beta
build and requested:

```text
Fatal Error: Could not load module 'bin/vgui2_s.dll'
```

The SteamClientTermux checkout was inspected at `8d14c10195b34fe2714ba59df1680df27a852532`.
Its successful logs identify ARM64 Steam build `1785799196` and use the
client-root working directory plus the conventional `.steam` links, but the
host package comparison shows that the stable/public-beta channel choice is
the only remaining upstream build variable that can be tested without an
artifact alias or SteamUI patch.

## Decision

Predeclare R17 with the R16 profile, client-root CWD, APK, Holo closure,
resolver, X11 endpoint, and app-UID supervisor unchanged. In the copied
client input, remove only `package/beta`, which selects Valve's stable
`steam_client_linuxarm64` manifest. Do not change the rootless supervisor or
create any `vgui2_s.dll` path.

R17 may advance to a SteamUI/X11 observation if the stable build crosses the
module handoff. It must remain a separate result from Runtime 4, Proton,
login, game, WSI, Gamescope, and AHardwareBuffer work.
