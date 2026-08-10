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
