# Termux:X11 explicit cleanup-phase repair — 2026-08-09

Status: harness repair; no device launch was performed for this change.

## Why this is needed

The phase marker added in doc 127 still allowed a preflight cleanup attempt to
report a root process as the current run's X11 client. That result was
conservative—the device had no Termux:X11 server, client, or X0 socket—but it
blocked the next Android-screen experiment before the display was started.

The marker itself is useful after launch, but it is not a sufficient preflight
boundary when Android shell and Magisk wrapper processes can briefly carry the
run's staged client path.

## Repair

`nova-termux-x11-cleanup.sh` now receives an explicit phase:

- `preflight` disables client-token matching unconditionally while retaining
  exact server, parent, socket, and staged-file cleanup;
- `runtime` enables the root client-token match only when `client-active=1`;
- `verify` derives the same client-matching decision from the final state file.

The host deploy script passes `preflight` before APK/server launch and
`runtime` from the exit trap. The helper prints the selected phase and matching
mode in its machine-readable cleanup output.

This preserves the cleanup contract without asking preflight to infer whether
a process containing a future client path is actually a live X11 client.

## Next experiment

After this repair is committed and pushed, rerun the already predeclared
Termux:X11 Android-screen capture profile with a fresh run ID. Acceptance still
requires, in order:

1. a clean explicit preflight;
2. a live Termux:X11 socket and Activity;
3. a mapped synthetic X11 window;
4. a physical `adb exec-out screencap -p` artifact; and
5. exact runtime cleanup and post-stop verification.

The earlier X11-side `XGetImage` failure remains observational for this profile
and must not be silently promoted to a pixel pass.
