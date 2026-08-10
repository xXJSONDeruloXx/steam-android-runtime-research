# Termux:X11 network inventory result — 2026-08-09

Status: Android-host networking is demonstrably usable by the native Steam
processes inside `chroot-dev`. The remaining observed failure is a missing
local Linux control-plane service boundary, not an AHardwareBuffer or
SurfaceFlinger problem and not currently a route/DNS/TCP data-plane problem.

## Run identity and provenance

```text
run_id=termux-x11-20260809T180325Z-network-inventory-3
repo_commit=d3d54d1a11ab738ddaf19700bf469a784e5b8ef3
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
termux_x11_apk=/tmp/nova-x11-prior-art-20260809/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
source_tree=/Users/kurt/Developer/steam-android-runtime-research
rootfs=/data/local/tmp/nova-holo-rootfs
client_namespace_mode=chroot-dev
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
x11_client=android/nova-lab/device/nova-termux-x11-steam-client.sh
x11_client_sha256=9d99f0b2fe09d46ac7842e30abc6921566c2e538b5a73529f4b30d0235630934
x11_capture=android/nova-lab/build/nova-x11-capture
x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206ae3efb4b017
network_observer=android/nova-lab/device/nova-termux-x11-network-observer.sh
network_observer_sha256=64ed0dd12f5bd4bf58fd7b790ca7dfdcdeb80fa98a636c23cbb85d3a5be0d092
network_observer_duration_seconds=45
network_observer_interval_seconds=5
steam_uid=501:20
steam_timeout_seconds=75
input_mode=android-keyevent-sequence
input_keycodes=66,66,66
input_after_delay_seconds=8
capture_delay_seconds=8
window_wait_seconds=25
```

The complete run directory is:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T180325Z-network-inventory-3/
```

The Android device had no Gamescope artifact in this profile. The X11
capture, private-namespace, cleanup, mount-private, and observer hashes are
also recorded in that run's `run-metadata.txt`.

## Control and display gates

The native Steam client was selected explicitly, rather than the synthetic
X11 animator. The run found window `0x2400035`; the Android SurfaceView and
X11 captures changed after each of the three Enter key events; and the Steam
client remained alive through its 75-second bound. The final Android capture
was:

```text
android-screenshot-step-03-after-input.png
sha256=217be806f47d12e108780c725981e309d13d364ee1311b0b4bc84498a054e21b
```

It showed the live Steam Gamepad UI with the animated Steam logo and
`Waiting for network...`. This is a display/input pass, but not a login or QR
acceptance pass.

The observer itself completed successfully:

```text
network_observer_run_id=termux-x11-20260809T180325Z-network-inventory-3
network_observer_remote_status=0
network_observer_android_samples=12
network_observer_status=pass
```

The observer collected nine chroot samples from `18:03:48Z` through
`18:04:35Z` and ended at `18:04:40Z`. Exact output hashes are in the run
directory; the primary outputs are `network-chroot-observer.txt`,
`network-android-00.txt`, `network-android-11-final.txt`, and
`network-observer-status.txt`.

## Network data-plane result

The Android snapshots show a validated primary Wi-Fi network:

```text
interface=wlan0
address=192.168.0.23/24
dns=192.168.0.1
default_route=0.0.0.0/0 -> 192.168.0.1
connectivity=TRANSPORT_PRIMARY, INTERNET, VALIDATED
```

Inside the same `chroot-dev` namespace, the inherited resolver configuration
was:

```text
nameserver 192.168.0.1
hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
```

The chroot's `ip` utility was absent, so the observer used procfs for the
route view. That view showed the local `wlan0` route but did not expose the
Android default route in `/proc/net/route`; this is not treated as a failure
because real resolver and HTTPS operations succeeded and the process socket
tables were populated.

The following operations succeeded from inside the chroot:

```text
getent ahosts client-update.steamstatic.com
getent ahosts api.steampowered.com
curl --head https://client-update.steamstatic.com/  # HTTP 403, curl status 0
curl --head https://api.steampowered.com/           # HTTP/2 404, curl status 0
```

The native Steam process (`steam`, PID 19468 in this run), its
`steamwebhelper` parent (PID 19480), and the Chromium network service (PID
19540) showed external established TCP sockets in their per-process
`/proc/<pid>/net` views. The encoded local address `1700A8C0` corresponds to
`192.168.0.23`; the connections were not limited to loopback or the X11
socket. This directly demonstrates that the actual Steam/webhelper processes
are using the Android host's network path.

Therefore the next experiment must not add a Linux-owned Wi-Fi route, NAT,
proxy, or alternate network namespace. The inherited Android data plane is
already the desired path and is working.

## Missing local service boundary

The same fresh observer window found no local Linux service endpoints:

```text
/run/dbus/system_bus_socket       absent
/var/run/dbus/system_bus_socket   absent
/run/dbus/user_bus_socket         absent
/var/run/dbus/user_bus_socket     absent
/run/NetworkManager/private       absent
/var/run/NetworkManager/private   absent
/usr/bin/dbus-daemon              present
NetworkManager binary              absent
nmcli                              absent
```

Fresh Steam log lines from this run recorded:

```text
operator(): failed to create a NMClient: Could not connect: No such file or directory
Init: failed to create a NetworkManager client
Connectivity test: result=Connected
```

Steam's stderr also reported that the runtime launch service could not find a
session bus. These observations make the missing D-Bus/NetworkManager
boundary the strongest current candidate for the Gamepad UI's incomplete
login bridge. They do not yet prove that it is the direct cause of the
missing `SteamClient.User` methods: the data-plane inventory and the User API
probe remain separate gates.

The absence of NetworkManager is important. A session bus alone can test the
session-bus portion of this boundary, but it cannot satisfy Steam's
`NMClient` system-bus calls without a compatible system bus and service. We
should therefore test those boundaries separately rather than introducing a
large fake service or silently patching the UI.

## Decision and next experiment

This experiment resolves the first networking question:

```text
Android/chroot data transport = pass
DNS and HTTPS from Steam namespace = pass
Steam/webhelper external sockets = pass
Local D-Bus session/system service boundary = absent
NetworkManager service contract = absent
Steam login/QR surface = not reached
```

The next one-variable experiment is a run-scoped session-bus test using the
existing `/usr/bin/dbus-daemon`, if its executable and supporting files pass
preflight. It will preserve the exact display, input, Android network, and
Steam flags from this run, set only the session-bus environment, and record
whether the Steam UI bridge or login API changes. It is explicitly not a
NetworkManager test. If it has no effect, the following experiment should
address the system-bus/NetworkManager contract only after verifying that a
compatible service binary or package is actually available.

No Gamescope, AHardwareBuffer, SurfaceControl, SurfaceFlinger, route/NAT, or
UI-bundle changes are part of this networking conclusion.

## Cleanup

The exact-scope teardown passed:

```text
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
termux_x11_post_stop=pass
nova_runtime_cleanup=pass
```
