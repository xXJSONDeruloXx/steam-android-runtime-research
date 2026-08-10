# Nova truthful SteamOS update boundary

Date: 2026-08-10
Status: implementation committed; fresh device verification pending

## Decision

Keep the exact SteamOS helper path as a compatibility seam, but do not use the
old unconditional-success shim. The Holo ARM64 runtime has no SteamOS A/B
image updater and cannot apply or reboot into a SteamOS image. The adapter now
implements the observable legacy `steamos-update` contract:

| Invocation | Meaning in the Nova runtime | Status |
| --- | --- | ---: |
| `--supports-duplicate-detection` | Capability is available | 0 |
| `check` | No host OS update exists | 7 |
| `--enable-duplicate-detection check` | No host OS update exists | 7 |
| no arguments | No host OS update exists | 7 |
| `--enable-duplicate-detection` | No host OS update exists | 7 |
| unknown option | Invalid invocation | 1 |

Status 7 is the important boundary. Valve's legacy helper uses it for “No
update available”; status 0 means an update was applied. The reference helper
also documents this interface as deprecated in favor of `atomupd-manager`, but
the current Steam client still calls the legacy path during OOBE.

## Why not transplant SteamOS Manager

The upstream manager has separate root/system-bus and user/session-bus daemons,
and its interface is intentionally feature-detectable. The current Holo rootfs
has neither daemon, but it does provide the two D-Bus brokers required by the
direct profile. A full manager transplant would add systemd, udev/sysfs,
login1, power, firmware, and device-policy assumptions without implementing
the missing atomic updater. It is a later optional feature layer, not the
minimal OOBE update repair.

## Scope of the experiment

The next fresh run changes only the host-update boundary and its default
installation policy:

- keep the current versioned v4 rootfs, direct Termux:X11 display, two D-Bus
  brokers, current launch flags, network compatibility helper, CEF/GPU split,
  input relay, and audio bridge unchanged;
- install the truthful adapter by default;
- retain `NOVA_ANDROID_LAUNCHER_STEAMOS_UPDATE_COMPAT=0` as the missing-helper
  control; and
- do not patch SteamUI bundles, OOBE callbacks, or the Android network UI.

The host-side contract is locked by
`android/nova-lab/test-steamos-update-compat.sh`. A passing OOBE result must
show the adapter's status-7 record, no `Updater apply error: 2`, no fabricated
“update applied” result, and a transition to the login/QR route. If this still
fails, the next diagnostic is the native `CSystemManagerApplyUpdateJob` result
mapping—not another unconditional return code or view patch.

## Source evidence

The current run records the missing-helper failure as:

```text
steamos-update returned: 127
OS update result: 2
Updater apply error: 2: null
```

With the old status-0 shim, the same boundary produced `SetOOBEComplete` and
`Restarting PC` while no host update existed. The new adapter deliberately
reports absence rather than success and leaves Steam's own OOBE lifecycle
untouched.
