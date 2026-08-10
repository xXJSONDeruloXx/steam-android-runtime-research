# Nova one-click Termux:X11 extra-key-bar suppression result — 2026-08-10

## Result

The key-bar suppression hypothesis passes at the Android presentation layer.
The one-click launcher applied both Termux:X11 suppression flags, retained the
working `1280x800` stretch profile, and produced a settled signed-in Steam
frame filling the Nova's `1280x960` screen without the visible `Esc`, `Home`,
`End`, `PgUp`, or related extra-key row.

The run is not a complete product acceptance result because the launcher stop
command still returned `143` and did not emit `nova_launcher_stop=pass`. The
exact runtime cleanup and preference restoration did pass, and the final
settled process audit found no Nova runtime residue. Lifecycle completion is a
separate follow-up.

This result covers only the direct Termux:X11 product path. It does not claim
Gamescope/AHardwareBuffer output, hardware Steam/CEF rendering, game
rendering, controller consumption, touchscreen navigation, audio, or
standalone operation without the Termux:X11 dependency.

## Run identity and provenance

- Run ID: `nova-one-click-x11-keybar-suppression-20260810T111155Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- Source commit: `c7245f2509fc488eed8f65b8120d6df32003c1ca`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `2209963643c00350589b3f8aebe0084290a4efcfe3c44d8921c58b1208a6e00e`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Presentation: direct Termux:X11, Android `1280x960`, stretched X11
  buffer `1280x800`
- Steam profile: software Steam/CEF, `-cef-disable-gpu`,
  `-fullscreen -fulldesktopres`
- Gamescope/AHardwareBuffer: not used
- Audio: disabled
- Input: no synthetic or physical input sent

The complete ignored evidence directory is:

```text
android/nova-lab/build/runs/nova-one-click-x11-keybar-suppression-20260810T111155Z/
```

The run was predeclared in
[285](285-nova-one-click-x11-keybar-suppression-experiment-2026-08-10.md).

## Preference and readiness evidence

The fresh launcher log records:

```text
nova_launcher_x11_stretch=1 resolution=1280x800
nova_launcher_x11_hide_extra_keybar=1
nova_launcher_gamepad=pass
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The live Termux:X11 preference file contained:

```xml
<boolean name="showAdditionalKbd" value="false" />
<boolean name="additionalKbdVisible" value="false" />
<string name="displayResolutionExact">1280x800</string>
<boolean name="displayStretch" value="true" />
<string name="displayResolutionCustom">1280x800</string>
<string name="displayResolutionMode">custom</string>
```

The Termux:X11 log independently recorded the expected Android and X11
dimensions:

```text
Surface was changed: 1280x960
tx11-request: window changed: 1280 800 builtin
Sent shared buffer width 1280 stride 1280 height 800
Received shared buffer width 1280 stride 1280 height 800
```

The first capture, taken only eight seconds after the launcher readiness
marker, was still a black/initialization frame and was not accepted. A later
capture after the Steam client and webhelper had settled is the authoritative
visual result:

- `android-screen-settled.png` SHA-256:
  `fe55299ecc412e9d387124f94c3fe096a0cd6c33af829b05e6c3d67cbe8edc94`
- `android-screen-late.png` SHA-256:
  `5a908a702486314d367b2fa0dc8f23e1d781374d69d37d1295395120e5a0199c`

Visual inspection of `android-screen-late.png` shows the signed-in Steam
Store/Friends desktop filling the entire `1280x960` Android capture. No
Termux:X11 extra-key bar or Android settings overlay is visible.

## Steam and network session

The root-side client reached the normal direct session rather than merely
starting Termux:X11:

```text
client_network_api_compat_status=0
client_gl_mode=software
client_mesa_driver=swrast
client_gallium_driver=softpipe
client_dbus_system_status=pass
client_dbus_session_status=pass
client_started=pass
```

The settled process poll captured the ARM64 Steam client, `steamwebhelper`,
and the relay-created `Nova Virtual Xbox Controller`. The Steam client also
logged successful network API compatibility setup and its cached Steam client
update endpoints. These are supporting session facts only; this run did not
exercise UI network controls or game downloads.

## Cleanup and restoration

The during-session Termux:X11 preferences hash was:

```text
2985d0d52b35d40d9f00dfbd6c69ca994dba3c99ef1b2c71b55fb5cf19d6ec5c
```

After stop, the preference file returned byte-for-byte to the known baseline:

```text
25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895
```

The stop output recorded `nova_launcher_x11_stretch_restore=pass`, and the
final process audit found no matching `/opt/nova-steam`, Gamescope, uinput,
libei, or launcher process. The exact residual-path scan was empty.

The stop command itself returned:

```text
adb_exit_status=143
nova_launcher_x11_stretch_restore=pass
```

It did not reach the normal `nova_launcher_stop=pass` marker because the stop
ancestry terminated the long-lived start wrapper while the cleanup sequence
was still running. This repeats the previously documented lifecycle defect;
the clean final audit does not erase the missing completion marker. The next
productization change should make stop completion observable and idempotent
without broadening the cleanup scope.

## Decision and next step

Keep the key-bar suppression in the one-click default. It addresses the user's
visible bottom-row problem while preserving the existing geometry and
preference-restore contract.

Next, fix and fresh-test the launcher stop path. After that, the product work
must return to the larger gaps: make the Gamescope/AHardwareBuffer path an
APK-owned mode rather than a host-script-only test, close hardware Steam/CEF
and game rendering, and then perform full gamepad, touch, audio, networking,
and standalone-launch acceptance. The direct Termux:X11 mode remains a useful
fallback and diagnostic path, not the final Gamescope product.
