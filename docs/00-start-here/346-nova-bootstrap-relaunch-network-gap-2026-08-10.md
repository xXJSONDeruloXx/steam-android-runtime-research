# Nova bootstrap relaunch network-gap result — 2026-08-10

Status: the bounded bootstrap-handoff fix passed its first gate, but exposed a
second same-process boundary before QR. The automatic relaunch worked and
reached Steam OOBE on the first **Start Steam** tap. The network OOBE then
showed **No networks found** because the existing network compatibility rewrite
had been deliberately deferred during the initial seed bootstrap and was not
re-applied inside the new relaunch.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`
- Run: `fresh-apk-bootstrap-relaunch-20260810T224245Z`
- Repository: `main` at `3a1c3e4`
- APK used: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `31566c6a3ed0f4a3a0ef7ccca33a0da1d6c7c8973b517fd0845fdeac472f942f`
- Profile: clean direct Holo ARM64 glibc runtime through Termux:X11

The device was scrubbed with the exact Nova scope before this run. Termux:X11
was preserved. No authentication secret or QR image was retained.

## Observed sequence

Provisioning downloaded and activated the same verified v4 runtime, then the
first Start action showed the native `657758 KB` Steam bootstrap update. After
the updater shut down, the client log recorded:

```text
client_attempt_status=42
client_bootstrap_handoff=1
client_bootstrap_relaunch=1
client_flags_relaunch=... -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
client_attempt=2
```

The same X11 session stayed alive and reached language and timezone OOBE with
no second Start tap. This confirms the handoff fix itself.

After selecting Eastern Standard Time, the network page showed:

```text
No networks found
```

The first client attempt correctly logged:

```text
client_network_api_compat=deferred reason=missing_steamui
```

The client script computed `STEAMUI_PRESENT=0` once before the bootstrap and
then reused that state during its in-process relaunch. The new SteamUI bundle
therefore did not receive the existing `nova-steam-network-api-compat.sh`
rewrite that a separate second Start would have applied.

## Correction predeclared for the next run

The client now re-evaluates the post-bootstrap state, marks SteamUI present,
and calls the same fail-closed network adapter before adding the post-bootstrap
flags. Already-patched bundles remain idempotent. A failed rewrite aborts the
relaunch instead of presenting a misleading network screen.

- Planned run: `fresh-apk-bootstrap-network-fix-20260810T225411Z`
- Rebuilt APK SHA-256:
  `4fe7660e809ca424c970a35f4685b6b3f779014e942a85279fae9dcb4de7519b`
- Required acceptance: first Start, automatic bootstrap relaunch, language,
  timezone, host-network option, and QR without a second Start tap

The update adapter, SteamOSManager absence, Gamescope/AHardwareBuffer scope,
and authentication policy are unchanged.
