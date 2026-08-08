# Nova bounded acceptance profile

The long-lived Steam/manual sessions and the protocol-only AHardwareBuffer
checks are separate experiments. The bounded gate for the current 4:3 display
contract is the named `bounded-ahb-1280x960` profile:

```sh
GAMESCOPE_HEADLESS_SOURCE="$PWD/android/nova-lab/build/gamescope-headless-source-six" \
NOVA_GAMESCOPE_HEADLESS="$PWD/android/nova-lab/build/gamescope-headless-build-libei/src/gamescope" \
android/nova-lab/run-nova-acceptance.sh
```

The command refuses implicit artifacts or a non-libei Gamescope binary. It
fixes the experiment at ten AHardwareBuffer frames of 1280x960, fullscreen
1280x960 presentation, and composer-overlay composition. Every run gets a
unique ID and an otherwise-empty directory under
`android/nova-lab/build/runs/`.

The acceptance result requires all of the following from the same run:

- fresh logcat and app-file baselines after exact-scope runtime cleanup;
- Gamescope path, SHA-256, source tree, source commit, libei status, and
  presentation/input flags in the run metadata;
- report, logcat, app report, and metadata files containing the current run ID;
- ten-frame AHardwareBuffer, release-fence, Wayland, and surface markers;
- cleanup helper success plus an independent process-table residual check; and
- no Nova bridge sockets or reports left in the app data directory.

The run directory contains `acceptance.log`, `acceptance-manifest.txt`, the
four text artifacts, and the screenshot. A nonzero result is not evidence for
changing presentation or input: inspect that directory, repair the failed
gate, and start a new run ID.

## Latest verified run

Run `20260808T204106Z-44855` passed on the Nova device on 2026-08-08. Its
manifest records Gamescope SHA-256
`93f4807d55e4ad95e8cbd7c1622f97c3ccd7781952aec3b08cd44ee64a449e8f`, source
commit `fb9f84ee247a1f02b1a132da60e94585db84bf61`, ten frames at 1280x960,
`gamescope_libei_build=enabled`, `headless_gamescope_ahb=pass`, and zero
residual runtime processes. The screenshot is confirmed as a 1280x960 PNG;
the visible USB settings overlay is an Android-side dialog from the test
environment, not a presentation-ratio failure. The local evidence directory
is `android/nova-lab/build/runs/20260808T204106Z-44855/` and is intentionally
ignored by Git; `acceptance-manifest.txt` contains the artifact hashes.
