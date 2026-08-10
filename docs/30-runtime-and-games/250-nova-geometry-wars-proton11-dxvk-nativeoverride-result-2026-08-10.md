# Nova Geometry Wars Proton 11 DXVK native-override result — 2026-08-10

## Result

Explicit native DLL dispatch worked. Proton recorded
`SteamGameId: 8400` and the exact effective
`WINEDLLOVERRIDES=d3d11=n;d3d10core=n;d3d9=n;dxgi=n`. Geometry Wars then
loaded DXVK 2.7.1 through `d3d9.dll`; `winevulkan.dll` loaded and resolved
`vkGetInstanceProcAddr`. This closes the earlier ambiguity: the 32-bit FEX
path can reach Proton's DXVK/WineVulkan stack when native DLL selection is
requested explicitly.

The run still failed before a game frame. DXVK enabled
`VK_KHR_win32_surface`, then logged
`DxvkInstance::createInstance: Failed to create Vulkan instance` and exited
with status 3. No Geometry Wars image appeared. The remaining blocker is now
inside WineVulkan/Vulkan instance or WSI creation for the 32-bit process, not
Gamescope-to-Android presentation and not the prefix DLL selection.

## Evidence

- Run ID: `nova-game-geometry-dxvk-nativeoverride-20260810T082211Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Fresh launcher readiness: `pass`, display `:0`, geometry `1280x960`
- Fresh D-Bus bus: `/tmp/nova-steam-runtime/dbus-session-16926/bus`
- Direct exit: `adb_exit_status=3`, `timed_out=0`, 7 process polls
- Proton log: `steam-8400.log`, 861 lines
- Proton log SHA-256:
  `0f686eeba41a94faa2c79166dff284e8c288897bee7bf28fead8365a216e7736`

The decisive fresh log sequence is:

```text
Proton: 1779182345 proton-11.0-1-beta5-unstripped
SteamGameId: 8400
System WINEDLLOVERRIDES: d3d11=n;d3d10core=n;d3d9=n;dxgi=n
Effective WINEDLLOVERRIDES: d3d11=n;d3d10core=n;d3d9=n;dxgi=n
info:  Game: GeometryWars.exe
info:  DXVK: v2.7.1-467-g83e503b4ae6de84
D 24 Load module winevulkan.dll
info:  Vulkan: Found vkGetInstanceProcAddr in winevulkan.dll
info:  Enabled instance extensions:
info:    VK_KHR_win32_surface
err:   DxvkInstance::createInstance: Failed to create Vulkan instance
```

The poll-4 screenshot changed from the prelaunch Steam surface but remained
Steam UI, not a Geometry Wars frame. The prelaunch and poll-4 SHA-256 values
are recorded in the run directory alongside the exact remote command.

## State protection and cleanup

The run captured the AppID-8400 registry files, Proton FEX configuration, and
all ten existing `drive_c/windows/{system32,syswow64}` D3D/DXGI files before
launch. `system.reg` and `user.reg` changed during startup; the FEX config and
prefix D3D/DXGI files remained at their baseline contents. All captured files
were restored, and every entry in `restore-cmp.txt` returned `pass`.

The run-scoped Proton log directory was removed after pulling
`steam-8400.log`. Both exact cleanup helpers returned `pass`; no matching
Nova, Gamescope, Steam, Wine, Proton, Xwayland, or uinput process remained;
only the two baseline udev sockets remained; and the temporary restore files
and launcher state files were removed.

## Interpretation and next step

The working chain is now bounded as:

`native DXVK DLLs` → `DXVK` → `winevulkan.dll` → `VK_KHR_win32_surface` →
`Vulkan instance creation failure`

The next controlled probe should run Vulkan enumeration through the same
private namespace and uid with the same `VK_ICD_FILENAMES`, software-GL
variables, and loader library path, then record the instance-extension set and
loader diagnostics. The comparison should specifically check
`VK_KHR_surface` and the X11 WSI extensions before changing Gamescope or
Android presentation code. If the native probe succeeds under the exact
environment but WineVulkan still fails, the next change belongs in the
WineVulkan/WSI bridge or its 32-bit FEX compatibility path.

The complete reproducible artifacts are under:
`android/nova-lab/build/runs/nova-game-geometry-dxvk-nativeoverride-20260810T082211Z`
