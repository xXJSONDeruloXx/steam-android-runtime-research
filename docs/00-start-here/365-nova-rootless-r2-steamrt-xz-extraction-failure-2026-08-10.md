# Nova rootless R2 — Android SteamRT3C extraction boundary — 2026-08-10

Status: device-side archive extraction failed; host extraction and app-UID
staging passed. No Steam runtime success is claimed from this attempt.

## Run identity

- Run: `nova-rootless-r2-20260810T230711Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rooted `:0` Steam session: preserved and not used as a source of
  authentication data
- Rootless target: app-private R2 staging under
  `files/rootless-r2-20260810T230711Z/`
- Archive: local SteamRT3C ARM64 archive
- SHA-256: `f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0`

## Result

The archive was copied to the device with its host-verified hash intact.
Attempting to stream it through Android toybox `tar` produced repeated
`not a bzip2 file` and `compressed file ends unexpectedly` diagnostics, and
the expected `VERSIONS.txt` was absent. This is an extraction-tool boundary,
not evidence that the archive or SteamRT3C itself is corrupt.

The recovery path was deliberately kept outside the rooted session:

1. Extract the same hash-verified archive on the host with XZ-aware `tar`.
2. Copy the extracted tree into an exact temporary R2 staging directory.
3. Copy that tree into the app-private rootless client directory as the
   SteamRT3C runtime.
4. Verify `VERSIONS.txt` before proceeding.

Host extraction and app-UID copy completed, including `VERSIONS.txt`. The
original toybox extraction output remains a failed sub-run; it must not be
reused as a readiness or runtime result.

## Interpretation and next step

The rootless launcher should not depend on Android toybox `tar` autodetection
for `.tar.xz` artifacts. A production provisioning path should either extract
with a bundled/verified XZ-capable helper or stage an already extracted tree
after verifying the archive and every required marker. It must report the
tool boundary explicitly and fail before activation when `VERSIONS.txt` is
missing.

The temporary device tree created for host-extracted recovery requires exact
scope cleanup after ADB is restored. Do not use a broad `/data/local/tmp`
cleanup: the rooted known-good runtime and unrelated device artifacts remain
outside this run's scope.

## Evidence boundary

This record proves only archive integrity, the toybox extraction failure, and
the host-extraction recovery staging step. It does not prove Runtime4,
Proton, native ARM64 Steam startup, audio, networking, controller input, or a
rootless QR/OOBE flow. The next replay needs a new run identity, fresh X11 and
guest logs, and the lifecycle cleanup contract.
