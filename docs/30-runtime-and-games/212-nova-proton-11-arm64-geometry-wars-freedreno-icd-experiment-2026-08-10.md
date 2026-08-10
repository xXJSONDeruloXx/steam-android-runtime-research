# Nova Proton 11 ARM64 Geometry Wars Freedreno-ICD experiment — 2026-08-10

Status: completed; no Geometry Wars frame, and the ICD was not exercised by
this WineD3D/OpenGL path.

## Question

The prior Geometry Wars run reached Proton 11 ARM64, FEX, Wine, and Direct3D
9, but Vulkan physical-device enumeration returned `res -3`, wined3d selected
llvmpipe, and the game ended before a frame. The clean Steam hardware-profile
run separately showed that enabling the same Freedreno environment for Steam's
CEF/UI path currently segfaults before a usable Steam frame.

This run isolates the game-side Vulkan/GL environment. Steam and Termux:X11
will use the known-good software UI profile; only the direct Geometry Wars
process will receive the explicit Nova Freedreno ICD. A game frame would show
that the hardware game path can work even while the Steam CEF path remains
unresolved. A repeat of the prior llvmpipe/FEX failure remains a valid negative
result.

## Run identity

Run ID: `proton-arm64-20260810T044735Z-geometry-wars-freedreno-icd`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `2bc1f5e`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Steam AppID `8400`, `GeometryWars.exe`, executable SHA-256
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`;
- retained Proton 11 ARM64 wrapper
  `compatibilitytools.d/proton-11-arm64` and AppID-8400 compatdata;
- Termux:X11 display `:0`, target geometry `1280x960`;
- `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json` selected only for the
  direct game process.

This document is committed and pushed before the device run. The installed
Geometry Wars files, Proton package, account state, and existing prefix will
be retained. The direct run may update normal Proton/Wine startup metadata;
run-specific logs and temporary launcher state are disposable.

## Controlled variables

1. Run the exact X11 and rootfs cleanup helpers and verify a fresh process,
   mount, socket, and launcher-state baseline.
2. Start the one-click APK with the default software Steam profile so Steam
   establishes the known-good X11 presentation surface at `1280x960`.
3. Invoke the installed `GeometryWars.exe` directly through the retained
   chroot-visible Proton 11 ARM64 wrapper and the existing AppID-8400 prefix,
   preserving the prior direct-run environment except for
   `VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`.
4. Capture the direct command status, process lifetime, Proton/Wine/FEX log,
   Vulkan/renderer selection, and repeated same-run screenshots. A Proton log
   or zero wrapper return code without a real Geometry Wars frame is not a
   rendering pass.
5. Stop the session with the exact helpers and verify that the installed game,
   Proton wrapper, prefix, and Steam state remain present.

No CPU-feature registry values, game binary changes, CEF flags, Gamescope,
AHardwareBuffer, or input/audio changes are part of this run.

## Acceptance and cleanup

A display prerequisite requires fresh `nova_launcher_ready=pass` and X11
readiness. Game startup requires a real Geometry Wars/Wine process and Proton
evidence beyond the prior launch boundary. Game rendering requires a same-run
1280x960 screenshot that is not the unchanged Steam UI. The result will be
classified at the first failed layer.

Before and after the run, use the exact Nova/X11 and rootfs cleanup helpers.
Do not use broad process killing or remove installed game, prefix, Proton,
shader-cache, or account data. Commit and push the result before another
device experiment.

## Discarded setup attempt

The initial run identity `proton-arm64-20260810T044735Z-geometry-wars-freedreno-icd`
passed the fresh X11/launcher readiness boundary and entered the direct
chroot namespace. Proton did not start: the root-created run-specific
`/tmp/nova-geometry-wars-freedreno-proton` directory was not writable by the
Steam UID 501 process, producing:

```text
PermissionError: [Errno 13] Permission denied: '/tmp/nova-geometry-wars-freedreno-proton/steam-8400.log'
direct_rc=1
```

No Wine, FEX, Vulkan, game, or frame result exists for that attempt. The
software Steam/X11 session was cleaned with
`nova_x11_cleanup=pass` and `nova_runtime_cleanup=pass`; the retained game,
prefix, and Proton data were not changed. The discarded output and pre-game
captures are retained under
`/tmp/proton-arm64-20260810T044735Z-geometry-wars-freedreno-icd/`.

## Retry predeclared run

Run ID: `proton-arm64-20260810T045216Z-geometry-wars-freedreno-icd-retry`

The retry keeps every declared game/display variable unchanged and changes
only the harness setup: the direct-run helper will chown its fresh Proton log
directory to `501:20` before invoking Proton. It will start from a new exact
cleanup baseline, establish the default software Steam/X11 surface, and then
repeat the direct Geometry Wars launch with the explicit Freedreno ICD. The
retry must produce a new launcher session token before any readiness or game
claim is accepted. Its artifacts will be retained under
`/tmp/proton-arm64-20260810T045216Z-geometry-wars-freedreno-icd-retry/`.

## Retry result

The retry created fresh launcher session `20260810T045317Z-11185`. The
software profile reached `nova_launcher_ready=pass` at `1280x960`, with the
gamepad relay ready on `event9`. The direct namespace reported
`mount_private=pass` and `x11_namespace_input=pass`. Proton then created a real
`GeometryWars.exe` process (PID `12754`) under Proton PID `12753`, with Wine's
server/device helpers and `winedbg` also present.

The direct Proton header recorded the requested AppID and explicit ICD
environment, and loaded the real PE32 executable, `d3d9.dll`, `wined3d.dll`,
native `d3dx9_32.dll`, and `XINPUT1_3.dll`. However, it also recorded:

```text
Effective WINEDEBUG: +timestamp,+pid,+tid,+seh,+unwind,+threadname,+debugstr,+loaddll,+mscoree
D 24 Host CPU doesn't support atomics. Expect bad performance
```

This path remained in WineD3D/OpenGL; no Vulkan physical-device or Freedreno
renderer selection appeared in the captured Proton excerpts. Setting
`VK_ICD_FILENAMES` therefore did not yet test a Vulkan game renderer for this
title. The game stayed in a repeated access-violation/exception loop instead
of presenting a window. The generated `steam-8400.log` reached
`12,656,505,994` bytes before the exact run-specific Wine/FEX processes were
stopped to prevent further storage growth. Bounded head/tail excerpts and the
process/screenshot captures remain under
`/tmp/proton-arm64-20260810T045216Z-geometry-wars-freedreno-icd-retry/`; the
explosive full log was removed as disposable run output.

No Geometry Wars frame appeared. The same-run screenshots remained on the
Steam splash/library UI; the late screenshot SHA-256 is
`652388491a4f390753efd039f32bf4408fd5d8ef8992a2e4928d4363190d1cce`.
The direct command was intentionally terminated with status 143 after the
bounded capture, so this is not a natural game-exit result and does not prove
that the executable would eventually render. It does prove the run passed the
prior immediate process-creation failure and reached a persistent 32-bit
Geometry Wars/Wine boundary.

## Clean-log retry predeclared

Run ID: `proton-arm64-20260810T045759Z-geometry-wars-freedreno-icd-clean-log`

The next run keeps the same game, prefix, software Steam/X11 surface, and
explicit Freedreno ICD. It changes only Proton logging: the direct helper will
set `WINEDEBUG=-all` while retaining `PROTON_LOG=1`, preventing the observed
SEH trace loop from consuming storage and allowing a bounded natural startup
observation. It will use a new exact cleanup baseline, a new launcher session,
and a new artifact directory. The result will still distinguish a real game
frame from a live process or wrapper return code.

## Clean-log retry result

The clean-log run created fresh launcher session
`20260810T045923Z-16419`. The default software profile passed
`nova_launcher_ready=pass` at `1280x960`, and the gamepad relay was ready on
`event9`. The direct namespace reported `mount_private=pass` and
`x11_namespace_input=pass`. The direct command ran from
`2026-08-10T04:59:52Z` to `2026-08-10T04:59:55Z` and returned:

```text
direct_game=GeometryWars.exe
direct_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
direct_rc=5
```

The bounded 67,392-byte Proton log has SHA-256
`3c3a70eea7c335a9168ff275d91aecee2abd29e304d513e4199cb07458427554` and
records both `System WINEDEBUG: -all` and `Effective WINEDEBUG: -all`.
Proton loaded the actual Geometry Wars executable, `d3d9.dll`,
`wined3d.dll`, `opengl32.dll`, native `d3dx9_32.dll`, and `XINPUT1_3.dll`.
There is no Vulkan physical-device, Turnip, or llvmpipe selection in the
fresh log. The requested Vulkan ICD was exported to the process, but this
Direct3D 9 configuration used WineD3D/OpenGL and therefore did not exercise
that ICD. The log also repeats the known FEX message
`Host CPU doesn't support atomics. Expect bad performance` and includes the
existing Mesa shader-cache permission warning.

No Geometry Wars window or frame appeared. The late 1280x960 screenshot shows
the Steam Geometry Wars library page, not the game; its SHA-256 is
`908f4f9437f371ef8741f35d2a9c1bdb7946253a54b07c8b229e47176245140b`. The
direct command's captured output SHA-256 is
`d66fe3feccc1c34f8f52f5e287681c7da950660268445c5e2ad1499de3375c67`.

This is a real game-process/startup result, but not a game-rendering result:
the previous run's immediate trace-loop condition was bounded, the game still
returned `5`, and the current display evidence remained Steam UI. Combined
with the earlier no-ICD Geometry Wars run and the Peggle control, this lowers
the value of trying more small 32-bit games without first addressing the
shared Proton 11 ARM64/FEX/WineD3D boundary. The next useful game experiment
would need to explicitly test a D3D9 Vulkan/DXVK path or the FEX/atomic
failure, rather than merely exporting a Vulkan ICD to WineD3D.

## Final cleanup and persistent state

The exact X11 cleanup and rootfs cleanup both initially reported
`nova_x11_cleanup=pass` and `nova_runtime_cleanup=pass`. Two orphaned
run-specific Wine helper PIDs (`17888` and `17916`) remained after the natural
game exit and were removed by exact PID after their command lines were
verified; the final process, mount, socket, launcher-state, and temporary-log
checks were empty. The retained Geometry Wars install, AppID-8400 compatdata,
Proton 11 ARM64 wrapper, Steam account state, and rootfs are intact.

Run artifacts are retained under
`/tmp/proton-arm64-20260810T045759Z-geometry-wars-freedreno-icd-clean-log/`.
The device's 67,392-byte run log and helper script were removed after capture;
the host copy, bounded excerpts, screenshots, and direct-run record remain.

### Post-run cleanup correction

On 2026-08-10, a later storage audit found two orphaned AppID-8400 Wine
process groups that the original final filter had missed. The verified stale
child PIDs were `12761`, `12773`, `12779`, `12811`, `12829`, `12840`, `12848`,
`12862`, `17892`, `17904`, `17910`, `17941`, and `17959`; they were Windows
Wine services, `xalia`, and `conhost` processes holding deleted
`steam-8400.log` descriptors. They were terminated by exact PID after command
line verification, followed by `sync`; no broad process kill was used. The
Geometry Wars install, prefix, Proton 11 ARM64 wrapper, account state, and
game files were preserved. This correction supersedes the original claim that
the first final process check was sufficient to prove the Wine groups absent.
