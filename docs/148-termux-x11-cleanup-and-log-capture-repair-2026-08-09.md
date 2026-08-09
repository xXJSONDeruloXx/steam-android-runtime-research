# Termux:X11 cleanup and log-capture repair — 2026-08-09

Status: the first control launch used the harness's default synthetic client
because the native Steam client path was not passed explicitly; see the
[partial result](149-termux-x11-cleanup-log-capture-control-result-2026-08-09.md).
The intended native Steam control remains pending.

## Why this is next

The [procfs Steam result](147-termux-x11-native-steam-procfs-result-2026-08-09.md)
reached a viewable Steam Big Picture window, but teardown exposed two evidence
problems:

1. The cleanup helper read `/proc/$pid/cmdline` after the recorded server PID
   vanished. On Android procfs this left a `tr` child spinning until it was
   terminated manually.
2. The host copied Steam logs before waiting for the background client launcher,
   so the run directory initially missed the final client status and last
   stderr lines.

## One-variable harness repair

The cleanup helper will identify the recorded server and parent only from the
single `ps -A` snapshot path. It will no longer stream a raced
`/proc/$pid/cmdline` file. The harness will wait for its background client
launcher before copying client and Steam logs, then perform the same exact
cleanup sequence.

The Steam command, `/dev` bind, `/dev/shm` tmpfs, `/proc` bind, UID/GID,
renderer, flags, APK, display, and acceptance gates remain unchanged.

## Acceptance and interpretation

Run the same direct native ARM64 Steam profile with a fresh run ID. Accept only
if the final run artifacts include `client_status`, final stdout/stderr sizes,
and cleanup/post-stop/runtime pass markers without manual process
intervention. This is a harness-control result, not a claim of OOBE or QR
progress. If the white Big Picture surface repeats with complete logs, use
the new CEF/`steamwebhelper` evidence for the next UI experiment.
