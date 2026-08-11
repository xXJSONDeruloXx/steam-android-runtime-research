# Nova rootless R25 — rooted public-client parity predeclaration — 2026-08-11

Run ID: `nova-rootless-r25-rooted-parity-steamui-20260811T124700Z`;
sub-run: `R25-rootless-supervisor-rooted-public-client-parity`.

Status: predeclared after the R24 SDL3 boundary and the host provider audit in
[doc 459](459-nova-rootless-steam-sdl3-provider-host-audit-2026-08-11.md).
This is the requested parity experiment: determine whether the public client
and runtime closure that carried the rooted APK through native OOBE/QR can
carry the app-UID PRoot path farther into SteamUI.

## Why this run exists

The rootless R22–R24 runs intentionally used a minimal stable raw seed. That
seed is not the rooted happy path:

| Boundary | Rooted known-good path | Rootless R22–R24 path |
|---|---|---|
| Client channel | Public-beta seed, build `1785979614` | Stable raw seed, build `1785799196` |
| Client closure | Completed post-bootstrap ARM64 client and SteamRT3C tree | Raw `steamrtarm64/` seed plus the experimentally matched FFmpeg family |
| Channel marker | `package/beta=steamdeck_publicbeta` | `package/beta` absent |
| Launch | Gamepad UI/SteamOS flags with the rooted bounded lifecycle | Bare `steamrtarm64/steam -noverifyfiles` |
| Steam layout | Conventional `.steam` links and updated client directories | Fresh app home with only `.steam/steam -> /opt/nova-steam` |
| Privilege | Rooted private mount namespace/chroot | App UID, no `su`, PRoot path translation |

R25 deliberately ports the public client/runtime/layout/flag portion of that
contract without porting rooted privilege or authentication state. It is a
higher-level parity test than the one-file SDL3 A/B; a pass will establish a
useful rootless client profile, while a failure will be followed by a narrow
experiment rather than more unclassified copying.

## Public source artifacts

The public-beta source is pinned by the rooted provisioning manifest:

```text
steam_seed_package=bins_linuxarm64_linuxarm64.zip.7affd5c9053499769e4f0a46bbb6cbdf0ba0d548
steam_seed_size=109767888
steam_seed_sha256=b2de13c267e101679750445c9c449fbfb58dbb7c9851729e95ac69637b9df563
steamrt_snapshot=3c.0.20260714.251839
steamrt_sha256=f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0
```

The host completed bootstrap used for R25 is:

```text
android/nova-lab/build/steam-bootstrap/home/.local/share/Steam/
```

Its public client metadata records build `1785979614`:

```text
package/beta
  size=21
  sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
package/steam_client_steamdeck_publicbeta_linuxarm64.installed
  size=1549302
  sha256=8fc3a43264a6f1c37895ed43e324f1121db6d7129d1fb70ffd6346abe0b0f5d9
steam-runtime-steamrt-arm64/VERSIONS.txt
  sha256=b41d058bc7f4c8bd220f999661ac64fcbb40aa5ffe396c7eae25715f48ff3726
```

The staged `steam-client/` will be a sanitized public copy of that completed
Steam tree, excluding only its `logs/` directory. Before staging, verify that
no `config`, `userdata`, `loginusers.vdf`, `ssfn*`, or other authentication
state exists; do not copy any such path if one appears. The aggregate staged
tree manifest and size will be recorded in the result document.

The sibling prior-art checkout used for the parity contract is clean at:

```text
/Users/kurt/Developer/steamclienttermux
HEAD=8d14c10195b34fe2714ba59df1680df27a852532
```

The existing Holo rootfs archive, 161-package closure, PRoot binaries,
resolver, and external GTK2 assets remain the R24 inputs unchanged. The Valve
client-side `libSDL3.so.0` and the matched FFmpeg family are included by the
completed public client; no preload or compatibility library is added.

## Controlled change

Keep unchanged from R24:

- Holo ARM64 rootfs archive and 161-package UI/audio closure;
- app-UID PRoot and no-`su` supervisor contract;
- app-owned resolver, state, home, temporary directories, and fresh Steam data;
- direct Termux:X11 at `127.0.0.1:6077`, guest `DISPLAY=127.0.0.1:77`;
- inherited Android network path and no route/proc-net shadow;
- no Gamescope, AHardwareBuffer, Proton, game, authentication, or SteamUI
  patch;
- exact-scope cleanup and preserved rooted rollback paths.

Change only the public client parity inputs:

1. Replace the stable raw `steam-client/` with the sanitized completed
   public-beta Steam client tree, including the completed `steamrtarm64/`,
   `steam-runtime-steamrt-arm64/`, public UI directories, and `package/`
   metadata, but excluding `logs/` and any auth state.
2. Preserve `package/beta=steamdeck_publicbeta`.
3. Add the rooted conventional app-home links after supervisor preparation:
   `.steam/root -> /opt/nova-steam`, `sdk32`, `sdk64`, `sdkarm64`, `bin32`, and
   `bin64`, all targeting the corresponding public client directories. The
   supervisor-owned `.steam/steam -> /opt/nova-steam` link remains authoritative.
4. Launch the already-completed client with the rooted Gamepad UI flags and
   bounded no-bootstrap lifecycle:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui'
```

Do not use `-noverifyfiles` for this parity run unless the completed public
manifest itself proves stale; the point is to test the normal completed-client
boundary. If the client requests an in-session restart, record it as a
lifecycle result and allow at most the existing bounded policy in a later
experiment; do not loop or silently relaunch in R25.

## Device and exact mutable scope

```text
Device: Retroid Pocket Nova, serial 675a2365, Android API 33, arm64-v8a
Branch: feat/rootless-steamclienttermux-profile
APK: android/nova-lab/build/nova-lab-debug.apk

/data/local/tmp/nova-rootless-r25-rooted-parity-steamui-20260811T124700Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r25/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No Steam authentication secret may be read, copied, backed up, or exported.

## Acceptance and decision rule

Capture fresh updater/client/SteamUI/webhelper logs, process state, listener
state, and a screenshot before teardown. The first positive boundary is a
loaded `steamui.so`; a UI pass requires a visible fresh Steam frame and a
fresh `steamwebhelper`. Classify failure as one of:

- missing public client file or update/lifecycle boundary;
- Holo/provider ABI or dynamic loader boundary;
- CEF/SteamUI/X11 display boundary;
- network/audio/input capability boundary;
- unrelated process or cleanup failure.

If R25 loads SteamUI, retain the parity profile and next isolate webhelper,
audio, input, or OOBE lifecycle. If it fails at a new library, audit the
completed public tree before staging anything else. If it passes SteamUI but
not OOBE, compare the rooted restart/update helper separately; do not patch
OOBE views or copy rooted Steam data.
