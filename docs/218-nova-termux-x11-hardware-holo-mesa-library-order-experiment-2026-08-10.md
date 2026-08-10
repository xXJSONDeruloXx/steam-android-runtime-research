# Nova Termux:X11 hardware Holo Mesa library-order experiment — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The hardware Termux:X11 boundary passes, but the direct ARM64 Steam client
still segfaults before drawing. CEF, SteamOS/GamepadUI flags, semaphore
preload, and synthetic system-D-Bus setup have now been isolated without
changing that boundary. The direct client currently puts SteamRT's
`libEGL_mesa`, `libGL`, `libGLX`, and `libgbm` directory ahead of Holo's
`/usr/lib`. The older Gamescope launcher documents the opposite ordering as a
requirement: Holo Mesa must precede SteamRT Mesa to avoid a GLX null-backend
failure when Holo's KGSL stack is used.

This run enables only an opt-in Holo-first library ordering. It keeps the
hardware profile, explicit Freedreno ICD, CEF-disabled setting, minimal Steam
flags, semaphore shim, private session bus, disabled synthetic system bus,
network compatibility patch, and presentation path unchanged. The normal
launcher default remains SteamRT-first.

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
--ez steam_holo_mesa_first true
```

The launcher must log `nova_launcher_steam_holo_mesa_first=1`, and the client
must log `client_holo_mesa_first=1` and
`client_library_order=holo-mesa-first`. The device asset should contain the
same source marker before launch.

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
steam_holo_mesa_first=true
dbus_session=enabled
dbus_system=disabled
gamescope=not_used
game_launch=not_attempted
input_action=none
audio_bridge=false
```

Read `docs/34-nova-runtime-harness-lifecycle.md` immediately before launch.
Use a fresh launcher state, fresh Steam logs, and a same-run screenshot. Run
the exact X11 and rootfs cleanup helpers before launch and after evidence
capture. Do not reuse a prior status-139 log or screenshot as acceptance.

## Acceptance and interpretation

Acceptance requires the selected hardware/ICD/CEF/UI/preload/D-Bus/library
markers, `client_started=pass`, and retained client stderr/minidump output if
Steam crashes. A stable Steam frame is required before any game, input, audio,
or network claim can be attributed to this run. Preserve independent
Termux:X11 EGL/XCB/shared-buffer evidence even if Steam exits early.

* If Steam reaches a stable frame or changes the crash boundary, retain this
  as evidence that the direct client was selecting an incompatible Mesa/GL
  closure. Follow with a narrow runtime dependency audit before making
  Holo-first the default.
* If the client fails with a missing symbol or loader error, record that as a
  library-ordering incompatibility rather than adding more preload shims.
* If it reaches the same status-139 boundary, this documented ordering is not
  sufficient; move to another single Steam runtime/binary startup variable.

No game title should be launched from a run without a fresh stable Steam
frame. Commit and push this predeclaration before installing the APK or
launching the device session.

## Result

Status: completed; putting Holo's `/usr/lib` ahead of SteamRT did not change
the hardware Steam startup crash.

The source commit was `a09eb20`. The rebuilt APK SHA-256 was
`c82f1d3b49db16313f85e69bdf72db8247e6252b5f79cdd96204d0616f572509`, and
the installed device APK reported the same hash. The valid run ID was
`steam-20260810T060113Z-hardware-holo-mesa-first`.

The launcher and client both confirmed the opt-in ordering while retaining
the other controlled values:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_cef_disable_gpu=1
nova_launcher_steam_ui_mode=minimal
nova_launcher_steam_disable_preload=0
nova_launcher_steam_disable_system_dbus=1
nova_launcher_steam_holo_mesa_first=1
nova_launcher_ready=pass display=:0 geometry=1280x960
client_hardware_accel=1
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_holo_mesa_first=1
client_library_order=holo-mesa-first
client_preload=/opt/nova-kgsl-driver/libsysv-sem-shim.so
client_dbus_session_status=pass
client_flags_final=... -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu -fullscreen -fulldesktopres
client_started=pass
client_status=139
```

Steam still segfaulted before a usable frame. Fresh stderr reported CrashID
`bp-ec6dc845-7032-4392-b0d0-6ff402260809`; the matching device minidump was
pulled before cleanup. The same-run screenshot is the Nova launcher with exit
status `143`, not Steam UI. No game, input, audio, or network result is
attributable to this run.

The display boundary remained independently healthy: Termux:X11 loaded the
Android Adreno EGL driver `0676.53`, initialized EGL 1.5, completed XCB
connection setup, exchanged 1280x1024 and 1280x960 shared buffers, and
continued receiving fresh buffers while Steam exited. Holo-first ordering
therefore does not resolve the direct ARM64 client crash and is not promoted
to the default.

Fresh artifacts are retained at
`/tmp/steam-20260810T060113Z-hardware-holo-mesa-first/`:

| Artifact | SHA-256 |
| --- | --- |
| `launcher.log` | `50bf14898531e19fb3f17cefffb061a65e87c485e8f0d5707f571a42ed3ff628` |
| `client.log` | `93443700b8cd97555b73c63580a8eb09ac412686373e3af96ebc384d2093852c` |
| `client-runtime.log` | `83d670fee89558e7c77128e74d692b27b142f55cb09557364c45ad8da6e1b63d` |
| `client-stdout.log` | `e7a3de096b981f2fadf271a67881392867aa0bcceffb3e9f701aecbcf8c376fa` |
| `client-stderr.log` | `f4b55a7f4643b2665129d19bdf01357eb7f63f60b457662ac8e96e4985733fa5` |
| `server.log` | `fee02a9bceb6bfd8fbbe22ef5262d941dc3c16c229c1dc909588db43c9ec5ad7` |
| `screen-00.png` | `294c8ea1524e5ba28b65293df3a0a8f6979d9e3ebb2615368c9d8bfa3f2979f5` |
| `logcat.txt` | `07a9126bfe8d09369e6e4a37d114e3e485bdb7eca32563ccbf3f1951831fcc63` |
| `device-crash_20260810060146_3.dmp` | `ac61e0ac2d7cf98f89f0b4dba440625fb007c056712c562f36c369ccf3925b01` |
| `cleanup.log` | `9b6e91b55629b83b9fa135e34b45d705812edf35577ee88caed9d151f142fc02` |
| `runtime-cleanup.log` | `1bb8add9bfa2a0ad115fa08807f1927364b44300ae706823e12964cc74539be8` |

The exact X11 and runtime cleanup helpers returned `pass`. Final checks found
no matching Steam, Xwayland, Termux:X11, D-Bus, Gamescope, rootfs-specific
process, X11 socket, mount, or device dump. The final rootfs filesystem
reported `80,062,512 KiB` available.

This closes the Holo-first ordering split. The accumulated hardware evidence
now points below the display transport and these launcher-level variables;
the next useful work should be a separate Steam binary/runtime investigation
or productizing the already-working software UI route, not another compositor
patch or game launch from a non-rendering hardware run.

## Post-run minidump analysis

LLDB can read the retained ARM64 Breakpad minidumps directly. The crashing
thread in both the system-D-Bus-off control and this Holo-first run has the
same native shape:

```text
frame 0  0x0                              SIGSEGV
frames 1-8  libgallium-25.2.7-arch1.1.so
frames 9-10 libGLX_mesa.so.0.0.0
frames 11-13 libGLX.so.0.0.0
frames 14-17 steam
```

Both dumps also retain worker threads in `libgallium-25.2.7-arch1.1.so` and
`libvulkan_freedreno.so`. The matching LLDB outputs are retained as
`lldb-backtrace.txt` in each run directory:

| Run | LLDB backtrace SHA-256 |
| --- | --- |
| `steam-20260810T055632Z-hardware-system-dbus-off` | `54be37973dacc77f10e0ee63fa73b7edb76998163ad94c8b75aa343d169968fa` |
| `steam-20260810T060113Z-hardware-holo-mesa-first` | `bf11e7ebf0eac3750f23c514eb293e2f1a3c1b06f461714a6ad800d32ce1c1f6` |

This turns the earlier library-order hypothesis into a narrower GLX/Mesa
failure boundary: Holo-first ordering alone does not prevent the same Mesa
callback from reaching address zero. The next diagnostic should force
software GL only in the Steam client while leaving the Termux:X11 Android
surface hardware-backed and retaining the explicit Vulkan ICD. A successful
Steam frame there would separate the client GLX path from the Android display
transport; it would be diagnostic evidence, not yet a hardware-rendered game
claim.
