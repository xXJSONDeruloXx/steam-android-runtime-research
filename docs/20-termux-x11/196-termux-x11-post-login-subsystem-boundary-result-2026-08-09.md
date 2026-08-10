# Termux:X11 post-login subsystem boundary result — 2026-08-09

Status: live-session diagnostic result. The signed-in Steam session remains
running while the operator tests the device. This record contains only
read-only observations; teardown and final cleanup remain pending in
[doc 195](195-termux-x11-interactive-qr-login-result-2026-08-09.md).

## Run identity

```text
run_id=termux-x11-20260809T190803Z-qr-login-interactive-0
repo_commit_at_launch=67de0e005f7bbaf3ed33764e97ac9ca5c7c180fa
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
steam_uid=501:20
```

The complete APK, client-script, D-Bus, and timeout provenance is retained in
doc 195. The live run directory is:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T190803Z-qr-login-interactive-0/
```

## Android networking versus the Steam UI

Android reported Wi-Fi enabled and connected to `BetweenTheRouterAndMe` with
`192.168.0.23`, completed WPA supplicant state, a DHCP route through
`192.168.0.1`, and DNS configured through that gateway. This is consistent with
the already-proven Steam CM/WebSocket connectivity and explains why QR login
and the signed-in home work.

The same live session's rootfs service-socket probe found the system D-Bus and
udev sockets but no `/run/NetworkManager` or `/var/run/NetworkManager`
directory. The earlier rootfs inventory also found no NetworkManager
executable or `nmcli`. Therefore the Steam network page is not reporting the
Android framework's Wi-Fi state: its Linux-side NetworkManager control plane
has no service endpoint to enumerate networks or toggle the Android radio.

This separates the problem into two layers:

```text
Android Wi-Fi/IP data plane       pass: wlan0, DHCP, DNS, Steam connections
Steam Linux radio/control plane   absent: NetworkManager endpoint/service
```

The next networking work should not claim that Android routing or NAT is
broken. It should either provide a deliberately narrow Android-to-Steam
control-plane bridge, or make the product treat Android connectivity as
authoritative and avoid exposing an unimplemented Linux radio page. Starting
`systemd-networkd` or changing the inherited Android route is not justified by
this result.

Artifact:

```text
android-wifi-status.txt=1072678a061ca8cac2b70a1649d315254c6f547b07247e7149ffb7cbc7bade0b
rootfs-service-sockets-live.txt=f92863d8ac60bc6676a32773643486b5248a2d8b21ab2be2cb70cec28ad289a7
```

## Bluetooth boundary

At the diagnostic snapshot, Android's Bluetooth manager reported:

```text
enabled: false
state: OFF
Bluetooth Service not connected
```

The operator's toggle was performed in the Steam UI, not in Android Settings.
The snapshot therefore does not prove that Android Bluetooth can never be
enabled; it does prove that the Steam UI toggle did not establish a visible
Android Bluetooth state before this capture. A future Bluetooth experiment
must first inventory whether a usable BlueZ service exists in the rootfs, then
choose between an Android Bluetooth API bridge and a compatible Linux service
contract. The Steam UI must not be treated as an Android radio controller until
that bridge is demonstrated.

Artifact:

```text
android-bluetooth-manager.txt=155418b3d370e3510b7108eaf8b5a9bb119951715673f6e1afeffa59e3b55e0b
```

## Controller capabilities and missing Steam input path

Android sees `/dev/input/event7` as an `Xbox Wireless Controller`. The device
advertises face-button key capabilities (`BTN_EAST`, `BTN_NORTH`, `BTN_WEST`,
and the additional controller button codes), shoulder buttons (`BTN_TL` and
`BTN_TR`), triggers, sticks, and all four D-pad directions. Android InputReader
classifies it as `KEYBOARD | GAMEPAD | JOYSTICK | VIBRATOR | EXTERNAL`.

That makes the missing face-button and LB/RB behavior a forwarding problem,
not an absent or unrecognized Android controller. The current direct
Termux:X11 run did not launch the repository's Linux uinput relay, so no
`Nova Virtual Xbox Controller` was injected into this session. The working
hypothesis is that the D-pad is reaching X11 as ordinary keyboard navigation,
which explains why it works while the controller-specific buttons do not. A
direct X11 event trace would be useful, but it is not required to select the
next controlled experiment.

The next input run should be fresh and separately identified:

1. launch the existing `nova-uinput-gamepad-relay` from `/dev/input/event7`;
2. verify the created virtual event node and Steam uid-501's open file
   descriptor with `nova-steam-input-fd-probe.sh`;
3. exercise A/B/X/Y, LB/RB, D-pad, sticks, and triggers one at a time; and
4. record both the low-level event forwarding and a same-run Steam UI or game
   consumer result.

The existing relay is therefore a targeted next experiment, not an assumption
that the prior uinput smoke tests automatically apply to this direct X11
session.

Artifacts:

```text
android-getevent-devices.txt=0c70e9b4f24f626e10ce7fa147aa72a9cfc7a719cec95222b9b307fa10aeb0a2
android-input-live.txt=418671c3eccf7eb13fe78cc9166bebb01f718db3cc5dde54938f9039835d1cff
rootfs-input-access-live.txt=63a351f7fd21866fa883bc2efd4fcdd0753d0f00868a03001b74dd51bd71aaa1
```

The rootfs access probe returned zero (success) for UID 501 readability tests
of `event7` and `/dev/uinput`; it did not create a virtual device or prove
that the current Steam process has opened either node.

## Display geometry

The live X11 tree reports a native root window of `1280x960`, but the mapped
`Steam Big Picture Mode` window is `1280x800` at `(0,0)`. The current Steam
client command line contains no explicit fullscreen or 1280x960 geometry
flag. Thus the Android SurfaceView can occupy the Nova's 4:3 display while the
Steam content remains in a non-4:3 window, matching the operator's visual
observation.

This needs a separate geometry run. Set and verify the mapped Steam window at
`1280x960`, capture the same X11 and Android frames, and record whether Steam
fills the display or letterboxes its own content. Do not infer 4:3 from the
SurfaceView dimensions alone.

Artifact:

```text
x11-tree-live.txt=953d1bc4dc76a55c782d3e7b9f7147862cc352eb9e0c3290773ccf2e79edbc90
```

The live process snapshot also records the exact current Steam flags and
confirms the absence of a fullscreen/resolution override:

```text
steam-processes-live.txt=a8daa4599f5a2e99ae71ee5ce9b53a972671c51a05d94607606c0ce4432587b0
```

## Decision and next steps

The current path has reached the authenticated Steam home and has a healthy
Android network data plane. The remaining observations are independent:

```text
network transport       working; Steam UI radio control is unimplemented
Bluetooth                Android service/radio state not bridged to Steam UI
controller buttons       present on Android; Linux uinput relay not active
display geometry         X11 root 1280x960; Steam window 1280x800
```

Keep this signed-in run alive for operator checks. When it is explicitly time
to stop, use the harness cleanup path and close doc 195 with fresh post-stop
and residual-process evidence. For the next work, use separate fresh runs for
the controller relay, 4:3 geometry, and Android network/Bluetooth control
plane; changing all three inside the current session would make the result
ambiguous.
