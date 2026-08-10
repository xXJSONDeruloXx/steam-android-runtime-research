# Nova fresh APK OOBE and QR result — 2026-08-10

Status: after the native Steam bootstrap update completed, one additional
**Start Steam** tap reached the real Steam QR login screen from the freshly
provisioned APK/runtime. The end-to-end display/OOBE path is therefore proven,
but the first tap still needs an automatic update handoff.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`
- Runtime: `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4`
- Resume launcher session: `20260810T215144Z-22701`
- APK SHA-256:
  `9f352805235ca005d9cffcb2c50aad9674d1ed1ea2a4218a44aa17f10324e07a`
- Profile: direct Holo ARM64 glibc through Termux:X11, 1280×960 Steam target,
  native Steam OOBE, no OOBE view rewrite, software CEF, audio bridge, uinput
  relay, and the existing one-restart supervisor.

## Resume result

The second tap was idempotent: the provisioner reported
`nova_provision_status=already-active` and did not redownload or rebuild the
runtime. X11, the uinput relay, the audio bridge, Steam, and SteamWebHelper
all reached a fresh ready state. The native OOBE selections were completed:

1. English;
2. Eastern Standard Time; and
3. Continue with Android host network.

Steam then reached the real sign-in page with the QR login control visible at
the current 1280×960 display geometry. Fresh filtered Steam evidence recorded:

```text
SteamUI: WARNING: SetOOBEComplete
SteamUI: WARNING: Restarting Steam
SteamUI: WARNING: OOBE Stage 2: completed
SteamUI: WARNING: No restart requested
SteamUI: INFO: Login: OnLoginStateChange  1 1 0 0
```

This confirms the native OOBE contract itself is working after bootstrap; the
earlier blank-after-network behavior is not present in this run.

## Authentication boundary

The QR page was visually inspected only. Its temporary Android capture was
deleted immediately after inspection. No QR image, Steam token, account name,
password, or other authentication secret was exported, backed up, or added to
the repository. The live session remains running at the QR page for the
operator's next login check.

## Acceptance status

| Gate | Result |
| --- | --- |
| Fresh APK install and notification permission | pass |
| Rooted versioned provisioning with artifact verification | pass |
| Atomic runtime activation | pass |
| Native Steam bootstrap update | pass, but requires a second tap |
| Native language/timezone/network OOBE | pass |
| QR login screen | pass after second tap |
| First-tap one-click handoff through update | not yet pass |
| Signed-in Big Picture and post-login baseline | deferred to operator login |

The next implementation should add a bounded, observable bootstrap-update
handoff/relaunch while preserving the current one-restart limit, and should
make the first-tap root-denial state explicit instead of opening a disconnected
Termux:X11 surface.
