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
