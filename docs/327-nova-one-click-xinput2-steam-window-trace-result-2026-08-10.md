# Nova one-click XInput2 Steam-window trace result — 2026-08-10

## Result

The explicit Steam-window trace reached the fresh signed-in Steam X11
session, discovered the viewable Steam Big Picture window, and queried
XInput2 version 2.0. It did not reach the event-observation phase: the X
server rejected the combined root/window selection with error code 10,
BadAccess.

This is a selection-ownership boundary, not a zero-event result. Because the
tracer reports one aggregate selection result after issuing the root and
Steam-window requests, this run cannot prove which request was rejected. It
does establish that the observer cannot claim both selections with the
requested XI2 masks while the Steam session is running. No conclusion about
whether the synthetic Android tap generated a Steam-window XI2 event is
justified from this run.

## Run identity and provenance

- Run ID:
  nova-one-click-xinput2-steam-window-trace-20260810T160142Z
- Launcher session: 20260810T160442Z-26936
- Device: Retroid Pocket Nova, Android 13, kalama, adb serial 675a2365
- Rootfs: /data/local/tmp/nova-holo-rootfs
- Branch/source commit at device launch: main /
  f6a27ebda2299b90802dbc5bf756254d990e0528
- APK SHA-256:
  0d3020eb0ba8d0fa09b168f85ba088ad3cc08932a7ad36c76bad0ab4b69f5d97
- Tracer:
  android/nova-lab/device/nova-x11-input-trace.c
- Tracer binary SHA-256:
  44809b365045ec05e0f21b4f490a01e9982e3d6ea02c59415d9a1b38cce2d371
- Device libXi.so.6.1.0 SHA-256:
  43e3de807c9a1c19b61d67145625cf64bd988800a02d3126494325e46d01bb09
- Display: Termux:X11 :0, X11 root 0x511
- Discovered Steam window: 0x1800035, viewable 1280x800,
  name Steam Big Picture Mode
- Android capture: 1280x960

The parent used the current one-click known-good profile: hardware
acceleration enabled, CEF GPU disabled, gamepadui, Steam software GL forced,
CEF environment split enabled, AudioTrack playback bridge enabled, and the
rooted controller relay enabled. The profile was not changed for this
observation.

## Fresh observation

The run started a fresh one-click session and captured the Steam window tree
before tracing. One synthetic tap was issued at (620,545) at
2026-08-10T16:06:07Z. Focus remained on
com.termux.x11/com.termux.x11.MainActivity; the before/after captures stayed
on the signed-in Steam UI and did not show a settings overlay.

The complete tracer output was:

~~~text
nova_xi2_extension=pass opcode=131 event_base=66 version=2.0 root=0x511
nova_xi2_select=fail error_code=10
~~~

The tracer exited with status 1, so there is no valid nova_xi2_trace=pass
sample count or event count for this run. Error 10 is the X11 BadAccess error
returned when the requested selection conflicts with an existing
selection/ownership constraint. The evidence therefore points at the X11
selection contract itself; it does not distinguish an exclusive Steam-window
selection from a root-selection conflict.

## Cleanup and artifact location

The run was stopped through the exact scoped helpers:

~~~text
nova_x11_cleanup=pass
nova_runtime_cleanup=pass
nova_launcher_dbus_state=absent
nova_launcher_stop=pass
~~~

The final targeted process audit was empty, final D-Bus state was absent, and
the app-owned temporary files were empty. No new input or presentation claim
is made after teardown.

Host evidence is retained under
android/nova-lab/build/runs/nova-one-click-xinput2-steam-window-trace-20260810T160142Z/.
The run directory includes artifacts-sha256.txt. Selected evidence hashes:

- xi2-trace.txt:
  2aa170b2ba19223cc72845092e6944141c930c9ba0bcf3b42df6987a0045bd34
- steam-settled-before-trace.png:
  890153e8d585059d9ee60faa9d6dff51610806c259ab05ed504cd9ec1d0544e7
- steam-after-trace.png:
  cf7c4e492539a7e1879ce78b1f7280820a1d58c1e31757209b302f0bec2b5006
- x11-tree-before-trace.txt:
  63d21a448d532e24219317224a33b6930dd34a50069b87c89d6b70b59dc17b2a
- cleanup-final-log.txt:
  6f814064d487bae9aa18aba0ebe020b8dc285d8e068682070b63d517322f686d
- process-final.txt:
  bba4ab27b4491828b6304f865228e278da2fbc6a6e2bba0a736a20b7e9fac583

## Decision

Do not promote this run to a touch-delivery pass or use it to close the
Termux:X11 input question. The immediate next experiment is the separately
predeclared Geometry Wars first-frame launch. A future XI2 revisit, if
needed, should report root and target selection errors independently; it is
not part of the next game-rendering milestone.
