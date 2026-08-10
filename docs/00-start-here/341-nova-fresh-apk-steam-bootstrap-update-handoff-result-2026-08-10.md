# Nova fresh APK Steam bootstrap-update handoff result — 2026-08-10

Status: clean provisioning passed, but the first native Steam bootstrap update
ended the one-click session instead of handing control to a second Steam
attempt. This is the remaining first-launch blocker after root authorization.

## Run identity and result

- Device: Retroid Pocket Nova, serial `675a2365`
- Runtime: `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4`
- Launcher session: `20260810T214544Z-19973`
- APK SHA-256:
  `9f352805235ca005d9cffcb2c50aad9674d1ed1ea2a4218a44aa17f10324e07a`
- Profile: unchanged direct Termux:X11 one-click profile from the prior QR
  result; only the fresh device state and Magisk authorization differed.

## Provisioning gate

The freshly installed APK completed the intended first-run flow from empty
device state:

```text
nova_provision_verified=system.rootfs.zst size=384971555 sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
nova_provision_verified=bins_linuxarm64_linuxarm64.zip.7affd5c9053499769e4f0a46bbb6cbdf0ba0d548 size=109767888 sha256=b2de13c267e101679750445c9c449fbfb58dbb7c9851729e95ac69637b9df563
nova_provision_verified=steam-runtime-steamrt-arm64.tar.xz size=52343604 sha256=f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0
nova_zip_rebase=pass prefix=20 entries=55
nova_provision_active=pass root=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
nova_provision_status=pass version=nova-holo-direct-x11-20260810-v4
```

The launcher then reported `nova_launcher_ready=pass display=:0
geometry=1280x960`, with the expected X11 server, uinput relay, audio bridge,
and Steam process tree alive.

## Steam update handoff

The first Steam screen was the real native updater. It downloaded the complete
`657758 KB` client update, extracted it, installed it, and recorded:

```text
Update complete, launching...
ProcessNextMessage: socket disconnected
No more messages are expected - exiting
```

The direct client recorded `client_attempt_status=42`, but
`client_restart_evidence=absent` because the existing supervisor only watches
fresh `SteamUI: WARNING: Restarting Steam` records in `webhelper_js.txt`. The
bootstrap updater writes its handoff to `logs/updateui_child.txt` instead.
The direct client then exits zero by design, the one-click wrapper cleans up,
and the Android service returns to Nova with:

```text
nova_launcher_client_exit=0
nova_launcher_stop=fail status=1
Nova launcher exited with status 1
```

The visible result is the Nova home screen with no Steam/X11 processes. The
session therefore requires the operator to press **Start Steam** a second time
after the client update. That is not a smooth fresh-install experience.

This was not the `steamos-update` compatibility shim: the evidence is Steam's
own `updateui_child.txt` bootstrap update path, and no SteamOS view patch was
enabled. No authentication material was retained or exported.

## Exact remaining defects

1. The one-click launcher does not recognize a successful native bootstrap
   update as a request to relaunch Steam in the same user action.
2. X11 cleanup reports status `1` after the bootstrap child disconnects even
   though the matching processes are gone. The cleanup path should tolerate
   this already-absent server state or expose it separately from the user-
   visible launch result.

## Predeclared follow-up

Use the already activated runtime and the now-updated Steam data tree for a
bounded post-bootstrap resume check. Change only the action from the first
**Start Steam** tap to a second **Start Steam** tap; do not change graphics,
network, OOBE, or input variables. If Steam reaches native OOBE, record the
result separately. Then implement and test a bounded automatic bootstrap
handoff, preserving the existing one-restart limit and cleanup guarantees.
