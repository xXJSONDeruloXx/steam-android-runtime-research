# Termux:X11 network inventory window-wait result — 2026-08-09

Status: harness-boundary failure; no networking or Steam result was accepted.

## Run identity

```text
run_id=termux-x11-20260809T175717Z-network-inventory-0
repo_commit=1ffd0e62fee05b5b6d4202a5fe9ee5ca762968c6
adb_serial=675a2365
device=Retroid Pocket Nova
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
bind_android_dev=1
client_namespace_mode=chroot-dev
network_observer=1
network_observer_duration_seconds=45
network_observer_interval_seconds=5
x11_window_wait_seconds=1
```

The predeclared [network inventory experiment](173-termux-x11-network-inventory-experiment-2026-08-09.md)
was launched with the committed observer and the required fresh cleanup
preflight. Termux:X11 created its display socket:

```text
termux_x11_server=pass display=:0 socket=/data/local/tmp/nova-holo-rootfs/tmp/.X11-unix/X0
```

The launcher then stopped at the one-second X11 window discovery bound:

```text
X11 window was not discovered after 1s
```

No X11 capture, input event, Steam readiness result, or network observer
sample was collected. This is not evidence about Android routing, DNS, Steam,
or the missing `SteamClient.User` bridge.

## Cleanup

The exact-scope cleanup contract passed on exit:

```text
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
termux_x11_post_stop=pass
```

The run metadata records all staged artifact paths and hashes. The failure is
isolated to the pre-existing default `NOVA_TERMUX_X11_WINDOW_WAIT_SECONDS=1`
being too short for this fresh server/client startup. The observer code itself
was not exercised.

## Next action

Repeat the same predeclared inventory with only
`NOVA_TERMUX_X11_WINDOW_WAIT_SECONDS=10` changed. Keep the observer, Steam
flags, namespace, input sequence, and rendering path unchanged. Do not
interpret the retry until the X11 window and observer acceptance gates pass.
