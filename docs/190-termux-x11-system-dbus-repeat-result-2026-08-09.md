# Termux:X11 system-D-Bus repeat result — 2026-08-09

Status: repeat success. The system-D-Bus unblocker reproduced the real Steam
QR login surface in a second fresh run with the same profile and independent
process, log, CDP, and screenshot artifacts.

## Run identity and provenance

```text
run_id=termux-x11-20260809T185417Z-network-system-bus-repeat-0
repo_commit=966c0e723e27c530f9159bc21d243f570a95c2bd
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
termux_x11_apk=/tmp/nova-x11-prior-art-20260809/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_client=android/nova-lab/device/nova-termux-x11-steam-client.sh
x11_client_sha256=a5d032caeda8c34f0384201c14f9dd91fc4394beaad2cfdcaf6d80246143299c
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
steam_uid=501:20
steam_timeout_seconds=90
dbus_session=1
dbus_session_user=steam
dbus_session_uid_record=1
dbus_system=1
network_observer_duration_seconds=60
```

The complete run directory is:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T185417Z-network-system-bus-repeat-0/
```

## Repeated network/system-service result

The fresh system log again reported:

```text
Initialized CSteamUINetworkController: 1
```

The fresh NetworkManager-client log again reported:

```text
Init: enable connect workaround: 0
Init: create NetworkManager client: success
```

The native client reached a Steam CM over the inherited Android connection:

```text
ConnectionCompleted() (162.254.192.98:443, WebSocket) local address (192.168.0.23:48769)
Client thinks it can connect via: UDP - yes, TCP - yes, WebSocket:443 - yes, WebSocket:Non443 - yes
Connected
```

This repeats the first system-bus run's transition from
`CSteamUINetworkController: 0`/`NMClient ... No such file or directory` to an
initialized controller and successful client network initialization. It does
not claim that a full NetworkManager daemon exists; the rootfs still lacks the
NetworkManager executable and the standard private socket.

## QR/login acceptance

Fresh CDP returned:

```text
title=Steam Big Picture Mode
body=Sign in / Use the Steam Mobile App to sign in via QR Code / Create account / SIGN IN WITH ACCOUNT NAME / PASSWORD
```

The repeated QR/login evidence hashes are:

```text
cdp-login-state.json=4ade844f24b26f234e3ee27e015fcee7299b7a4699d2569a8ca895f6bae715e4
android-screenshot-step-03-after-input.png=ed0bf4cffb9c67b5f11c06e8e02b62f7fe9b27a022184b4ff3de7b80e0041bac
x11-window-step-03-after-input.ppm=69b28b8f37a1bff1998381bf0768b4aeda35a1e80043991365507803d739b249
```

The Android screenshot visibly shows the fresh QR code, “Sign in” heading,
mobile-app instruction, account-name/password form, and controls. The QR
payload changed from the preceding run, which is additional evidence that the
screen is live rather than a reused capture.

## Cleanup

```text
dbus_system_cleanup=pass socket=/run/dbus/system_bus_socket
dbus_session_cleanup=pass
dbus_session_dir_cleanup=pass
dbus_session_passwd_restore=pass
termux_x11_post_stop=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass
network_observer_status=pass
network_observer_android_samples=17
```

## Decision

The system-D-Bus requirement is repeatable for this exact Termux:X11/native
ARM64 Steam profile. The branch has cleared the current networking blocker to
the QR-code login surface without reopening the compositor path. The next
repository step is to package the two-bus setup as an explicit named profile,
keep the service limitations visible, and then review whether this research
branch is clean enough to merge into `main`.
