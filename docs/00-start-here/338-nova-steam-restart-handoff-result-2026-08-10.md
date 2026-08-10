# Nova Steam restart handoff result — 2026-08-10

Status: the truthful update adapter passed its intended boundary; the next
blocker is the direct-client session lifecycle. This record predeclares the
bounded restart-handoff experiment before another device run.

## Observed result

The fresh direct Termux:X11 session used the current one-click profile,
including the existing network compatibility rewrite, SteamOS flags, software
CEF path, audio bridge, and system/session D-Bus setup. The only updater change
was the truthful `steamos-update` compatibility helper from record 337.

The device evidence showed:

```text
nova_steamos_update_operation=capability
nova_steamos_update_status=0
nova_steamos_update_args=--supports-duplicate-detection
nova_steamos_update_operation=apply
nova_steamos_update_status=7
nova_steamos_update_message=No update available
```

Steam then recorded the normal OOBE completion handoff:

```text
SteamUI: WARNING: SetOOBEComplete
SteamUI: WARNING: Restarting Steam
SteamUI: ERROR: Uncaught (in promise) Error: WHEN_CANCELLED
```

On the observed relaunch, the Steam child returned status `42`. The wrapper
then ended normally, and the Android launcher tore down X11 and D-Bus. A later
tap started a new session at OOBE and repeated the same sequence. This is why
the current flow cannot reach the login/QR page: Steam is requesting an
in-session restart, but the wrapper interprets that handoff as the end of the
whole session.

This result does not show that the updater helper is asking Android to shut
down. It shows that the helper has moved Steam past the previous update error
and exposed the missing Steam restart lifecycle.

## Predeclared experiment: one bounded in-session restart

The client wrapper now:

1. records the byte offset of `webhelper_js.txt` before each Steam attempt;
2. waits for the child to exit and searches only newly appended bytes for
   `SteamUI: WARNING: Restarting Steam`;
3. relaunches the same Steam executable with the same flags, environment,
   X11 display, and D-Bus buses when that fresh marker is present;
4. allows at most one automatic restart (`NOVA_TERMUX_X11_STEAM_RESTART_LIMIT=1`);
5. leaves timeouts, missing/rotated evidence, and unrelated exits alone.

The second attempt uses separate stdout/stderr files so the first handoff is
not overwritten. The launcher passes and logs the one-restart limit explicitly.

No SteamUI bundle patch, network patch, updater status, rendering flag, audio
flag, or input flag changes in this experiment. Gamescope/AHardwareBuffer
remains outside the path.

## Acceptance

The next fresh run must show, in one launcher session:

```text
client_restart_request=detected
client_restart_attempt=1
client_attempt=2
```

The second Steam attempt must remain alive at the login/QR page or proceed
past it. If the second attempt requests another restart, the bounded limit
must end the session with `client_restart=exhausted` rather than loop.

The run remains subject to the exact-scope Nova cleanup and fresh-log evidence
requirements in
[`34-nova-runtime-harness-lifecycle.md`](34-nova-runtime-harness-lifecycle.md).
