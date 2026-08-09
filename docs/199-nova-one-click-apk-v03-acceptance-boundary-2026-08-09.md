# Nova one-click APK v0.3 acceptance boundary

Date: 2026-08-09  
Device: Retroid Pocket Nova, Android 13, `kalama`, adb serial `675a2365`  
Branch: `feat/nova-one-click-launcher`

## Scope

This record covers the first device acceptance attempts for the standalone
`com.xjsonderulo.steamandroid.novalab` launcher APK. The APK's current product
path is direct Termux:X11; it does not yet package or select the Gamescope /
AHardwareBuffer path. The 198X game-launch result is recorded separately in
[198](198-termux-x11-198x-game-launch-result-2026-08-09.md).

The exact Nova lifecycle contract in [34](34-nova-runtime-harness-lifecycle.md)
was read immediately before each device run. Each attempt used a fresh local
run directory and the exact runtime cleanup helper on exit.

## Artifact identity

The APK was built by `android/nova-lab/build.sh`, signed with the local debug
keystore, and verified by `apksigner`.

| Attempt | Source state | APK SHA-256 | Version |
| --- | --- | --- | --- |
| initial launch | `8fb5c20` | `1f64fc080989652422de52e7f159432113399564442eaffad22a5af6e8f1c155` | 0.3 |
| window-order retry | `d641095` | `c0b57de4ee3fbe75ed4a90a0dc4f289d36a45f2f502985d2b26baddd436da21c` | 0.3 |
| preflight-guard fix, pending device retest | `0d137c6` | `a5f4a5512fc89da9380eb275a81d1f408ed11796f0655be83f1f512b3f56b2a0` | 0.3 |
| relay-corrected build | `00ed01c` | `d9288c9f7843c215441c074d51491e473b7b53453a1e4454adb4a576db766306` | 0.3 |
| timeout/cleanup fix, pending device retest | working tree after `00ed01c` | `9124807429ff6d21a3c7556865cf6a33b0c8999ac8673cc4b5629b46839b3ec1` | 0.3 |
| single-controller namespace refinement, device-tested | `3681167` | `25d389dddc26cff7cbb53f39f6169cbbfc05eed68336dab53d09a4e4197d2ef0` | 0.3 |
| relay-event allowlist refinement, device-tested | `21ad85a` | `d52d966749a4e6cc5b23c4548adce8c0161cea7c66aba5392fa2167bc191a356` | 0.3 |

The runtime inputs for these attempts were the direct launcher mode: Termux:X11
APK `/data/app/~~EaHbYh5LSrJyPyjYrj44Wg==/com.termux.x11-Yy3Sfe-6FUYa5hx2OcDldw==/base.apk`,
rootfs `/data/local/tmp/nova-holo-rootfs`, display `:0`, Steam flags
`-fullscreen -fulldesktopres`, and the ARM64 uinput relay when available.

## Results

### `launcher-20260809T195502Z-apk-v03-direct-input-geometry`

Installation succeeded, but starting `LauncherActivity` failed before the
launcher view was created. Android logged:

```text
FATAL EXCEPTION: main
Unable to start activity ... LauncherActivity:
NullPointerException ... DecorView.getWindowInsetsController()
at LauncherActivity.enterImmersiveMode(LauncherActivity.java:267)
```

The cause was calling `enterImmersiveMode()` before `setContentView()`. No
rooted Steam process was started. The fix moved the call after
`setContentView()` and was committed and pushed as `d641095`.

### `launcher-20260809T195802Z-apk-v03-window-order-retry`

The corrected APK rendered the launcher screen on the Nova. The visible frame
was 1280x960 and showed the expected `Start Steam`, `Stop Nova session`, and
`Open diagnostics lab` controls. The screenshot hash is
`4c2fc38bec52f06bf64adcfbeca2be5f25f3925ac37d377c1c38cb4670de2cdb`.

The device UIAutomator dump returned `null root node` even while the screenshot
showed the activity, so the button was activated at the captured `Start Steam`
location `(640,412)` and the window focus was recorded separately.

The root-side launcher then rejected the start with:

```text
nova_launcher_start=fail reason=existing_nova_runtime
```

The post-failure process table contained no matching Nova rootfs, Steam,
Gamescope, Termux:X11, or relay process. The failure was a launcher
preflight false positive: its `runtime_present()` pipeline searched the
process table for literal Nova paths while its own `awk` command line also
contained those literals. A minimal reproduction captured the `awk` process
itself as a match. The preflight now excludes `awk`, matching the existing
cleanup helper's self-match protection.

The corrected preflight build is `a5f4a5512fc89da9380eb275a81d1f408ed11796f0655be83f1f512b3f56b2a0`.
It has not yet been installed and run on the device at the time of this
record, so standalone APK-to-Steam acceptance remains pending.

### `launcher-20260809T200145Z-apk-v03-preflight-guard`

The preflight-guard build (`a5f4a5512fc89da9380eb275a81d1f408ed11796f0655be83f1f512b3f56b2a0`)
was installed successfully. The APK rendered, the root launcher passed its
preflight, and the fresh state reached:

```text
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The APK therefore launched native ARM64 Steam and `steamwebhelper` from the
rootfs. The Android capture reached the signed-in Steam home screen; its SHA is
`5f4ac46dfbcc2261ee232ea28f521dc3c6771caf5dad14bb72b6b10e8cfe877b`.
The X11 tree and window capture were both fresh and stable: the root was
1280x960, while `Steam Big Picture Mode` was explicitly created as
1280x800. The baseline and settled X11 PPM hashes were
`3b1d600afb64cbe3eb5c886559a7270763250a68c5e3c1453a1b72f6457da174` and
`c02a9eb80c69975825f1d54a6d608e9fad82ef0f1036ff48551fd7592f26db8d`.
This confirms the remaining black bottom band is a Steam/X11 window-size
decision, not an Android SurfaceView crop; `-fullscreen -fulldesktopres` did
not make the Big Picture window 4:3.

The physical input relay did not reach readiness:

```text
nova_launcher_gamepad=not_ready
env: '/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver/nova-uinput-gamepad-relay': No such file or directory
```

The binary was present in the staged rootfs. The failure is in
`nova-uinput-gamepad-relay-launcher.sh`: it passed a host-root absolute helper
path into `chroot`, which caused the chroot to look for the path a second time
under the root. The wrapper now strips the root prefix before `chroot`.

This does not mean controller support was absent in this run. Steam's fresh
`controller.txt` detected the Android Xbox device as an Xbox 360 Controller and
loaded the complete SDL mapping, including `a`, `b`, `x`, `y`, `leftshoulder`,
`rightshoulder`, and the D-pad. `dumpsys input` named Termux:X11 as the focused
window. The relay correction still needs a fresh device run before physical
button forwarding is accepted as a product gate.

Steam's client stdout still records Vulkan enumeration failure, but the same
run reached the signed-in UI through the deliberate software CEF path. This is
not evidence of hardware-accelerated Steam UI or game rendering.

The product stop command removed the runtime, but returned failure because the
Termux:X11 cleanup sub-gate failed; the subsequent exact runtime helper
returned `pass` and the residual process audit was empty. The next run will
retain the cleanup log before removing state so that sub-gate can be repaired
or explained rather than hidden.

### `launcher-20260809T200616Z-apk-v03-relay-fixed`

The relay-wrapper correction was installed as APK `d9288c9f7843c215441c074d51491e473b7b53453a1e4454adb4a576db766306`.
The wrapper now found and executed the binary inside the chroot; its result
changed from `No such file or directory` to the binary's own validation:

```text
uinput_error=invalid_timeout
```

That separated the path bug from the timeout contract. The launcher requests
86400000 ms for a long-lived session, while the relay binary had a 3600000 ms
maximum. The relay source now accepts the requested 24-hour bound and the APK
has been rebuilt as `9124807429ff6d21a3c7556865cf6a33b0c8999ac8673cc4b5629b46839b3ec1`.

This run also retained the Termux:X11 stop log. Its final client residual was
the cleanup verifier's own `awk` command, because `client_pids()` passed the
client token as an `awk -v` argument and did not exclude `awk`. The exact Nova
runtime cleanup still returned `pass` and the final matching process set was
empty. The cleanup verifier now excludes its own `awk` process; that change is
included in the pending APK above.

### `launcher-20260809T200927Z-apk-v03-relay-timeout-cleanup-fixed`

The timeout and cleanup fixes passed their launch gates. The APK created a
stable relay-backed virtual controller:

```text
nova_launcher_gamepad=pass
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_device=/dev/input/event9
uinput_device_ready=pass
nova_launcher_ready=pass display=:0 geometry=1280x960
```

Steam's fresh controller log opened both the physical Xbox device and the
virtual `Nova Virtual Xbox Controller`, with complete SDL mappings for ABXY,
LB/RB, triggers, sticks, and the D-pad. The controller trace hash is retained
in the run directory. This motivated the next refinement's attempt to hide
only physical event7 in the Steam client namespace while leaving the relay's
source node available; the follow-up result is recorded below.

The controlled source-event proof was end-to-end. Root sent a BTN_SOUTH/A
event to event7; event9 reported the corresponding gamepad down/up and the
visible Steam UI opened 198X. A BTN_EAST/B event returned to the home carousel.
The event9 trace also recorded `BTN_TL`, `BTN_TR`, and `BTN_DPAD_RIGHT`; the
right-D-pad screenshot visibly moved the carousel. These are kernel-level
`sendevent` controls, not a claim that a human hand-press was sampled, but they
prove the same physical-event node -> relay -> Steam path that the device
buttons use.

Fresh X11 captures again showed root 1280x960 and Steam Big Picture 1280x800;
the geometry decision is unchanged. The signed-in UI capture and the A/B/D-pad
screenshots are all under this run ID.

The one-click stop and Termux:X11 cleanup both returned `pass`. The immediate
runtime audit briefly showed a reparented relay process with basename
`nova-uinput-gamepad-relay`, which exited before the targeted exact stop. The
runtime cleanup matcher now includes that basename (plus the control-wrapper
basename), and the follow-up run below exercised that matcher.

### `launcher-20260809T201703Z-apk-v03-single-controller`

The committed single-controller refinement installed and started from the APK:

```text
nova_launcher_gamepad=pass
nova_launcher_input_hide=event7
x11_namespace_input=pass hidden_events=7
uinput_source=/dev/input/event7
uinput_device=/dev/input/event9
uinput_device_ready=pass
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The private mount namespace was real and shared by the Steam process. The fresh
Steam PID's mount table contained the private `/dev/input` tmpfs, and
`/proc/<steam-pid>/root/dev/input/event7` was absent. A controlled
`BTN_SOUTH` event sent to the physical source event7 still reached the relay
and opened the 198X detail page. The Android baseline and after-A screenshot
hashes are
`bb7393913f7cbc26ebb54c1135ded4bb4a9165160b549ee144eb30fd430aa2f1` and
`bd158c9fb26e1e504ad8afc1eb9073cfb571f818f3b97e0ec251a75ec5694bb7`.

This did not yet prove one controller at Steam's SDL boundary. The fresh
`controller.txt` entry at `20:18:00` still enumerated an Xbox 360 device
(`045e/028e`) and the Nova virtual device (`2022/3001`), both with complete
ABXY/LB/RB/D-pad mappings. The contemporaneous Steam file-descriptor audit
showed the Steam process holding event9 and event10, while event7 remained
absent from its namespace. Android logcat also showed `com.rp.mapping`
creating/owning additional `Microsoft X-Box 360 pad 0/1` nodes. After the
Nova relay stopped, event9 disappeared but event10 remained, confirming that
the remaining duplicate is an Android mapping-service concern rather than a
Nova relay process leak. The next namespace experiment must allowlist only the
current relay event instead of recreating every event node except event7.

Fresh X11 capture again found a 1280x960 root and a 1280x800 `Steam Big Picture
Mode` window. The captured Steam PPM hash is
`1178e1a3de7b857dccd36df3fcab6120e3a1d1dd5b18a56084d6cefaf5da65ab`; the
geometry and black bottom band are unchanged. The latest audio-manager entry
remains `Initialized system audio manager: default`, which is initialization
evidence only, not proof of an audible Android sink.

The APK product stop returned `nova_launcher_stop=pass`; its cleanup log and
the exact runtime verifier both returned `pass`. The launcher state directory,
X11 socket, and all matching Nova runtime processes were absent after teardown.
Two old bounded `getevent` probes were found by the final process audit and
were killed by their exact PIDs after their command lines were retained; this
is a diagnostic-harness cleanup gap, not a live Steam runtime residual.

### `launcher-20260809T202544Z-apk-v03-input-allowlist`

The relay-event allowlist refinement passed the one-controller namespace gate:

```text
nova_launcher_gamepad=pass
nova_launcher_input_allow=event9
x11_namespace_input=pass allowed_events=9 hidden_events=
uinput_source=/dev/input/event7
uinput_device=/dev/input/event9
uinput_device_ready=pass
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The fresh Steam process shared the private mount namespace and saw exactly one
node, `/dev/input/event9`; event7, event10, and the other host input nodes were
absent inside its root. Steam held only event9. The relay intentionally uses
the Xbox 360 identity (`045e:028e`) while retaining the descriptive device
name, so the fresh Steam controller log contained one Xbox-compatible mapping
with ABXY, LB/RB, triggers, sticks, and D-pad support. This is the desired
single logical controller; the earlier physical-plus-virtual log was caused by
exposing every node except event7.

The bounded source-event sequence reached event9 and produced the expected
Steam UI behavior: A opened 198X, B returned to the library, LB/RB produced
`BTN_TL`/`BTN_TR`, and D-pad-right moved the carousel to The Sims 2. The event9
trace hash is
`3bd5d4b9069c08a1f2cb34468b758e2cff1564bf2a6ac24c7f362482aa8c5537`, and the
settled Android screenshot hash is
`f64ecac509fa4b9c54bf477d17e0854254ec3d5984118f0b58ab49892f9505fe`.

X11 geometry remains the same: a 1280x960 root with a 1280x800 `Steam Big
Picture Mode` window. The settled Steam PPM hash is
`481b7098406be4f45c08206cb870ae9360f6580218ef52408fe1bea1f9afd8e2`.
The APK product stop returned `nova_launcher_stop=pass`, both exact cleanup
checks returned `pass`, and the launcher state/socket plus matching Nova
processes were absent after teardown. Host event10 remains a separate
`com.rp.mapping` virtual device after teardown, but it is not visible to this
Steam client namespace.

### `launcher-20260809T203314Z-apk-v03-native-window-size`

This geometry experiment used commit `dc83268cfc2da93c27c97afd237eb88d733691a4`
and APK SHA-256
`42696a39be946fcb6ea1fc510b0132af0fb8093b44176bf6bbb8f2414c3c3504`.
The direct Termux:X11 client retained `-fullscreen -fulldesktopres` and added
Steam's explicit `-w 1280 -h 960` arguments. The fresh inner-client log
recorded both requested dimensions and the final command line:

```text
client_width=1280
client_height=960
client_flags_final=/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu -fullscreen -fulldesktopres -w 1280 -h 960
client_started=pass
```

The arguments did not change the mapped X11 geometry. Fresh X11 capture found
root `0x511` at 1280x960 and Steam Big Picture window `0x2400035` at
1280x800, with the same 160-pixel black bottom band on the Android capture.
The X11 tree and settled Android screenshot hashes are
`fff86bb187d869ad55a56be7db45004dc5036c1928bbe0662681e274972634c5` and
`2d699f8d7e1c20f7aee41c598e15c6bd39e7cb4dfbb55bafdf13a95b70c099ba`.
This is a negative result for Steam's `-w/-h` flags under the current
fullscreen/full-desktop profile; the next geometry experiment should vary the
fullscreen/full-desktop or X11 display mode, not add more size aliases.
The default APK launch no longer passes these ineffective size flags; the
client wrapper still accepts them for a separately identified future test.

The one-controller namespace gate remained intact: the fresh Steam process saw
only `/proc/<steam-pid>/root/dev/input/event9`, Steam opened the current
045e/028e Xbox-compatible mapping at `20:34:13`, and the fresh source-event
probe reached event9. That probe used `sendevent` to inject code 304 into the
raw source event7; it is synthetic relay evidence, not proof that a human
press on the physical controller is producing an event on event7. The operator
reported that actual physical controls were not being forwarded, so physical
event capture is now the next input gate.

The direct root-side stop completed after the final exact cleanup retry:
`nova_launcher_stop=pass`, `nova_x11_cleanup=pass`, and
`nova_runtime_cleanup=pass`. The app state directory, X11 socket, capture
helper, and matching Nova processes were absent after teardown. The attempted
external `am startservice` stop was rejected because the service is not
exported; the subsequent exact launcher stop path was used for cleanup and is
not a product-session failure.

### `input-20260809T203930Z-physical-evdev`

After the geometry session was stopped, a bounded 20-second root capture of
`/dev/input/event7` recorded zero lines (empty-trace SHA-256
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`). The
device inventory still identified event7 as an enabled external gamepad named
`Xbox Wireless Controller`, with the expected ABXY, LB/RB, trigger, stick, and
D-pad capabilities. Its sysfs path is `/devices/virtual/input/input764`, so
this is a virtual output of Retroid's input mapper rather than a direct
physical transport node.

The contemporaneous device state reported `bluetooth_on=0`, and logcat showed
`com.rp.mapping` restarting its `rsinput` service, registering
`Retroid Pocket Controller`, reporting MCU frame-loss errors, and transitioning
the mapping configuration from `Gamepad` to `Empty`. This places the current
physical-control failure before the Nova relay and Steam namespace: the relay
can forward injected events, but the virtual source node was quiet during the
bounded physical capture. A fresh session must therefore capture all input
nodes while the operator presses the built-in controls and correlate those
events with the mapper's MCU log before changing Steam input code.

### `launcher-20260809T204121Z-apk-v04-physical-input`

This fresh direct-APK run used commit `ec69b2e4ff924eeda15542ce632d0a58a27ffe79`
and APK SHA-256
`398412c0f2c711ffcb3d11a86a8038daa7474660ef9cf58fce3b4a0660d661b2`.
The client started with the restored default command line (fullscreen and
full-desktop-resolution only), the relay reported source event7 and output
event9, and Steam opened one 045e/028e Xbox-compatible controller.

During the operator-directed 30-second synchronized capture, neither the
physical mapper source nor the relay output produced an event:

```text
---SOURCE_EVENT7---
---RELAY_EVENT9---
```

The combined trace hash is
`f62b2aed4fada12a9e1a9e900c16d37005981e913d9105ec6a280bf8e1eb4d78`.
The Steam UI remained live with 198X selected, so this is not a display or
Steam-readiness failure. It also means the earlier synthetic `sendevent`
success cannot be used as evidence that the Nova's physical buttons are
working. The mapper logs during this run showed additional event9/event10
creation/removal churn and the same `rsinput`/mapping-service behavior; the
relay itself remained ready throughout.

This moves the next input experiment below the Nova relay: inspect and restore
the Retroid `com.rp.mapping` gamepad profile/MCU path, including why Bluetooth
is off and why the mapper transitions to an empty configuration. Do not change
Steam's event mapping until a real event appears on event7.

### `input-20260809T205021Z-mapper-profile-inspection`

This was a read-only source and state inspection after the physical-input run.
The pulled system APKs were `RsMapping.apk` SHA-256
`1596ab70b2443a14bd7268cf9655be668d79e7a60e62d924ce844f000b37d0bc`,
`RPSettings.apk` SHA-256
`07c3627f180dbfb80099e49136de375a79d5c410fbf4124dc0de7f9921ba621f`, and
`GameAssistant.apk` SHA-256
`889e42a54eb3fe84739245d032be7174804cc5b3a79625cab5e9e5cd85bf2d22`.

The decompiled `RsMapping` application initializes `StandardGamepadConfig`,
but the live log then records `Gamepad->Empty`. The `GameAssistant`
`AppConfigService` selects a per-foreground-app config when `key_adapter_enable`
is enabled; if no app-specific config exists, it falls back to its global
default. The device's pulled `configs.db` contained only the built-in `empty`
configuration and `com.rp.gameassistant|empty` in `last_config` (DB SHA-256
`5c026f9357d912e25cb4639a35cfc7218a7dda45ad673f1258e45466d07ff742`). There
was no Steam profile to select.

The relevant firmware settings were absent from the settings table, so the
source defaults apply: `key_adapter_enable=true` and
`global_gamepad_to_mouse_mode=false`. `RsMapping` reported
`ro.mapping.state=3`, which is its `SERVICE_READY` state. This explains why
the virtual event7 node exists and has a complete Xbox capability descriptor
while no physical MCU event reaches it: the mapper is live but its active
configuration is empty. The `Gamepad->Empty` transition is therefore a
Retroid system-app configuration problem, not evidence of a Nova relay or
Steam namespace failure.

No device setting or mapper data was changed during this inspection. The next
bounded experiment must use one reversible source-side change at a time: first
test the Retroid screen/key-mapping configuration with the operator's current
settings recorded, then verify a real event7 trace before starting Nova. Do
not add more relay mappings or synthetic `sendevent` tests until that gate
passes.

### `input-20260809T210313Z-handle-takeover`

This bounded source-side experiment tested the Retroid setting that is
explicitly described as `New Controller Takeover Mode`. The setting is
implemented by `com.ro.settings.preference.input.HandleConnectionModePreference`
and writes `persist.sys.handle.mode`; it was `0` before the experiment and was
set to `1` through the vendor settings UI. The preference says that a restart
is required, so the Nova was not running and the device was rebooted before
the fresh capture. The post-reboot state was:

```text
persist.sys.handle.mode=1
persist.sys.gamepad.type=1
sys.boot_completed=1
bluetooth_on=0
key_adapter_enable=null
global_gamepad_to_mouse_mode=null
```

The mapper still exposed `/dev/input/event7` as the virtual `Xbox Wireless
Controller` and the `keydetect` kernel module was loaded. Its `/dev/adckey`
misc device existed, and boot `dmesg` included `driver: adckey_fasync` and
`adckey_write:start`. However, an operator-directed 12-second capture of
`/dev/input/event7` was empty (SHA-256
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`). A
simultaneous all-node capture contained only the nine `getevent` device
announcements and no key, axis, or touch events. The captured state,
capabilities, kernel log, logcat tail, and both traces are retained under the
ignored local artifact directory
`android/nova-lab/build/mapper-test/input-20260809T210313Z-handle-takeover/`;
the state and capability artifact hashes are
`967fd4c38c82cccb61fe2990d51874d3b93fadff87c3ec278259b506b4ad6e2a` and
`fc0dd837228ff7f6684c3567facf17c7b6d1ca0cce1c727fdb9ce1e5611047bc`.

The prior reversible Game Assistant drawer test was also negative: opening
the vendor overlay and closing it with Back did not produce a
`Gamepad->Standard` transition in the mapper log; the live configuration
remained empty. This rules out the simple UI lifecycle reset as a reliable
fix. The physical-control failure is therefore still below the Nova relay and
Steam: the current device image has a live virtual gamepad endpoint but no
observed physical source event. Do not claim controller support or add more
Steam-side mappings until the `keydetect`/MCU or Retroid takeover path emits a
real input event.

### `launcher-20260809T210746Z-apk-v04-shm-after-reboot`

After the device reboot required by the takeover experiment, the existing
installed APK (`398412c0f2c711ffcb3d11a86a8038daa7474660ef9cf58fce3b4a0660d661b2`)
was launched from the product UI. The relay still reached
`nova_launcher_gamepad=pass` with output `event9`, and Termux:X11 reached a
fresh 1280x960 surface, but the Steam client exited before starting. Its fresh
client log recorded:

```text
mount_private=pass path=/
mount: 'tmpfs'->'/data/local/tmp/nova-holo-rootfs/dev/shm': No such file or directory
x11_namespace_error=mount_shm
```

The failure is caused by the private namespace helper binding Android
`/dev` over the rootfs `dev` directory before mounting shared memory. Android
`/dev/shm` is absent, so the bind hides the rootfs target and the mount
silently becomes a missing-target failure after reboot. The first automatic
stop caught a server-parent exit race (`nova_x11_cleanup=fail`); pressing the
product stop button immediately repeated the exact cleanup and returned
`nova_x11_cleanup=pass`, with no matching runtime process left behind.
Fresh failed-run artifacts are retained locally under
`android/nova-lab/build/mapper-test/input-20260809T210313Z-handle-takeover/nova-run-failed/`;
the client, relay, server, and activity log hashes are
`a778d3dbdc6bc19d512c9181097446cd43780ff02e84334c19caef5714518f4c`,
`3f0de19e55830f8bf026ffa971122158eee6e12d1254e71d2ffc0257fd9ab85c`,
`a1f9fcf219238ec5e82d75fdc67615b169f4266c10b75d4f9f1453051f650df7`, and
`b8d2b40f621cebe988c6724c3e4d6a83233ba3a3ec98dc5da5ac02b0384207a9`.

The helper now creates the missing target only after the `/dev` bind and
removes that directory during namespace cleanup. The rebuilt APK containing
this fix is `45bc0dc0dce83141b21b6d386c1c8ac43e34448b90a824d833126dbc345c348f`;
it has not yet been installed or accepted on the Nova.

### `input-20260809T213206Z-native-source-audit`

This source-side follow-up left the signed-in Steam runtime alive and opened
the vendor `com.ro.gameassistant/com.ro.gameassistant.activity.GamepadTestActivity`.
The fresh 30-second `getevent -lt` capture enumerated the eleven input nodes,
including event7 (`Xbox Wireless Controller`), but contained no key, axis, or
switch event (739 bytes; SHA-256
`1628d7aeb61319aa4ead2bdaed9583e5cb2f6a9ba2667fc4e98360ac63ae8da3`). The
vendor Key Test remained at `Device ID: 0`, an empty device name, and zeroed
axes before and after the capture. This is an independent confirmation that
the physical-input gap is below the Nova relay and below Steam.

The device-side source inventory identified a more specific vendor-path
failure to investigate:

```text
persist.sys.handle.mode=1
persist.sys.gamepad.type=1
persist.sys.mcu.checkerrs=2
/dev/adckey                         present (misc 10:122)
/dev/rscom                          present (499:1)
/dev/ttyHS1                         absent
ttyHS1 sysfs device                 present as 499:1
/sys/class/hwmon                     empty
/sys/devices/platform/rsgpio/driver_ctl=unsupported
keydetect kernel module              loaded
```

The native `librsinput.so` contains the Nova/U3 ADC paths
`/sys/class/hwmon/hwmon1/device/gpio{8,9,10,11,12,21}_adc*`, but none of those
paths exists on the live device. The MCU UART's sysfs device exists, while
`/dev/ttyHS1` does not; boot audit records show `pservice` attempting to remove
or rename `ttyHS1` and the mapping process opening `/dev/rscom` instead. The
fresh dmesg also records `rs_gpio_request()` failures with `-517` for GPIOs
302, 301, 400, and 313, and the active/suspend `gamepad_gpio_key` pinctrl
states each contain three literal `nouse` groups. The pinctrl driver reports
each `nouse` group as invalid. These are source-path facts, not yet a proven
hardware fault, but they explain why another relay mapping would be premature.

As a reversible vendor-only reinitialization, root launched
`com.ro.settings/com.ro.settings.activity.InputControlActivity`, whose
`onCreate` calls the vendor `K1.b.b()` standard-input setup. The activity
opened successfully, but native logcat only recorded another
`gamepad_config_create` / `parse_config ... deconfig success` sequence. A
fresh copy of `configs.db` still contains only the built-in `empty` row and
`com.rp.gameassistant|empty` in `last_config` (SHA-256
`5c026f9357d912e25cb4639a35cfc7218a7dda45ad673f1258e45466d07ff742`). The
reinitialization therefore did not establish a non-empty active mapper
profile, and no real event7 event appeared afterward.

Retained artifacts are under the ignored
`android/nova-lab/build/mapper-test/input-20260809T210313Z-handle-takeover/`
directory. The Key Test capture, reinitialization screenshot, post-reinit
database, focused logcat, and current dmesg hashes are recorded in the local
artifact inventory. The next experiment should select or import a known
non-empty vendor `StandardGamepadConfig`/Xbox profile through the vendor
API/UI, then repeat the same physical-event gate. If that profile still
produces no event, the remaining blocker is the MCU/ADC/pinctrl path rather
than the profile database or Steam integration.

### `input-20260809T214900Z-profile-api-raw`

This follow-up tested the vendor's exported `com.ro.mapping.service.ApiService`
directly with a disposable Android binder probe. The probe serialized the
decompiled built-in `XboxGamepadConfig`, invoked the vendor
`setGamepadConfig(GamepadConfig)` transaction, and kept both the mapping binder
and the probe Activity in the foreground while the operator pressed the
physical controls. The probe APK SHA-256 was
`6352ef463e0e04dd3257cc18c5d8ced34b1a81d07b7ec0685e14035f5e42b1f2`.

The vendor service accepted the profile and logcat recorded
`Config changed: Empty->XBox Gamepad` followed by a successful native
`parse_config` call. Releasing the probe later caused the vendor mapper to
revert to `Empty`; the call is therefore a live service operation, not a
persistent profile selection. It is not a suitable launcher fix by itself.

While the profile was held, a fresh 30-second all-node `getevent -lt` capture
still contained only the eleven device-announcement lines (739 bytes; SHA-256
`1628d7aeb61319aa4ead2bdaed9583e5cb2f6a9ba2667fc4e98360ac63ae8da3`). No key,
axis, switch, event7, or mapper event9 records appeared. The vendor binder's
`currentRawEvent()` was also sampled 60 times at 250 ms intervals. Every
sample was identical:

```text
[-31.0, 0.0, -18.0, -7.0, 1527.0, 1501.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
```

The raw-state log SHA-256 is
`938682377312f92ae03a51f521722c99a9fb3ab9f0c74ffc813f139155c4f6c4`; the
focused device state was still `persist.sys.handle.mode=1`,
`persist.sys.gamepad.type=1`, and `persist.sys.mcu.checkerrs=2`. The input
reader continued to list event7 as the virtual `Xbox Wireless Controller`
and event9 as `Nova Virtual Xbox Controller`, with no physical evdev source.

This rules out the empty profile as the immediate cause of the physical-control
failure. The controls are not reaching the vendor mapper's raw state, so the
remaining blocker is the Retroid MCU/ADC/UART/GPIO source path. The signed-in
Steam runtime was returned to the foreground afterward; the restored
1280x800 capture is retained with SHA-256
`2a26476c6f0cfc006069450343a5192b59bc67253ba9fa443aa441183694497b`.
The full run artifacts are under the ignored
`android/nova-lab/build/mapper-test/input-20260809T214900Z-profile-api-raw/`
directory.

The next controlled experiment should compare the vendor's original
`persist.sys.handle.mode=0` path with mode 1 across a documented reboot, or
exercise the native MCU initialization path directly. Do not add the binder
profile probe to the product launcher and do not spend more time on Steam-side
mapping until a physical press changes either the raw state or an evdev node.

### `input-20260809T220000Z-cleanup-fix`

Before the next mode comparison, a teardown audit found that the prior helper
could report `pass` after killing only the relay. The launch wrappers carried
`/data/local/tmp/nova-holo-rootfs` as an argument, while the chrooted Steam
children exposed only `/opt/nova-steam`; the matcher therefore failed to seed
the descendant walk with the launcher tree. The old helper SHA-256 was
`1ef0af366747d932639bfeeee67d117dde0b35317d522e2fdadd243eef1cc783`.

Commit `6ef295d` now matches the exact requested rootfs path as well as the
chrooted Nova paths. The pushed device helper SHA-256 is
`12332bc7e8d9401dfbe9ce72c5aba8feb910c1574a0e28602817bf92da34fb97`.
The corrected run enumerated the full launcher, Termux:X11, private namespace,
Steam, and webhelper tree. Its first three TERM/KILL cycles returned a visible
`fail` while those processes were still in ordinary sleeping states; an
immediate exact-scope rerun then returned:

```text
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=2 remaining=
```

The post-rerun process audit contained no matching Nova runtime process. This
is an exit-timing race, not permission to broaden the kill scope; the helper
must remain a hard gate and a failed first stop must be retried explicitly.
Artifacts are retained under the ignored
`android/nova-lab/build/mapper-test/input-20260809T220000Z-cleanup-fix/`
directory. The rerun cleanup and post-rerun process-table hashes are
`23fc591f7dc83a4d368136b43e2e76444bae4536ecf827f468076949999580a7` and
`e78059fc5feafa6c287017b47e52961cda94baebf70d920e8bd71ec0c5bcb000`.

No new physical-control sample was taken in this run because the operator was
away and no buttons were pressed. The preceding no-input raw-state and
all-node event captures remain the valid physical-source evidence.

### `input-20260809T220043Z-handle-mode-0`

This controlled reboot compared the vendor's original handle mode with the
mode used by the product path. Before reboot, the exact Nova runtime cleanup
had passed and the test APK and Termux:X11 were force-stopped. The device
property was changed from `persist.sys.handle.mode=1` to `0`, then the Nova
was rebooted as required by the vendor preference implementation.

After boot, the property remained `0`, but the input topology did not change:
Android still exposed the virtual `Xbox Wireless Controller` as `/dev/input/event7`
and the `Retroid Pocket Virtual Mouse` as `/dev/input/event8`; no physical
controller node appeared. The vendor nodes remained `/dev/adckey` and
`/dev/rsinput`, while `/dev/rscom` existed as the MCU UART endpoint and
`/dev/ttyHS1` remained absent. `persist.sys.mcu.checkerrs` remained `2`.

A fresh no-input 30-second all-node `getevent -lt` capture contained only
nine device-announcement records and no key, axis, switch, event7, or mapper
event9 records (589 bytes; SHA-256
`143a2cad0b27ebd59b2479475d1ad6adcb91fd575409fa65f7227598901a228d`). The
post-boot state, input topology, and input-reader inventory hashes are
`805d2d4715080834d88e0da261856b0770b1bc88a170d099b524b6612eab5bf7`,
`30af81e4238be149c53f1a009eca32263dc3f74b3ba5aeb6645e3942fe90be3f`, and
`d991f9e8e20855942c20eff565600983a23ddbbfb2f122d843b044f7c21d6121`.

The vendor Gamepad Test launch could not be used as a UI result because the
device remained at the Android lock screen and no physical or synthetic
unlock input was supplied. Its capture is retained only as context (SHA-256
`a9e177041fbc9614694997f435fca7e13f35c14fb14d4611edd36b071b65f0e9`). No
physical controls were pressed during this run. Mode 0 therefore does not
unblock the source path; restore mode 1 and investigate the native MCU/ADC/
UART/GPIO initialization rather than changing Steam or relay mappings.

Artifacts are retained under the ignored
`android/nova-lab/build/mapper-test/input-20260809T220043Z-handle-mode-0/`
directory.

The product baseline was restored in a separate reboot immediately afterward:
`persist.sys.handle.mode=1`, `persist.sys.gamepad.type=1`, and
`persist.sys.mcu.checkerrs=2` persisted after boot. The restoration state,
input topology, and input-reader inventory hashes are
`0032ce09e40bd54547a7fcacab79edd1199ff161a34f7abe1fa26f73e6d4a5be`,
`2feb78b279fae870dfd7fd71924b380124a71510e2f86b39f6aa6446074957b5`, and
`b24071cd4032e3f22ce4b30d9df1fd24835882d4a199f219c9513a1a6dc546a7` under
`android/nova-lab/build/mapper-test/input-20260809T220410Z-restore-mode-1/`.
No Nova Steam runtime was relaunched during either mode run.

## Cleanup

Every attempt ended without a Nova Steam runtime. The exact helper returned
the following on the latest completed run:

```text
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

The APK and Termux:X11 were force-stopped, `/data/local/tmp/nova-android-launcher`
was removed as app-owned state, and the post-cleanup process audit found no
matching runtime. No broad process kill was used.

## Next gate

The direct APK path is now repeatable through signed-in Steam UI and the
single-controller namespace gate is accepted, but physical-controller
forwarding is not yet accepted. The next run should focus on the remaining
product boundaries, in order:

1. inspect the Retroid `keydetect`/`/dev/adckey` and MCU source path, including
   the effect of `persist.sys.handle.mode=1`, and require a real physical
   event before re-running the relay gate;
2. test and fix the 1280x800 Steam window geometry against the 1280x960 Nova
   surface;
3. establish whether the `default` Steam audio manager reaches an Android
   sink;
4. preserve the direct APK fallback while adding a separately identified
   Gamescope/AHardwareBuffer product mode; and
5. keep 198X/game launch as a separate translation-runtime phase because its
   current blocker is x86-64 execution, not display or controller input.

Only after that direct product path is repeatable should the APK gain the
separate Gamescope/AHardwareBuffer product mode.
