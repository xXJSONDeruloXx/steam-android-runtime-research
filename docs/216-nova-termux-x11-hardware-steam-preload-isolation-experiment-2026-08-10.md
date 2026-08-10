# Nova Termux:X11 hardware Steam preload-isolation experiment — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The hardware Termux:X11 path passes Android Adreno EGL, XCB, and the
1280x960 shared-buffer exchange, but the ARM64 Steam client segfaults before
presenting a frame under both CEF-enabled and CEF-disabled profiles. Removing
the SteamOS/GamepadUI flags also left the crash unchanged. The current direct
client always preloads `libsysv-sem-shim.so`, an explicitly experimental
adapter for the Android rootfs's missing System V semaphore calls. This run
tests whether that preload is involved in the later hardware client crash.

The change is opt-in only. The normal launcher keeps the existing preload and
the software profile remains unchanged. `steam_disable_preload=true` disables
the entire client preload chain for this bounded run, including an optional
audio preload if one is accidentally requested; no other client or display
variable changes.

## Source and artifact

Before the device run, build and install the APK from the source commit that
contains the new switch. Record the final source commit, host APK SHA-256, and
the matching device APK SHA-256 in the result. The intended launch extra is:

```text
--ez run_steam_session true
--ez hardware_accel true
--ez cef_disable_gpu true
--es steam_ui_mode minimal
--ez steam_disable_preload true
```

The client must log both `client_disable_preload=1` and
`client_preload=disabled`; `client_preload_mode=disabled` is expected before
that final marker. A `threadtools.cpp` semaphore assertion or
an earlier startup failure is a valid result and distinguishes the shim's
known prerequisite role from the later status-139 crash.

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
steam_disable_preload=true
audio_bridge=false
gamescope=not_used
game_launch=not_attempted
input_action=none
```

The session must use a fresh launcher state, fresh Steam logs, and a fresh
same-run screenshot. Read `docs/34-nova-runtime-harness-lifecycle.md`
immediately before launch. Run the exact X11 and rootfs cleanup helpers before
launch and after capture. Do not reuse the previous status-139 screenshot or
Steam log as readiness evidence.

## Acceptance and interpretation

Acceptance requires fresh launcher readiness, the selected hardware/ICD/CEF/UI
markers, `client_started=pass`, and a retained client stderr/minidump if the
process crashes. A stable Steam frame is required before any game test can be
attributed to this run. The same display-boundary evidence should be retained
even if Steam exits early.

* If Steam reaches a stable frame, retain this as evidence that the preload
  chain participates in the hardware crash and follow with a one-variable
  re-enable split.
* If Steam fails at the expected System V semaphore assertion or exits earlier
  with `Function not implemented`, retain this as evidence that the shim is a
  prerequisite and proceed to isolate a different runtime boundary.
* If Steam still reaches the same status-139 boundary, the shim is not the
  sole cause; the next split should be a different startup layer such as the
  D-Bus setup or Steam runtime library selection.

No game, input, audio, or network acceptance claim is permitted from a run
that does not first produce a fresh stable Steam frame. Commit and push this
predeclaration before installing the APK or launching the device session.

## Result

Status: completed; disabling the preload chain fails at the known System V
semaphore compatibility boundary, before the later hardware status-139 crash.

The source commit was `47024a7`. The rebuilt APK SHA-256 was
`99c0820cdec5153fb98b12353897322da62a9ec726751d1e35fda89f3a75c075`, and
the installed device APK reported the same hash. A first launch attempt with
run ID `steam-20260810T054523Z-hardware-preload-off` was not accepted: the
host poll saw stale state before the new launch had written fresh client
output, and the run was stopped during startup. Its retained assertion dumps
are kept separately under the valid run's `aborted-earlier-dumps/` directory.

The valid fresh run was
`steam-20260810T054843Z-hardware-preload-off-rerun`, with stage token
`20260810T054906Z-2642`. The launcher selected the intended profile:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_cef_disable_gpu=1
nova_launcher_steam_ui_mode=minimal
nova_launcher_steam_disable_preload=1
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The fresh client runtime log recorded:

```text
client_hardware_accel=1
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_cef_disable_gpu=1
client_steam_ui_mode=minimal
client_disable_preload=1
client_preload_mode=disabled
client_preload=disabled
client_dbus_system_status=pass
client_dbus_system_client_probe=pass
client_dbus_session_status=pass
client_dbus_session_client_probe=pass
client_flags_final=... -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu -fullscreen -fulldesktopres
client_started=pass
```

Steam then failed earlier than the normal hardware crash. Fresh stderr
reported all three expected synchronization failures:

```text
src/tier0/threadtools.cpp (2526) : Assertion Failed: Function not implemented
src/tier0/threadtools.cpp (2121) : Assertion Failed: semaphore creation failed Invalid argument
src/tier0/threadtools.cpp (1951) : Assertion Failed: Thread synchronization object is unuseable
```

The three current-run assertion dumps were uploaded with CrashIDs
`bp-c7880147-abc6-489d-82cf-d70f22260809`,
`bp-743dd873-e9cd-40ae-bead-5230f2260809`, and
`bp-03c324d9-84c6-49e0-b68e-faf3e2260809`. No Steam frame was presented; the
same-run screenshot is a black Termux:X11 surface with an X cursor and a
root-grant toast. No game was launched.

The display side remained healthy independently: fresh Termux:X11 output
loaded Android Adreno EGL with driver `0676.53` and EGL 1.5, completed XCB
connection setup, exchanged 1280x1024 and 1280x960 shared buffers, and
reported three frames in five seconds. This run therefore confirms that
`libsysv-sem-shim.so` is a prerequisite for getting past Steam's initial
semaphore calls; it does not implicate the shim as the sole cause of the
later status-139 hardware crash.

Fresh artifacts are retained at
`/tmp/steam-20260810T054843Z-hardware-preload-off-rerun/`:

| Artifact | SHA-256 |
| --- | --- |
| `launcher.log` | `1063895623894b3add9c8862dba6fb6ab4f0f96eddfc1f36ccf7f1cb56fd2361` |
| `client.log` | `1619903f56f05254d534cdef3a73b870320808649bc159c8b5f57bca9e223eec` |
| `client-runtime.log` | `32c41f7d649b8efd78d2bd31535fc37c2be3784b32de7581e175c30d022c8d71` |
| `client-stdout.log` | `e7a3de096b981f2fadf271a67881392867aa0bcceffb3e9f701aecbcf8c376fa` |
| `client-stderr.log` | `8ca0a8e1ec0c7d62d186a6ed034dd89dbdb9874fb6fe7858cde45705efdfa51c` |
| `server.log` | `174ce26b9468c6a8da4601c96e8ecffa5c29684609661be099d7319816f254d6` |
| `screen-00.png` | `03577401505951b1904b48e9daeb89fe36c2b971dd95b259ca776ba1a590184a` |
| `logcat.txt` | `26cc30697db299f983f2e708baef5fdf43f5a2ab991a2eb47ad847aa8f43c8fb` |
| `device-assert_20260810054912_3.dmp` | `abb429bc73afae87a3705d03062063ef58e32cafdcf2a0502d24f062bbce5a04` |
| `device-assert_20260810054912_6.dmp` | `28a67e6673d7267b770930b7039b66b8f09e7996c6d6ed632cd6bd405ab4b435` |
| `device-assert_20260810054912_9.dmp` | `b2d1995cae4762f0dcd01ac5f84dfe9c90884b3ef310beda448a3c8f5c2bb9e2` |
| `cleanup.log` | `993a9e79946cb3239391dcb894e2464c079c0e54db4df37d3c293395533d94fb` |
| `runtime-cleanup.log` | `fe0c931a4fb53e2fb1dd1682eb229174d55f8707df0092087886f66705d95e99` |

The exact X11 and runtime helpers ultimately returned `pass`. One UID-501
Steam `timeout` wrapper survived the first helper pass; its command line was
verified and that exact wrapper and child were terminated as UID 501 before a
second helper pass. Final checks found no matching Steam, Xwayland,
Termux:X11, D-Bus, Gamescope, rootfs-specific process, X11 socket, mount, or
device dump. The fixed rootfs client logs are root-owned run artifacts that
the Android-root context could not unlink; they are not live runtime state or
open device/session resources. The final rootfs filesystem reported
`80,046,764 KiB` available.

The no-preload result closes this split. Keep the semaphore shim in the normal
profile and move the next controlled hardware experiment to a different
startup layer, such as one D-Bus mode or the Steam runtime library selection,
without changing the known-good software UI path.
