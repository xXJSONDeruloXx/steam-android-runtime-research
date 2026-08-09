# Termux:X11 network inventory observer-path result — 2026-08-09

Status: observer harness failure; display/input and native Steam startup
passed, but no networking conclusion was accepted.

## Run identity

```text
run_id=termux-x11-20260809T180047Z-network-inventory-2
repo_commit=2d5c69b8ac2cab3090ab5a9098e5b4790b365e78
adb_serial=675a2365
device=Retroid Pocket Nova
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_client=android/nova-lab/device/nova-termux-x11-steam-client.sh
x11_client_sha256=9d99f0b2fe09d46ac7842e30abc6921566c2e538b5a73529f4b30d0235630934
bind_android_dev=1
client_namespace_mode=chroot-dev
x11_window_id=0x2400035
network_observer_duration_seconds=45
network_observer_interval_seconds=5
```

## Validated control gates

The native Steam profile was selected explicitly. The same X11 window remained
viewable through the three focused Enter events, Android and X11 captures
changed at each step, and the Steam client stayed alive to its 75-second
bound. The run therefore reproduced the proven direct display/input path.

The fresh Steam log also recorded the expected native-session environment
boundary, including absent DBus/session services and successful local X11
authorization. Those observations are retained as context, but this result
does not interpret them as the networking answer because the dedicated
inventory observer did not run.

## Observer failure

The observer host process recorded:

```text
network_observer_remote_status=127
network_observer_status=fail
```

The device-side output was:

```text
mount_private=pass path=/
env: '/data/local/tmp/nova-termux-x11-network-observer-termux-x11-20260809T180047Z-network-inventory-2.sh': No such file or directory
```

The script had been pushed to `/data/local/tmp/...`, outside the chroot, but
the observer was invoked with that Android path from inside the chroot. The
correct invariant is to stage it under the rootfs (for example
`$DEVICE_ROOT/tmp/...`) and invoke its chroot-visible `/tmp/...` path. This is
now repaired in the harness; the observer remains opt-in and observation-only.

## Cleanup

The exact-scope teardown still passed:

```text
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
termux_x11_post_stop=pass
nova_runtime_cleanup=pass
```

## Next action

Commit and push the path repair, then rerun the same native profile with the
same flags, input, observer duration, and fresh run identity. Accept only a
run with `network_observer_status=pass` and timestamped Android plus chroot
samples.
