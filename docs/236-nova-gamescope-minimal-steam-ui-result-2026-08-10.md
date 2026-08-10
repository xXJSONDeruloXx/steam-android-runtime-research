# Nova Gamescope minimal Steam UI result — 2026-08-10

## Scope

This run isolates the Steam `-gamepadui` startup hypothesis from the
Gamescope/AHardwareBuffer transport. It reuses the libei-enabled Gamescope
artifact and the 1280×960 linear AHB presentation profile from the preceding
run, but launches Steam with `-steamos3 -steampal -steamdeck` and deliberately
omits `-gamepadui`.

The run was predeclared and pushed as
[`docs/235-nova-gamescope-minimal-steam-ui-run-2026-08-10.md`](235-nova-gamescope-minimal-steam-ui-run-2026-08-10.md)
in commit `1d0eccf` on `feat/nova-one-click-launcher`.

## Run identity and provenance

- Run ID: `gamescope-minimal-steam-ui-20260810T071304Z`
- Run directory:
  `android/nova-lab/build/runs/gamescope-minimal-steam-ui-20260810T071304Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Gamescope: `android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope`
- Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Source status: dirty, with status/diff/submodule hashes recorded in the run
  metadata
- APK:
  `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Output: 1280×960, linear AHB, 120 target frames
- Steam rendering isolation: `swrast`, `softpipe`,
  `LIBGL_ALWAYS_SOFTWARE=1`
- Steam flags: `-steamos3 -steampal -steamdeck -nobootstrapperupdate
  -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox`

## Result

The compositor and Android presentation gates passed, but Steam UI did not
reach readiness and no Steam frame was displayed.

Gamescope imported three 1280×960 AHBs, initialized Xwayland and libei, and
reported `android_ahb_target_reached=120`. The Android app report recorded 120
successful imports, GPU writes, image writes, acquire fences, SurfaceControl
latches, and 119 buffer releases. The run ended with clean runtime and
residual-process checks.

Steam reached the client process and downloaded the 237,350 KB client update,
but its fresh client log ended with:

```text
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
```

The client stdout still reported:

```text
Vulkan missing requested extension 'VK_KHR_surface'.
Vulkan missing requested extension 'VK_KHR_xlib_surface'.
BInit - Unable to initialize Vulkan!
```

The captured 1280×960 screenshot is dark/blank rather than Steam UI. There is
no fresh SteamUI/webhelper readiness marker, OOBE marker, login view, or
frame-identity evidence.

## Interpretation

Omitting `-gamepadui` does not remove the current Steam startup blocker. The
failure is upstream of Steam UI readiness and remains the Vulkan instance
extension set visible to the Steam client inside Gamescope/Xwayland. The
`native_steam_smoke=pass` line is only a narrow process/install gate; it must
not be read as a displayed Steam UI result.

The run also provides fresh evidence that the network path is usable during
this startup: Steam completed its client update download before the bounded
client timeout. This does not prove the full logged-in UI network workflow,
but networking is not the first failure in this Gamescope path.

## Artifacts

- Report:
  `android/nova-lab/build/runs/gamescope-minimal-steam-ui-20260810T071304Z/device-gamescope-headless-ahb-report.txt`
  SHA-256 `50dd31e512f75ab30cb74aab2e211b5f839947ae93371f6d612ade54926736fd`
- App report:
  `android/nova-lab/build/runs/gamescope-minimal-steam-ui-20260810T071304Z/device-gamescope-headless-ahb-app-report.txt`
  SHA-256 `f628319217d7289f31af6f9419641febf50fe3f7a18a5fd082a80e596225acd4`
- Logcat:
  `android/nova-lab/build/runs/gamescope-minimal-steam-ui-20260810T071304Z/device-gamescope-headless-ahb-logcat.txt`
  SHA-256 `330f957383e02c1136659e7716a3d0d12d29130709def9a1b958b785f4e4dd62`
- Metadata:
  `android/nova-lab/build/runs/gamescope-minimal-steam-ui-20260810T071304Z/device-gamescope-headless-ahb-metadata.txt`
  SHA-256 `0b1118eb2a551463d68215326413071c912e2b262dc94ea733d5dc7472a1b4f8`
- Screenshot:
  `android/nova-lab/build/runs/gamescope-minimal-steam-ui-20260810T071304Z/device-gamescope-headless-ahb-screenshot.png`
  SHA-256 `58993a39c54f390bbb8466c3105e964a8f07b57ea9d9e25d199b303807100b13`
- Steam client log: `android/nova-lab/build/nova-steam-client.log`
- Steam client stdout: `android/nova-lab/build/nova-steam-client.stdout`
- Steam client stderr: `android/nova-lab/build/nova-steam-client.stderr`

