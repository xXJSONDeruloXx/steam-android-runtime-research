# Nova one-click stop ancestor exclusion result — 2026-08-10

## Result

The ancestor-chain exclusion was not sufficient to make the one-click stop
completion contract pass. The fresh launcher logged the expanded caller list:

```text
nova_launcher_cleanup_exclude_pids=28421 28420 1032
```

but the stop command still returned `143` after preference restoration. The
runtime helper did eventually report `nova_runtime_cleanup=pass`, and the
settled process/residue audit was empty, but its snapshots still contained the
exact stop command:

```text
.../nova-one-click-root-launcher.sh stop /data/local/tmp/nova-holo-rootfs ...
```

This explains why the PID-list exclusion alone was not reliable under the
Android `adb shell` → `su` nesting: the stop process and its shell wrapper are
also discovered by the rootfs command-line matcher. The next repair adds an
exact command-line guard for `nova-one-click-root-launcher.sh stop` in the
cleanup helper. It does not suppress the separate `...root-launcher.sh start`
wrapper or any of its descendants.

## Run identity and provenance

- Run ID: `nova-one-click-stop-ancestor-exclusion-20260810T111828Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- Source commit at launch:
  `45fb86ff81b63ff5ba9808c00db8a587e2956fa3`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `7cd75bb3712882f97a9f8310814d9a2be0013056ec0853061dc07fbf41d63fba`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Presentation: direct Termux:X11, Android `1280x960`, stretched X11
  `1280x800`, extra-key bar hidden
- Steam: signed-in software/CEF profile
- Gamescope/AHardwareBuffer: not used
- Input, audio, and game launch: not exercised

Evidence is retained locally at:

```text
android/nova-lab/build/runs/nova-one-click-stop-ancestor-exclusion-20260810T111828Z/
```

## Presentation checkpoint

The direct session still produced a settled full-screen Steam frame without
the extra-key bar:

- `android-screen-settled.png` SHA-256:
  `036a50e42e55e17c955afd4695bc03fb219cf19369283043e257ffb13aa29a95`

The screenshot is retained as supporting evidence for this run's display
setup; the stop result is the authoritative subject of this document.

The live Termux:X11 preferences were set to the expected custom `1280x800`
stretch profile with both key-bar values false. After stop, the file returned
to the known baseline:

```text
during 2985d0d52b35d40d9f00dfbd6c69ca994dba3c99ef1b2c71b55fb5cf19d6ec5c
after  25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895
```

## Teardown evidence

The stop output was:

```text
nova_launcher_x11_stretch_restore=pass
nova_launcher_cleanup_exclude_pids=28421 28420 1032
Terminated
```

The final settled process audit found no matching Nova Steam, Gamescope,
uinput, libei, or launcher process, and the exact rootfs residue scan was
empty. Those are necessary safety gates but not sufficient for a product stop
pass because `nova_launcher_stop=pass` was absent.

## Decision

Retain the ancestor walk as useful diagnostics, but add the exact stop-command
line guard in `nova-runtime-cleanup.sh` and rerun the same profile under a
fresh run ID. Do not broaden the matcher to generic `sh`, `su`, or rootfs
ancestors: the start wrapper and its runtime descendants must still be
terminated and verified absent.
