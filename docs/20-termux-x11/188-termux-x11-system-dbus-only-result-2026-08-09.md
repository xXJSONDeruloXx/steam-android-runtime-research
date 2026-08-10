# Termux:X11 system-D-Bus-only result — 2026-08-09

Status: success for the current blocker. Supplying the standard system D-Bus
made Steam initialize its system network controller and reach the real Steam
sign-in/QR surface on the Android screen. No NetworkManager executable,
networkd, resolved, route, NAT, proxy, Gamescope, AHardwareBuffer, or
SurfaceFlinger change was used.

## Run identity and provenance

```text
run_id=termux-x11-20260809T184950Z-network-system-bus-0
repo_commit=feb6d1bc33e34139be53c34f1ff5ea60c2b508fb
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
android/nova-lab/build/manual-runs/termux-x11-20260809T184950Z-network-system-bus-0/
```

## System-bus and network evidence

The run started the shipped rootfs D-Bus daemon at the standard system path:

```text
client_dbus_system_config=/usr/share/dbus-1/system.conf
client_dbus_system_socket=/run/dbus/system_bus_socket
client_dbus_system_status=pass
```

The optional direct UID-501 `dbus-send --system ... ListNames` probe timed out,
and the daemon reported that activation of `org.freedesktop.login1` could not
use the rootfs setuid helper. This does not invalidate the bus reachability
result: Steam itself successfully used the bus contract needed by this run.
Those limitations remain recorded rather than being silently treated as a
fully working SteamOS system service layer.

The fresh Steam system log changed from the no-system-bus baseline:

```text
Initialized CSteamUINetworkController: 1
```

The fresh network log recorded:

```text
Init: enable connect workaround: 0
Init: create NetworkManager client: success
```

The previous fresh-run error, `failed to create a NMClient: Could not connect:
No such file or directory`, did not recur in this run. The rootfs still has no
NetworkManager executable and no `/run/NetworkManager/private`; the successful
`libnm` initialization therefore must not be described as a complete
NetworkManager implementation.

The fresh connection log also reached the external Steam CM:

```text
ConnectionCompleted() (162.254.198.68:27019, WebSocket) local address (192.168.0.23:59961)
Client thinks it can connect via: UDP - yes, TCP - yes, WebSocket:443 - yes, WebSocket:Non443 - yes
Connected
```

The fresh `steamwebhelper` log contained no `/run/dbus/system_bus_socket`-
missing errors. Android network observation passed with 16 samples.

## Login-surface acceptance

The live, fresh CDP probe returned the actual login page, not the previous
waiting state:

```text
title=Steam Big Picture Mode
body=Sign in / Use the Steam Mobile App to sign in via QR Code / Create account / SIGN IN WITH ACCOUNT NAME / PASSWORD
```

The `SteamClient.User` method names remained undefined in this build, so that
API shape is not a reliable acceptance gate once the real login page is
rendered. The page body and the paired physical capture are the acceptance
evidence for this milestone.

```text
cdp-login-state.json=da0d2eaa6d125fe351f22c4da1524a6fd1a9ba1ea8415516eecea46c8bf0670d
android-screenshot-step-03-after-input.png=04757b036437a1600b8417af51ff919aa277520274b8ac3f64f644f76bf5743c
x11-window-step-03-after-input.ppm=b914bf11306fdd83a97adbc5c16282c7caa6d72c985575c931b054a34d3fc628
```

The Android screenshot visibly shows the QR code, “Sign in” heading, mobile
app instruction, account-name/password form, and the sign-in controls. The
Termux:X11 capture was taken at the same controlled input step.

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
```

## Decision

The Android-hosted data path was not the blocker. The minimum observed
unblocker for this Steam client is the standard local system-D-Bus endpoint;
the session bus repair is also retained because it keeps the Steam Runtime
Launch Service healthy. The networking branch has now reached the requested
QR-code login surface on the real device.

Next work should be a fresh repeat of this exact two-bus profile to establish
repeatability, followed by making the system-bus dependency a named,
run-scoped Termux:X11 profile. Keep the system bus and the absent
NetworkManager/systemd activation limitations explicit; do not add a fake
NetworkManager or reopen Gamescope-to-AHardwareBuffer work based on this
result.
