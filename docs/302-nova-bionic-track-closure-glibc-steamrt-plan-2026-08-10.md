# Nova Bionic track closure and glibc SteamRT plan — 2026-08-10

## Decision

Pause the GameNative/WinNative Bionic runtime experiments as a separate
historical track. Do not add an APK-side Bionic launcher or keep extending the
root/chroot adapter in the current rendering investigation. The existing
records remain valuable because they distinguish an Android linker/runtime
boundary from a Vulkan or game failure:

- [docs/297](297-nova-gamenative-proton-arm64ec-result-2026-08-10.md) closed
  the incorrectly modeled attempt to run the Android/Bionic WCP inside the
  glibc Holo rootfs.
- [docs/299](299-nova-gamenative-bionic-direct-namespace-result-2026-08-10.md)
  proved the official GameNative Proton `11.0-1-arm64ec` payload can reach
  `wine-11.0` through Android's linker with the Bionic imagefs and preload
  chain, but the game attempt stopped at root-prefix ownership or shell linker
  namespace rules.
- [docs/300](300-gamenative-bionic-android-namespace-adapter-predeclaration-2026-08-10.md)
  predeclared the root-side namespace adapter.
- [docs/301](301-nova-gamenative-bionic-android-namespace-adapter-result-2026-08-10.md)
  recorded the adapter's final boundary: the corrected APEX mount made
  `linker64` visible, but the Android linker still rejected the run-scoped
  Bionic preload library before Wine started.

No APK-side helper was implemented after that result. The Bionic track is
therefore paused without claiming that GameNative's Android renderer or
runtime is generally unusable.

## Why the glibc Holo path is the primary track

The existing Holo path has already launched the real Windows executable through
the standard glibc-side Proton, Wine, and FEX chain. A later control reached
DXVK and Turnip, then failed at the Wine-facing presentation boundary rather
than before graphics initialization. The DMA-BUF WSI result is recorded in
[`docs/293-nova-android-wsi-layer-dmabuf-result-2026-08-10.md`](293-nova-android-wsi-layer-dmabuf-result-2026-08-10.md).

That makes the next work concrete:

1. Reproduce the actual Steam compatibility-tool setup path, or reproduce its
   prefix initialization exactly, before interpreting a game launch failure.
2. Capture fresh Proton/DXVK logs and the effective `WINEDLLOVERRIDES` for
   every game attempt. A direct `wine` invocation without Proton's normal
   setup is not a fair DXVK control.
3. Test WineD3D through Proton with `PROTON_USE_WINED3D=1`, using a genuinely
   software OpenGL environment and recording the selected Mesa driver. Keep
   FEX/32-bit failures separate from the renderer result.
4. Inspect and, if justified, implement the smallest Wine-facing WSI change:
   Proton/Wine requests `VK_KHR_win32_surface`, while the current layer's
   useful X11 bridge is exposed as Xlib/XCB. Treat Win32-surface-to-X11
   translation as a separate narrow experiment, not another Gamescope/AHB
   change.
5. Inventory the runtime pairing before choosing Proton 11. Valve's current
   Steam Runtime documentation says Proton 11 and newer use Steam Runtime 4,
   while Proton 8–10 use Steam Runtime 3 (`sniper`). The Holo tree currently
   contains SteamRT3C/ARM64 material, so Proton and runtime must be treated as
   a matched pair rather than assumed interchangeable.

Authoritative references:

- [Valve Proton runtime options](https://github.com/ValveSoftware/Proton),
  including `PROTON_USE_WINED3D=1`.
- [Valve Proton 11 README](https://github.com/ValveSoftware/Proton/blob/proton_11.0/README.md).
- [Valve Steam Runtime documentation](https://github.com/ValveSoftware/steam-runtime),
  including the Proton 11/Steam Runtime 4 and Proton 8–10/Steam Runtime 3
  pairing.

## Glibc control ladder

Each item is a separate run with a fresh baseline, exact artifact identity,
fresh logs, and a pushed result before the next item:

### Control A — supported Steam/Proton setup

Inventory the Holo rootfs, installed compatibility tools, Steam client
runtime, Steam Linux Runtime directories, Proton version, and AppID 8400
prefix. Then launch through Steam's normal AppID path with the selected Proton
tool, preserving the real Steam environment and prefix initialization. Capture
the complete command/environment boundary without adding a renderer override.

### Control B — DXVK prefix verification

Using a fresh run copy of the prefix, confirm Proton's setup created the DXVK
DLLs and the expected DLL overrides. Enable `PROTON_LOG=1`, a run-scoped
`PROTON_LOG_DIR`, and DXVK logging. Only after these artifacts are present
should a Vulkan/WSI failure be classified.

### Control C — Proton WineD3D software fallback

Repeat the same Steam/Proton launch with `PROTON_USE_WINED3D=1`. Force and
record a software GL selection only if the Holo Mesa tree actually provides
the required software driver. The acceptance target is a game frame or a
layered failure after WineD3D initialization; missing 32-bit/FEX pieces are a
separate result.

### Control D — Win32-surface WSI contract

Before changing the layer, trace the exact Proton/Wine extension negotiation
and `vkCreateWin32SurfaceKHR` call path. Compare it with the current layer's
Xlib/XCB bridge. Implement only a narrow adapter if the evidence shows that
the missing translation is the first failing boundary. Validate with a native
probe and one Proton game run using the same layer artifact.

### Control E — runtime pairing

If Control A shows a SteamRT3C/Proton 11 mismatch, test a compatible pairing:
either the Holo-supported Proton/runtime combination or the Steam Runtime 4
content required by Proton 11. Do not mix runtime trees silently, and do not
call a result a Proton rendering regression until the pairing is recorded.

## Guardrails

- Keep the Bionic records immutable historical evidence; do not fold their
  artifacts into the glibc path.
- Preserve the current user-owned `README.md` edit and stage only intentional
  documentation or source changes.
- Before every Nova device run, use the lifecycle contract in
  [`docs/34-nova-runtime-harness-lifecycle.md`](34-nova-runtime-harness-lifecycle.md).
- Commit and push each predeclaration/result before starting the next bounded
  experiment.
