# WinNative Bionic Steam prior art and source provenance audit — 2026-08-10

## Status and scope

This is a read-only source and packaged-asset audit. It records what the
public [WinNative repository](https://github.com/WinNative-Emu/WinNative)
appears to provide, which pieces have public source, and which pieces are
Valve or other prebuilt binaries. No Nova device run, runtime replacement, or
source integration was performed for this record.

The audit follows the earlier proposal to keep the working glibc Steam UI and
use a narrowly scoped Bionic helper or parallel launch mode; see
[`docs/40-productization/320-nova-glibc-ui-bionic-sidecar-future-research-2026-08-10.md`](320-nova-glibc-ui-bionic-sidecar-future-research-2026-08-10.md).

## Conclusion

WinNative is stronger prior art for the Bionic side of this project than a
generic Android wrapper. It contains source for an Android-native Steam
protocol/client layer, bootstrap and staging logic, a launcher, API bridges,
and the surrounding Winlator/Pluvia runtime pieces. It also demonstrates how
to stage the Android `libsteamclient.so` family alongside Wine's
`lsteamclient` boundary.

The missing source does not look like a hidden WinNative implementation of
the Steam client. The important absent pieces are predominantly Valve's
proprietary Steam binaries, plus prebuilt Proton/Wine artifacts whose public
upstream source exists but whose exact WinNative build and patch set are not
fully pinned. This distinction matters: WinNative's GPL-3 application license
does not make Valve's staged binaries redistributable or reproducible under
the same terms.

WinNative is therefore useful as architecture and lifecycle prior art, not as
a drop-in glibc UI dependency and not as proof that a complete Bionic Steam UI
can be rebuilt from the repository alone.

## What WinNative implements

The public source tree includes several relevant layers:

| Layer | Public evidence | Interpretation |
| --- | --- | --- |
| Android application and Winlator/Pluvia integration | [WinNative source tree](https://github.com/WinNative-Emu/WinNative) and [top-level native CMake](https://raw.githubusercontent.com/WinNative-Emu/WinNative/main/app/src/main/cpp/CMakeLists.txt) | WinNative-authored Android/runtime integration; the repository is GPL-3 at the top level, subject to file-specific and third-party terms. |
| Native Steam protocol/client layer | [`wn-steam-client`](https://github.com/WinNative-Emu/WinNative/tree/main/app/src/main/cpp/wn-steam-client), [Rust module list](https://raw.githubusercontent.com/WinNative-Emu/WinNative/main/app/src/main/cpp/wn-steam-client/rust/src/lib.rs), and [`WnSteamSession.kt`](https://raw.githubusercontent.com/WinNative-Emu/WinNative/main/app/src/main/feature/stores/steam/wnsteam/WnSteamSession.kt) | WinNative source for QR/credential and refresh-token login, CM lifecycle, depot/PICS, ownership/tickets, stats, cloud, and related Steam services. This is not the proprietary Steam UI. |
| Bootstrap and service boundary | [`wn-steam-bootstrap`](https://github.com/WinNative-Emu/WinNative/tree/main/app/src/main/cpp/wn-steam-bootstrap), [bootstrap implementation](https://raw.githubusercontent.com/WinNative-Emu/WinNative/main/app/src/main/cpp/wn-steam-bootstrap/src/steam_bootstrap.cpp), and [CMake notes](https://raw.githubusercontent.com/WinNative-Emu/WinNative/main/app/src/main/cpp/wn-steam-bootstrap/CMakeLists.txt) | Public JNI/bootstrap code loads a staged Valve `libsteamclient.so`, creates interfaces/users, pumps callbacks, and coordinates the Wine-side service boundary. The Steam logic itself is not reimplemented there. |
| Open-source `libsteamclient` work | [`wn-libsteamclient`](https://github.com/WinNative-Emu/WinNative/tree/main/app/src/main/cpp/wn-libsteamclient) and [its CMake description](https://raw.githubusercontent.com/WinNative-Emu/WinNative/main/app/src/main/cpp/wn-libsteamclient/CMakeLists.txt) | WinNative-authored from-scratch implementation backed by the open Rust client. The source explicitly describes an initial/stub and incremental scope; it is not a complete replacement for Valve's client. |
| Launcher | [`wn-steam-launcher`](https://github.com/WinNative-Emu/WinNative/tree/main/app/src/main/cpp/wn-steam-launcher) and [launcher source](https://raw.githubusercontent.com/WinNative-Emu/WinNative/main/app/src/main/cpp/wn-steam-launcher/src/main.cpp) | WinNative source for the staged `wnsteam/bionic/steam.exe` launcher and its environment/lifecycle handling. |
| Steam API bridge | [`wn-steamapi-bridge`](https://github.com/WinNative-Emu/WinNative/tree/main/app/src/main/cpp/wn-steamapi-bridge) | WinNative source/generators for the bridge DLLs. The separate `original_steam_api64.dll` asset should remain classified as an upstream Valve binary. |
| Asset staging | [`WnSteamAssetsInstaller.kt`](https://raw.githubusercontent.com/WinNative-Emu/WinNative/main/app/src/main/feature/stores/steam/wnsteam/WnSteamAssetsInstaller.kt) | Public code stages the Android Steam libraries, Wine-side `lsteamclient`, service files, and the Valve Windows client bundle into app-private storage. |

The README describes WinNative as a combination of Winlator Bionic and Pluvia
and gives the build/submodule requirements. Its current clone example still
mentions an older repository owner, so a reproducible follow-up should pin the
actual repository URL and commit rather than copying that command verbatim.

## Source-versus-binary classification

The following classification is based on the repository tree, the asset
installer, embedded strings, and the corresponding public upstream source.
The hashes below are GitHub blob SHA-1 values where noted, not package
SHA-256 values.

| WinNative item | Observed contents/evidence | Provenance decision |
| --- | --- | --- |
| `app/src/main/**`, `wn-steam-client`, `wn-steam-bootstrap`, `wn-steam-launcher`, and `wn-steamapi-bridge` | C/C++, Rust, Kotlin, and generators are present in the public repository. | WinNative-authored source is available. Check each file's license before reuse; do not assume every transitive dependency is GPL-3. |
| `app/src/main/assets/wnsteam/steam-androidarm64.tzst` | 12,805,003-byte archive; GitHub blob SHA `8244f1d95a73427778e468eb32e20e56e17c9dd7`. Extracted `usr/lib/libsteamclient.so`, `libsteamnetworkingsockets.so`, `libtier0_s.so`, `libvstdlib_s.so`, and `steamservice.so`; the ARM64 ELF contains Android linker/libandroid and Valve build markers. | Valve Android Steam component bundle, proprietary/prebuilt. It is the same broad component family as Valve's `bins_androidarm64_linuxarm64` depot, but the inspected WinNative archive is smaller/repacked and was not byte-identified as the current Valve depot. |
| `app/src/main/assets/wnsteam/bionic/valve-steam-x86_64.tzst` | 15,979,710-byte archive; GitHub blob SHA `2b8f10b71c67cb98402103cd72c08760da0dda63`. Contains `steamclient64.dll`, `steamclient.dll`, `Steam2.dll`, `Steam.dll`, and Valve `tier0`/`vstdlib` DLLs. | Valve Windows Steam client bundle staged by WinNative. Proprietary upstream artifact, not WinNative source. |
| `app/src/main/assets/wnsteam/bionic/steamservice.exe` and `steamservice.dll` | PE binaries with Valve buildworker paths, `Software\\Valve\\Steam`, `Steam3 Client Engine`, and `CServiceEngine` strings. | Valve proprietary service binaries. |
| `app/src/main/assets/wnsteam/bionic/steam.exe` | 1,064,448-byte binary with `[wn-launcher]`, `WN_STEAM_*`, and WinNative launcher markers. | WinNative launcher build; its implementation is present in `wn-steam-launcher`, unlike the Valve Steam binaries staged beside it. |
| `app/src/main/assets/wnsteam/bionic/wn-steam-helper.exe` | 176,128-byte PE32+ Wine builtin with `steam_helper/steam.c`, Proton/Wine build paths, and “Forwarded command to native steam” strings. | Prebuilt Proton/Wine `steam_helper`-style component. The matching [Proton 11 source](https://raw.githubusercontent.com/ValveSoftware/Proton/proton_11.0/steam_helper/steam.c) is public; the exact WinNative build and patch set are not pinned. |
| `app/src/main/assets/wnsteam/lsteamclient-arm64ec.tzst` and `lsteamclient-x86_64.tzst` | Archives contain Unix and Windows `lsteamclient` libraries. Strings reference Wine/Proton, generated `steamclient_structs.h`, and Proton voice setup. | Prebuilt Proton/Wine bridge. Public [Proton `lsteamclient` source](https://github.com/ValveSoftware/Proton/tree/proton_11.0/lsteamclient) exists, but the exact WinNative build/patch set and applicable Steamworks SDK terms must be pinned before reuse. |
| `wnsteam/steampipe/steam_api.dll` and `steam_api64.dll` | `steam_api64.dll` contains WinNative bridge markers such as `[wnb]` and `LoadLibraryEx(Valve steamclient64.dll)`; matching bridge source is present. | WinNative bridge/generated artifact, with public source available. |
| `wnsteam/steampipe/original_steam_api64.dll` | Separate original Steam API binary retained beside the bridge. | Treat as Valve proprietary/upstream input, not as WinNative source. |

This audit does not claim that every file in the large Bionic imagefs or every
third-party runtime archive has been individually licensed. Those should be
treated as prebuilt third-party inputs until an asset manifest, source commit,
license, and checksum are recorded.

## What this means for the glibc UI plus Bionic components idea

WinNative supports the feasibility of a Bionic side, but not in-process libc
mixing. Its useful boundaries are already process/runtime boundaries:

```text
Android/Bionic WinNative-style helper
  protocol client, bootstrap, staged Android Steam libraries, optional services
                         |
                         | explicit IPC or a deliberately defined service API
                         v
Holo/glibc Steam UI
  Steam client, webhelper, Steam Runtime, Proton/Wine/FEX
```

The practical reuse split is:

1. Keep the current glibc Steam UI and its Steam Runtime isolated.
2. Study WinNative's Android-side login/service lifecycle, staging, and
   callback handling as prior art for a future helper.
3. Treat the Android `libsteamclient.so` family as a user-supplied or
   downloaded Valve artifact with recorded provenance, not as source to copy
   into this repository.
4. If a Bionic game-launch mode is tested, pair the Bionic runtime, FEX,
   Proton/lsteamclient, and client assets as one matched dependency graph.
5. Define IPC around a small capability—authentication, service requests,
   audio/input/display, or launch control—before attempting to proxy the
   entire Steam UI or Steam pipe.

Loading WinNative's Bionic `.so` files into the existing glibc Steam process
would still be the wrong approach. The ELF interpreter, libc ABI, linker
namespace, symbol versions, global state, and process assumptions are not
made compatible by putting both directories on `LD_LIBRARY_PATH`.

## Risks and follow-up audit

- Pin a WinNative commit and obtain a complete asset manifest before using any
  packaged binary in a Nova experiment.
- Record whether an asset is downloaded from WinNative, Valve's depot, Proton,
  Wine, FEX, or a driver project; the top-level GPL notice is not sufficient
  provenance for the bundle.
- Confirm the exact Proton/Wine revision behind `lsteamclient` and
  `wn-steam-helper.exe`; public upstream source establishes prior art, not
  bit-for-bit reproducibility.
- Keep the incomplete `wn-libsteamclient` implementation separate from the
  proprietary Valve client. It may be useful for a protocol/service helper,
  but it is not evidence that the full Steam client has been recreated.
- Do not infer that WinNative's Android-native client, successful login, or
  asset staging solves Nova's current game-frame, audio, input, or UI
  presentation boundaries. Those are separate acceptance gates.

## Recommendation

Use WinNative as the primary Bionic-sidecar and Steam-lifecycle reference,
while keeping the glibc/Holo UI path as the primary product path. The next
high-value work, if this track is resumed, is a host-side artifact/provenance
matrix followed by a minimal Bionic helper with explicit IPC—not a fork of the
closed Valve UI and not an attempt to merge Bionic libraries into the glibc
process.

For comparison, GameNative's public notices explicitly classify its own
`libsteambootstrap.so` as proprietary/source-withheld. WinNative's analogous
bootstrap and helper orchestration source is public; the source gap here is
mostly the Valve payloads and unpinned prebuilt upstream components, not an
unexplained WinNative-only closed implementation.
