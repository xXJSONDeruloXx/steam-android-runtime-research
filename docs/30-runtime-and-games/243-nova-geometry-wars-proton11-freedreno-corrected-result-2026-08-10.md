# Nova Geometry Wars Proton 11 explicit Freedreno corrected result — 2026-08-10

## Result summary

The corrected direct run reached the real `GeometryWars.exe` process under
Proton 11 ARM64/FEX and loaded Wine's X11, D3D9, wined3d, DirectInput,
Steam, and audio modules. It exited with status `5` before producing a game
frame. All same-run captures remained the authenticated Steam desktop UI.

The exact command did contain the launcher Freedreno ICD
(`VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`), but the
fresh trace emitted no Vulkan physical-device or renderer line. Therefore
this run does not prove that the ICD was consulted or that it changed
enumeration; it does establish that adding the variable did not carry
Geometry Wars through startup.

## Run identity and provenance

- Run ID: `nova-game-geometry-freedreno-20260810T075005Z`
- Run directory:
  `android/nova-lab/build/runs/nova-game-geometry-freedreno-20260810T075005Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Compatibility tool: Proton 11.0 (ARM64),
  `compatibilitytools.d/proton-11-arm64`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Presentation: hardware-backed Termux:X11 Android SurfaceView, 1280×960
- Steam client: software GL (`swrast`, `softpipe`,
  `LIBGL_ALWAYS_SOFTWARE=1`)
- D-Bus session: `/tmp/nova-steam-runtime/dbus-session-18478/bus`
- Prefix registry before/restored:
  - `system.reg` `d7380fdeaba4a14f29b3be9d4ff5816636c4fad2fd096324e9d90d756c1401ca`
  - `user.reg` `d8ba0cfab7e6e66ff466e9bc02d9f4fe64d93184f712d4367fe08fd08206960f`
  - `userdef.reg` `a2e53741b4af39b5371308fb9ab998988cbdd0ed69b377dc29c89d1a6cfa791e`

The corrected run was predeclared and pushed in
[`docs/30-runtime-and-games/242-nova-geometry-wars-proton11-freedreno-corrected-run-2026-08-10.md`](242-nova-geometry-wars-proton11-freedreno-corrected-run-2026-08-10.md),
commit `01e783d`. The earlier unquoted-path attempt is recorded in
[`docs/30-runtime-and-games/241-nova-geometry-wars-proton11-freedreno-direct-run-2026-08-10.md`](241-nova-geometry-wars-proton11-freedreno-direct-run-2026-08-10.md).

## Fresh session and direct launch

The one-click launcher reported:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_cef_disable_gpu=1
nova_launcher_steam_ui_mode=minimal
nova_launcher_steam_force_software_gl=1
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The exact quoted request is retained in
`android/nova-lab/build/runs/nova-game-geometry-freedreno-20260810T075005Z/direct-command.txt`.
It used `proton runinprefix`, `PROTON_LOG=1`, a run-scoped
`PROTON_LOG_DIR`, software-GL variables, and the explicit Freedreno ICD.
The wrapper returned `direct_status=5`; it did not time out.

The fresh stderr trace recorded:

```text
D 24 Host CPU doesn't support atomics. Expect bad performance
D 24 Load module GeometryWars.exe ...
D 24 Load module d3d9.dll ...
D 24 Load module wined3d.dll ...
D 24 Load module XINPUT1_3.dll ...
D 24 Load module winex11.drv ...
D 24 Load module winepulse.drv ...
D 24 Load module winealsa.drv ...
D 24 Reconstructing context
```

The process poll captured a live `GeometryWars.exe` child, `wineserver`, and
Wine device processes during startup. No game process remained after the
wrapper exited. The four repeated screenshots remained Steam desktop frames;
the final capture shows the Store page and Friends window, not Geometry Wars.

`PROTON_LOG=1` did not emit a file under the requested run-scoped log
directory. The 835-line `direct.stderr` file is the fresh Proton/FEX/Wine
trace for this run and is retained as the authoritative diagnostic artifact.

## Interpretation

This result does not support returning to Gamescope-to-AHardwareBuffer work:
the direct path reached the game process and Wine X11 while the existing
Termux:X11 surface stayed live. It also does not yet isolate the ICD, because
Geometry Wars uses the D3D9/wined3d path and no Vulkan enumeration message was
observed.

Across the Steam-mediated Geometry Wars and Peggle runs, and this direct
Freedreno comparison, the stable blocker remains before a game frame at the
32-bit Proton/FEX/Wine startup boundary. The next focused diagnostic should
capture Wine's Vulkan/wined3d channels explicitly or use a small Vulkan-native
probe, rather than infer ICD success from an environment variable alone.

## Cleanup and restoration

- `nova_x11_cleanup=pass`
- `nova_runtime_cleanup=pass`
- no matching Nova, Gamescope, Steam, webhelper, Proton, Wine, FEX, or
  Termux:X11 process after the settled check
- the run-scoped log directory and exact stale Steam sockets were removed
- `system.reg`, `user.reg`, and `userdef.reg` compare byte-for-byte with their
  pre-run snapshots
- final rootfs sockets contain only the reusable baseline udev sockets:
  `/run/udev/control` and `/run/udev/io.systemd.Udev`

## Artifacts

- launcher log SHA-256 `ebab36edfab490325fe6bceb91ab20994cf7e501a3dbce969bf25d2a275af80e`
- exact command SHA-256 `264042c40556ee4ce2efcb37220667fff2375d69869de160197f26b92106f97f`
- direct stdout SHA-256 `1619903f56f05254d534cdef3a73b870320808649bc159c8b5f57bca9e223eec`
- direct stderr SHA-256 `41306feba0cdf20a57a6288803f7a3a1e107d1129b2a68c01233179d7fdb90f1`
- direct status SHA-256 `e6937c12ac5fb17f3d43ae41f47385b1529f532ac0b19f5ee23b891411571ac1`
- process poll SHA-256 `e5d0583350fe94f9610cbcd9a5aaaa2a69917314af939153e4d53a957fb90597`
- prelaunch screenshot SHA-256 `c21f19c212d46c406e1c389bd3cefc1c6647d09ef4b41a5238458bbead473058`
- Geometry screenshots:
  - `screen-01.png`: `2c5526424e58513ad4ee05e38dc2cebd5e2e212390d0f882782bbc9c684bbee5`
  - `screen-02.png`: `74358111dc5bf3c8491ade455ca15a944dca808c7198760b18fb8d9e305de231`
  - `screen-03.png`: `dfada710c906dddbe761e38f96dea51b07a77a225b2f1ed186ee1c040b561b8e`
  - `screen-04.png`: `163c75a4507bd8158dc3c3f27369e9e37e61b56334dc41eda943bde8fa6ce722`
- final process check SHA-256 `a37a9a6f2d7bbdd94a0b0d4f691499a2d90e2671a093be05d16f138e3cb06970`
- final mounts check SHA-256 `8b6ccea3ed9835c1639f095046c5fb5662ea8d140860dc51d257cf253f8ce5d3`
- final rootfs socket inventory SHA-256 `e85c24c031da253a5b3738ff85fd567af1680c23c4a30c705aaaf35b77eb6bb3`
- restored `system.reg` SHA-256 `d7380fdeaba4a14f29b3be9d4ff5816636c4fad2fd096324e9d90d756c1401ca`
- restored `user.reg` SHA-256 `d8ba0cfab7e6e66ff466e9bc02d9f4fe64d93184f712d4367fe08fd08206960f`
- restored `userdef.reg` SHA-256 `a2e53741b4af39b5371308fb9ab998988cbdd0ed69b377dc29c89d1a6cfa791e`
