# Nova Termux:X11 hardware Steam system-D-Bus isolation experiment — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The hardware Termux:X11 display boundary passes, while Steam’s ARM64 client
still exits before a frame under CEF-enabled, CEF-disabled, and minimal
Steam-UI flag profiles. The no-preload split established that the System V
semaphore shim is required; the normal hardware profile therefore retains it.
The remaining direct-client setup starts both a synthetic rootfs system bus
and a private Steam session bus. This run disables only the synthetic system
bus while retaining the session bus, display path, Steam flags, CEF setting,
network compatibility patch, and semaphore shim.

This is an opt-in launcher extra. The default launcher continues to start both
buses, and the software profile is unchanged.

## Source and artifact

Build and push the source change before installing or launching the device.
Record the final source commit, host APK SHA-256, and matching device APK
SHA-256 in the result. The intended launch extras are:

```text
--ez run_steam_session true
--ez hardware_accel true
--ez cef_disable_gpu true
--es steam_ui_mode minimal
--ez steam_disable_preload false
--ez steam_disable_system_dbus true
```

The launcher must log `nova_launcher_steam_disable_system_dbus=1`, and the
client must log `client_dbus_system_mode=0` while retaining
`client_dbus_session_mode=1` and `client_dbus_session_status=pass`.

## Fixed run profile

```text
device=Retroid Pocket Nova
adb_serial=675a2365
rootfs=/data/local/tmp/nova-holo-rootfs
display=:0
presentation=Termux:X11 Android SurfaceView
target_geometry=1280x960
hardware_accel=true
vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
cef_disable_gpu=true
steam_ui_mode=minimal
steam_disable_preload=false
steam_disable_system_dbus=true
dbus_session=enabled
dbus_system=disabled
audio_bridge=false
gamescope=not_used
game_launch=not_attempted
input_action=none
```

Read `docs/00-start-here/34-nova-runtime-harness-lifecycle.md` immediately before launch.
Use a fresh launcher state, fresh Steam logs, and a same-run screenshot. Run
the exact X11 and rootfs cleanup helpers before launch and after evidence
capture. Do not reuse a prior status-139 log, screenshot, or readiness token.

## Acceptance and interpretation

Acceptance requires the selected hardware/ICD/CEF/UI/preload markers,
`client_started=pass`, and retained client stderr/minidump output if Steam
crashes. A stable Steam frame is required before any game, input, audio, or
network claim can be attributed to this run. Preserve independent Termux:X11
EGL/XCB/shared-buffer evidence even if Steam exits early.

* If Steam reaches a stable frame or changes its crash boundary, record that
  as evidence that the synthetic system bus participates in startup. Follow
  with a separately declared service/network interpretation; do not call the
  empty system bus a finished NetworkManager implementation.
* If the client reports an expected missing system-bus or `NMClient` boundary
  but remains alive, this isolates the system-bus dependency from the later
  hardware crash.
* If it reaches the same status-139 boundary, the system bus is not the sole
  cause; move to Steam runtime library selection or another single startup
  layer.

No game title should be launched from a run without a fresh stable Steam
frame. Commit and push this predeclaration before installing the APK or
launching the device session.

## Result

Status: completed; disabling the synthetic system bus did not change the
hardware Steam startup crash.

The source commit was `086cc8f`. The rebuilt APK SHA-256 was
`ea62c640e79590b74db0a0b66b26f05adb6b5d5f80f98873869a6a73e4a1705b`, and
the installed device APK reported the same hash. The valid run ID was
`steam-20260810T055632Z-hardware-system-dbus-off`.

The fresh launcher selected the intended profile:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_cef_disable_gpu=1
nova_launcher_steam_ui_mode=minimal
nova_launcher_steam_disable_preload=0
nova_launcher_steam_disable_system_dbus=1
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The client retained the semaphore shim and disabled only the system bus:

```text
client_disable_preload=0
client_preload=/opt/nova-kgsl-driver/libsysv-sem-shim.so
client_dbus_system_mode=0
client_dbus_system=disabled
client_dbus_session_mode=1
client_dbus_session=enabled
client_dbus_session_status=pass
client_dbus_session_client_probe=pass
client_flags_final=... -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu -fullscreen -fulldesktopres
client_started=pass
client_status=139
```

Steam still segfaulted before a usable frame. Fresh stderr reported CrashID
`bp-97e7ea4d-c412-4a9a-90c7-af82f2260809`; the matching device minidump was
pulled before teardown. The same-run screenshot shows the Nova launcher with
exit status `143`, not Steam UI. No game, input, audio, or network result is
attributable to this run.

The display boundary remained independently healthy: Termux:X11 loaded the
Android Adreno EGL driver `0676.53`, initialized EGL 1.5, completed XCB
connection setup, exchanged 1280x1024 and 1280x960 shared buffers, and
continued reporting fresh shared-buffer frames while Steam exited. This
matches the prior hardware runs and isolates the unchanged failure below the
system-D-Bus choice. The private session bus remains a viable compatibility
boundary, but it is not sufficient to keep this Steam client alive.

Fresh artifacts are retained at
`/tmp/steam-20260810T055632Z-hardware-system-dbus-off/`:

| Artifact | SHA-256 |
| --- | --- |
| `launcher.log` | `685d97254573c144153e367c8dc021646bd9c3ce9c6ca4e209add3a75eff56e9` |
| `client.log` | `01dc3568a4a62afc55b61b9857c76160476aa5d9a2d2165ab7511bd3f6aabb0d` |
| `client-runtime.log` | `f86ccb8ab667a1269a933be0ea8958724dfce635c94bd920e0ecb33ac505b344` |
| `client-stdout.log` | `e7a3de096b981f2fadf271a67881392867aa0bcceffb3e9f701aecbcf8c376fa` |
| `client-stderr.log` | `e868cdbb410f79bc34d01b10fe57826fa4fc35690208be31add5737ff8a9a3b0` |
| `server.log` | `7610b30a564bab991100ed422556fe89e2dc8003b72e6622647e1afd66a0b319` |
| `screen-00.png` | `294c8ea1524e5ba28b65293df3a0a8f6979d9e3ebb2615368c9d8bfa3f2979f5` |
| `logcat.txt` | `7f9595240d3b5e3d56119df7b4da5e8628567d30ce8593dc2e458c136c0373a0` |
| `device-crash_20260810055722_3.dmp` | `f83cc87672da7f580178313600cb74e29142f0bf21c51eff7efa641eb6b3726b` |
| `cleanup.log` | `9b6e91b55629b83b9fa135e34b45d705812edf35577ee88caed9d151f142fc02` |
| `runtime-cleanup.log` | `1bb8add9bfa2a0ad115fa08807f1927364b44300ae706823e12964cc74539be8` |

The exact X11 and runtime cleanup helpers returned `pass`. Final checks found
no matching Steam, Xwayland, Termux:X11, D-Bus, Gamescope, rootfs-specific
process, X11 socket, mount, or device dump. The final rootfs filesystem
reported `80,041,964 KiB` available.

This closes the system-D-Bus split. The next hardware experiment should move
to Steam runtime library selection or another single binary-startup layer;
adding more compositor patches is not justified by this result. The known
software UI path and the retained semaphore shim remain the controls.
