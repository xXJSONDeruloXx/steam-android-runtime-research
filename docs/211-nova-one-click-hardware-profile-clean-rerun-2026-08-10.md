# Nova one-click hardware profile clean rerun — 2026-08-10

Status: completed; hardware Steam UI failed before producing a usable frame.

## Question

The prior mount-master retry loaded `com.termux.x11.CmdEntryPoint`, but a
leftover manual X11 probe owned the socket and invalidated the UI attempt. The
probe is now terminated, the Activity is stopped, and the rootfs/X11 paths have
been checked. This run repeats the same opt-in hardware profile with one
variable changed: a genuinely clean X11 process baseline.

## Run identity

Run ID: `gpu-20260810T043806Z-x11-steam-hardware-clean-rerun`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `f8d4534`;
- rebuilt APK with `su -mm 0` root launch and explicit `hardware_accel` intent;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Termux:X11 display `:0`, fullscreen/full-desktop-resolution, target
  `1280x960`;
- `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json` selected through the
  hardware profile;
- no physical or synthetic input and no audio bridge.

## Controlled baseline

Before the Activity launch, use the exact cleanup helpers, force-stop the Nova
and Termux:X11 packages, and prove that no `termux-x11`, `app_process` with
`CmdEntryPoint`, Steam, Gamescope, Wine, FEX, relay, X11 socket, or rootfs
mount from a prior run remains. Do not run a separate manual X11 probe during
this experiment.

The app is started with:

```text
am start -W -n com.xjsonderulo.steamandroid.novalab/.LauncherActivity \
  --ez run_steam_session true --ez hardware_accel true
```

## Acceptance and cleanup

A pass requires the current launcher to record `nova_launcher_ready=pass`,
the client log to show hardware mode and the explicit ICD, fresh Steam and
webhelper startup evidence, and a same-run stable Steam screenshot. A startup,
Steam, or CEF crash is recorded at its first failed layer and is not counted
as a hardware-rendering pass. Only if the Steam UI is stable will the next
run test hardware game rendering.

After capture, run the exact X11 and rootfs cleanup helpers and verify no
matching process, mount, socket, or temporary launcher state remains. Commit
and push the result before any next experiment.

## Result

The controlled baseline was clean. The Activity was then launched with the
declared `hardware_accel=true` extra. The fresh launcher reached
`nova_launcher_ready=pass` at `display=:0 geometry=1280x960`, and the X11
server loaded Termux:X11 `CmdEntryPoint` commit
`d8013ac5d174bb16120f915c10a7255948c59c17`. Android Adreno EGL initialized,
the XCB connection succeeded, and the server exchanged 1280x960 shared
buffers with the Activity. This validates the Android/Termux:X11 display
boundary for this run.

The Steam client also reached its hardware launch boundary:

```text
client_hardware_accel=1
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_mesa_driver=unset
client_gallium_driver=unset
client_libgl_always_software=unset
client_flags_final=... -no-cef-sandbox -fullscreen -fulldesktopres
client_started=pass
client_status=139
```

Network compatibility, the D-Bus system/session probes, and the installed
client checks all passed. Steam then segfaulted before producing a usable
Steam frame. Its fresh stderr records a Mesa shader-cache permission warning,
followed by minidump
`/tmp/dumps03/crash_20260810043924_3.dmp` and CrashID
`bp-ebac7dad-075a-475d-acc3-afee12260809`. The device minidump was pulled to
`/tmp/gpu-20260810T043806Z-x11-steam-hardware-clean-rerun/crash_20260810043924_3.dmp`
with SHA-256
`d13507b55be69f8b455150ca175e3ecc5f939bc0e1d41f8a8ebea738a3487a18`.

The only same-run screenshot remained the Nova Launcher Activity reporting
launcher status 143; it is not a Steam UI result. Its SHA-256 is
`ac76071bd77db4245da06e0e29f6aff15c868658d06346c49b728badc1649060`.
`nova_launcher_client_exit=0` is the wrapper's post-child exit status and does
not override the client's recorded status 139.

This is therefore a hardware Steam/CEF startup failure, not a rendering pass.
It does not justify making the hardware profile the default, and it does not
invalidate the existing software profile. The next useful experiment is to
isolate Steam's CEF GPU path from the explicit Vulkan/GL environment, keeping
the working Termux:X11 and software default unchanged.

## Artifact provenance

- Run ID: `gpu-20260810T043806Z-x11-steam-hardware-clean-rerun`; the launcher
  session token was `20260810T043917Z-30636`.
- Source commit: `f8d4534`; installed Nova APK SHA-256:
  `3cf09db54b4aa45518326ddcc874b32ae5bd9d55b67b412fd928c1ae9e5462a5`.
- Termux:X11 base APK SHA-256:
  `6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705`.
- Freedreno ICD SHA-256:
  `337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70`.
- Freedreno Vulkan library SHA-256:
  `a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810`.
- Rootfs Steam executable SHA-256:
  `6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf`.
- Launcher log SHA-256:
  `49abcbc2d0dbe38e36164a3b34a4aed7a2816bca086a1800d100451738970a16`.
- Client log SHA-256:
  `53f92bee5f36255b145b35260ae901fbaf6037e9b730af2f3c93a475d7d7598c`.
- Client stderr SHA-256:
  `a78b9ade90435190c1cb0351b6fb332714900c4a41f8b0f6c1857d20386e13cb`.
- Termux:X11 server log SHA-256:
  `a1b52811c5db23cb809a756a5f45a25a044367f059cb21146ba47a753c259bd5`.
- Post-run logcat capture SHA-256:
  `e6561d5b253d8595893297f74ac6635e42db2f149d034c0c8eb64dd806b57491`.

The first cleanup attempt raced a launcher-parent PID and reported
`server_parent_state=present` / `nova_x11_cleanup=fail`; no socket or client
remained. Re-running the exact X11 helper after the parent exited reported
`nova_x11_cleanup=pass`, and the exact rootfs helper reported
`nova_runtime_cleanup=pass`. A final process, socket, mount, and launcher-state
check found no matching runtime processes, X11 socket, rootfs mount, or
`server-parent.pid`. Installed games, Proton 11 ARM64, Steam state, and the
rootfs remain intact.
