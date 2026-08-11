# AYN Thor rootless short-temporary-path public-seed rerun — predeclaration — 2026-08-11

Run ID: `thor-rootless-short-temp-public-seed-20260811T161200Z`;
sub-run: `Thor-rootless-public-arm64-seed-short-proot-temp`.

Status: predeclared after the valid X11-foreground result in [doc
478](478-ayn-thor-rootless-public-seed-refresh-x11-foreground-result-2026-08-11.md).
This is a one-variable PRoot temporary-path isolation run. It is not a
stable-channel, Vulkan-provider, `/dev/shm`, D-Bus, Proton, Gamescope, or
SteamUI experiment.

## Question and hypothesis

The Thor X11 foreground rerun passed its display lifecycle and app-UID
handshake, but the launch emitted:

```text
proot-shm-helper: Temporary path too long
```

The warning correlates with the long run-specific path used for
`NOVA_ROOTLESS_PROOT_TMP_DIR` and the guest temporary directory. Earlier R10
evidence showed that short app-owned paths removed this warning without
changing the public Steam command. The next run isolates that contract before
testing the stable ARM64 client pairing identified in the SteamClientTermux
audit.

## Fixed inputs

Keep the completed Thor refresh fixed:

- AYN Thor `kalama`, serial `d234a848`, Android API 33, `arm64-v8a`;
- app UID `10138`, rootless PRoot `-0`, `/dev` and `/proc` bindings;
- the verified Holo archive and exact 161-package/two-asset UI-audio closure;
- app-owned resolver with the fresh Android DNS value
  `nameserver 192.168.0.1`;
- the public ARM64 seed archive, version `1785979169`, and its exact archive
  SHA-256 `1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124`;
- nested `/opt/nova-steam/home/.local/share/Steam` layout and the existing
  rooted SteamRT-first `PATH`/`LD_LIBRARY_PATH`;
- direct TCP Termux:X11 at `DISPLAY=127.0.0.1:77`, with a fresh server
  explicitly foregrounded through `com.termux.x11/.MainActivity` and a
  passing app-UID `xprop` handshake;
- `-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox
  -skipinitialbootstrap -no-child-update-ui`; and
- no Vulkan selector or exploratory provider variable. Keep
  `VK_ICD_FILENAMES`, `VK_DRIVER_FILES`, `LD_PRELOAD`,
  `MESA_LOADER_DRIVER_OVERRIDE`, `GALLIUM_DRIVER`, `LIBGL_ALWAYS_SOFTWARE`,
  and `VK_IMPLICIT_LAYER_PATH` unset.

Do not use an authenticated Steam home. Do not read or copy generated
`.steam/steam.token`, `registry.vdf`, cookies, QR/session state, or any other
credential-bearing file.

## One changed contract

Use a fresh app-owned short path for PRoot's host temporary directory and the
guest `/tmp` binding. Keep the run state and all other paths fresh but use the
short relative names below, matching the already-observed R10 contract:

```text
/data/local/tmp/thor-rootless-short-temp-public-seed-20260811T161200Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r32/
/data/data/com.termux/files/home/.nova-thor-short-temp/

NOVA_ROOTLESS_STATE=files/r32/state
NOVA_ROOTLESS_PROOT_TMP_DIR=files/r32/proot-tmp
NOVA_ROOTLESS_TMP_DIR=files/r32/tmp
```

The only experimental change relative to doc 478 is the short-temporary-path
contract. Do not change the public client, channel selector, client links,
Steam environment, provider selection, X11 lifecycle, resolver, or Steam
flags. Do not add `/dev/shm`, machine-id, D-Bus, Runtime 4, Proton, route
shadows, audio, input, Gamescope, AHardwareBuffer, or SteamUI patches.

## Procedure and acceptance

1. Read the lifecycle contract and perform exact-scope cleanup. Confirm Thor's
   original `termux.properties` is restored and record fresh free space.
2. Stage the same Holo rootfs, closure, public seed, provider files, resolver,
   and client layout under the fresh `r32` app scope. Recreate the
   `.steam/steam -> /opt/nova-steam` link only.
3. Start a fresh Termux:X11 server through the APK bridge, explicitly launch
   its activity, and require a fresh app-UID `xprop` pass before Steam.
4. Run supervisor preflight with the three short paths above. Record the
   exact path lengths, owner/mode, and free-space result.
5. Launch the unchanged public-seed Steam command. Capture the first relevant
   output and fresh bootstrap/update logs.
6. Classify the result in this order:

   - if the temporary-path warning is absent, close that infrastructure
     boundary and classify any remaining `vgui2_s` or updater failure
     separately;
   - if it remains, classify the short-path implementation as invalid and do
     not infer anything about client channel or Vulkan;
   - do not treat a black X11 surface as a Steam frame.

7. Capture screenshot, X11 log, process/listener state, and exact hashes before
   teardown. Restore the original Termux configuration, terminate only the
   exact fresh X11 PID, remove only the three declared scopes plus any actual
   default helper files created by this run, and verify no process or 6077
   listener remains.

No Nova rollback-path claim applies on Thor. End the result with an explicit
 statement that no Steam authentication secret or authenticated Steam state
 was read, copied, backed up, committed, or exported.
