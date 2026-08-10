# Nova Geometry Wars Proton 11 DXVK corrected result — 2026-08-10

## Result

`PROTON_USE_WINED3D=0` did not make the installed Proton 11 ARM64 path use
DXVK. The corrected direct invocation reached the real Geometry Wars
executable, but the fresh trace loaded `d3d9.dll`, `wined3d.dll`, and
`opengl32.dll`; it contained no DXVK, Vulkan, Turnip, or llvmpipe evidence.
The game exited with status 5 before producing a Geometry Wars frame. This is
a negative renderer-selection/startup result, not evidence against the
Freedreno Vulkan driver: the independent Vulkan probe in
`docs/245-nova-freedreno-vulkaninfo-probe-result-2026-08-10.md` still proves
Turnip works outside this Proton game path.

## Evidence

- Run ID: `nova-game-geometry-dxvk-corrected-20260810T081025Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532e`
- Fresh launcher readiness: `pass`, display `:0`, geometry `1280x960`
- Fresh D-Bus bus: `/tmp/nova-steam-runtime/dbus-session-6949/bus`
- Direct command: `direct-command.txt` and the corrected single-argument
  `direct-remote-command.txt` in the run directory
- Direct exit: `adb_exit_status=5`, `timed_out=0`, 11 process polls
- Direct stderr: 836 lines; the decisive module sequence is:
  `GeometryWars.exe` → `d3d9.dll` → `wined3d.dll` → `opengl32.dll`
- Final trace: `winepulse.drv`, `winealsa.drv`, and `Reconstructing context`
  were the last relevant lines; no DXVK/Vulkan renderer log was created
- Prelaunch screenshot SHA-256:
  `9c92cb534f7c91dfe24be5a6072c83bccd756e177277f078315926485979db91`
- Poll-4 screenshot SHA-256:
  `726b05fa2b42e6464b9c48f088a1721216782703b9fe9eb98bf296a35de5d862`

The poll-4 image is a changed Steam client frame, not the game. It shows the
same Steam UI path with the client content letterboxed inside the 1280×960
surface; it does not establish a game render or a 4:3 game presentation.

## State protection and cleanup

The run captured the AppID-8400 registry files, Proton FEX configuration, and
the ten existing `drive_c/windows/{system32,syswow64}` D3D/DXGI files before
launch. Proton changed `system.reg` and `user.reg` during startup, while
`userdef.reg`, `proton-fex-config.json`, and all ten D3D/DXGI files retained
their baseline contents. All captured files were restored and every entry in
`restore-cmp.txt` returned `pass`.

The corrected invocation's first-level run log directory was empty and was
removed. The APK and Termux:X11 were stopped; both exact cleanup helpers
returned `pass`; no matching Nova, Gamescope, Steam, Wine, Proton, Xwayland,
or uinput process remained; only the two baseline udev sockets remained; and
the temporary restore files were removed. Launcher state files were also
removed after the final cleanup.

## Interpretation and next step

The renderer switch is not reaching DXVK for this 32-bit Geometry Wars path,
so repeating the same `PROTON_USE_WINED3D=0` environment change is not useful.
The next controlled experiment should force the prefix's D3D9/DXGI DLL
selection explicitly—using the installed ARM64 DXVK files and a fresh prefix
DLL snapshot—while preserving the successful Turnip ICD and one-click Steam
surface. The Proton source captured during follow-up inspection explains why:
`runinprefix` calls `init_session(False)`, so it does not run `setup_prefix()`;
that setup is where Proton installs the native DXVK files and adds its `n`
DLL overrides. The prefix already contains the same DXVK hashes for `d3d9`,
`d3d11`, `d3d10core`, and `dxgi`, but the direct `runinprefix` command did not
explicitly request those native overrides. The next run will therefore add
the exact `WINEDLLOVERRIDES` entries and `SteamGameId=8400` so Proton both
selects the native files and writes its run-scoped log. If that still loads
WineD3D, the shared blocker is in Proton/FEX's 32-bit DLL dispatch rather than
Gamescope-to-Android presentation.

The complete reproducible artifacts are under:
`android/nova-lab/build/runs/nova-game-geometry-dxvk-corrected-20260810T081025Z`
