# AYN Thor rooted known-good path — OOBE comparison result — 2026-08-11

Run ID: `thor-rooted-known-good-oobe-compare-20260811T184500Z`.

Status: complete as a manual rooted comparator, not an Rxx one-variable A/B.
The run was requested after the Thor rootless stable-payload replay to answer
whether the `vgui2_s` failure was an inherent rootless limitation.

## Result

The rooted APK path booted Steam through the public client updater, initialized
SteamUI and webhelper, crossed Steam OOBE language, timezone, and network
selection, recovered from Steam's normal “Shutting down Steam…” transition,
and reached the QR sign-in screen.

The rooted path therefore proves:

- the device can display the current Steam Gamepad UI through the direct X11
  path;
- the native `vgui2_s`/SteamUI boundary is loadable in the rooted profile; and
- the network-selection shutdown is a later recoverable OOBE transition, not
  the native SteamUI loader failure.

It does **not** prove that all rootless prerequisites are solved. The rooted
profile changed several contracts together: private mount/chroot, root-side
`/dev` and `/proc` setup, tmpfs `/dev/shm`, D-Bus, software CEF/GL controls,
preloads, input relay, UID/GID setup, and the updater lifecycle.

## Rooted launch evidence

Device: AYN Thor, serial `d234a848`, model `AYN Thor`, `kalama`, Android API
33, `arm64-v8a`. Repository start HEAD was `b17b0ab29038942241f17190863bad26426e893e`;
the sibling `/Users/kurt/Developer/steamclienttermux` was clean at
`8d14c10195b34fe2714ba59df1680df27a852532`.

The APK's normal rooted launch profile recorded:

```text
NOVA_ANDROID_LAUNCHER_HARDWARE_ACCEL=1
NOVA_ANDROID_LAUNCHER_CEF_DISABLE_GPU=1
NOVA_ANDROID_LAUNCHER_STEAM_UI_MODE=gamepadui
NOVA_ANDROID_LAUNCHER_STEAM_DISABLE_PRELOAD=0
NOVA_ANDROID_LAUNCHER_STEAM_DISABLE_SYSTEM_DBUS=0
NOVA_ANDROID_LAUNCHER_STEAM_HOLO_MESA_FIRST=0
NOVA_ANDROID_LAUNCHER_STEAM_FORCE_SOFTWARE_GL=1
NOVA_ANDROID_LAUNCHER_STEAM_CEF_ENV_SPLIT=1
NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE=1
NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE_PORT=29100
DISPLAY=:0
```

The rooted client wrapper then used SteamRT-first libraries, software GL
variables (`swrast`, `softpipe`, `LIBGL_ALWAYS_SOFTWARE=1`), and these
preloads:

```text
/opt/nova-kgsl-driver/libnova-alsa-audiotrack-bridge.so
/opt/nova-kgsl-driver/libsysv-sem-shim.so
/opt/nova-kgsl-driver/libnova-cef-env-split.so
```

It started a private session bus and a root-side system bus, mounted a fresh
tmpfs at guest `/dev/shm`, and used the rooted private X11 namespace and
controller relay. The Linux Steam identity was uid `501`, gid `20`, with audio
gid `1005`.

The initial command included the rooted-only display/update flags:

```text
steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu -fullscreen -fulldesktopres
```

Unlike the rootless stable replay, the rooted profile allowed normal bootstrap
and update behavior. The updater reached:

```text
Downloading update (657758 of 657758 KB)...
Download Complete.
Extracting package...
Installing update...
Cleaning up...
Update complete, launching...
```

The wrapper then recorded `client_bootstrap_handoff=1`,
`client_steamui_present_after_bootstrap=1`, `steam_network_compat=pass`, and
restarted Steam with `-nobootstrapperupdate -skipinitialbootstrap
-no-child-update-ui`. The post-update selected public client hashes were:

```text
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
```

The first three hashes exactly match the R28/rooted public-beta client, not
the stable payload used by doc 485. This is the strongest current evidence
that the doc 485 `vgui2_s` result is payload/channel-specific or a payload plus
rootless loader interaction, rather than a simple “rootless cannot load
SteamUI” rule.

## OOBE sequence

Fresh screen captures were 1920x1080 and remain outside the repository in
`/tmp/thor-rooted-compare-20260811T184500Z-evidence/`. Non-sensitive captures
include:

```text
rooted-8s.png
  sha256=8db59492a9ada07ac334667f3204caf698ad3d53d24e45a968a60457233267f2
  visible=Steam updater modal at 51529 of 65758 KB
rooted-now.png
  sha256=831d076e8aa4ad8acde597ed808ff458d35cc9464c522ae8625af7f8a02b1e10
  visible=Steam OOBE language selection
rooted-oobe-after-english.png
  sha256=a999019909612afadefc09ed2dc6891b0611316390f1ba6cf0be5403eb99271a
  visible=timezone selection
rooted-oobe-after-timezone.png
  sha256=cb028a0997c8401e7353c132ddb65079fceb63364a35e9041944f6421263a84c
  visible=“Choose your network” with Android host network selected
rooted-oobe-after-network.png
  sha256=d78ebacd4f3ef4010f770cc2137ae82255bacfd8a941a6891e372959c5e23a6a
  visible=Steam “Shutting down Steam…” transition
rooted-oobe-shutdown-followup.png
  sha256=2bec5ab087f941bef49f40c8c8f823053174a6655a4cf0d846c2883d6fd51d51
  visible=controller/network setup screen after automatic restart
```

Selecting the already highlighted English, timezone, and “Continue with
Android host network” entries used only targeted ADB key events. After the
network transition, the rooted launcher restarted Steam and the controller
setup screen advanced to the QR sign-in screen. A QR screenshot was captured
only long enough to verify the screen, then deleted immediately; it is not
retained, committed, or exported.

## Cleanup and rollback

The rooted launcher's own scoped `stop` path returned
`nova_launcher_stop=pass`, restored the Termux:X11 preference change, and
reported `nova_launcher_dbus_state=absent`. The APK and Termux:X11 were then
force-stopped. No matching Nova Steam, webhelper, X11, D-Bus, controller-relay,
or TCP 6077 process/listener remained. The preserved paths were verified:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Post-cleanup free space was `21490484 KiB` on the reported device filesystem.
The rooted runtime was not deleted or reset.

No Steam authentication secret, QR/session state, cookie, token contents, or
authenticated home was read, copied, backed up, or exported.

## Comparison conclusion

The two results should be read as a matrix, not as a single root-versus-
rootless switch:

| Path | Client bytes | Root-only services | First boundary |
|---|---|---|---|
| Rootless doc 485 | stable endpoint `72f/25ad/705f` | absent by contract | `vgui2_s` loader fatal |
| Rootless R28 | sanitized public-beta `6d/69/aba` | absent by contract | SteamUI/webhelper; later Vulkan, `/dev/shm`, D-Bus |
| Rooted comparator | sanitized public-beta `6d/69/aba` | present | OOBE and QR sign-in |

The next experiment must first restore the exact R28 client bytes in rootless
with doc 485's other variables fixed. Only if that baseline crosses `vgui2_s`
should the predeclared `VK_DRIVER_FILES` R31 selector be resumed.
