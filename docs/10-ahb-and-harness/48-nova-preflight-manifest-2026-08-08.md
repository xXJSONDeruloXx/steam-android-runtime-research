# Nova mandatory preflight manifest — 2026-08-08

## Trigger

Luna's latest parent-session audit found that linked-worktree handling and
remote `su -c` quoting were still being discovered during launch. The device
was cleaned afterward, but the first launch attempt was not protected by a
single, durable gate.

## Repair

`android/nova-lab/deploy-gamescope-headless-ahb-test.sh` now supports a
mandatory run-scoped preflight through `NOVA_REQUIRE_RUN_MANIFEST=1`.

Before the Activity starts, the preflight:

- rejects a missing or malformed run ID, a missing run directory, and reused
  generated artifacts;
- records the exact binary, APK, source, metadata, and remote command paths;
- force-stops the Nova Activity;
- runs the exact runtime cleanup and residual-process check twice;
- clears app-owned sockets/reports twice; and
- resets and reads back both AHB trace properties and rootfs trace files.

It writes `device-gamescope-headless-ahb-preflight.txt` beside the run
artifacts and only allows launch after a final
`preflight_manifest=pass run_id=...` marker. A failed gate leaves the manifest
and exits before logcat clearing or Activity launch; the exit trap still runs
the exact-scope cleanup.

The bounded acceptance wrapper now enables this gate automatically and records
the acceptance profile as the run profile. Existing ad-hoc callers retain the
legacy opt-in behavior until they provide a unique run directory and profile.

## Verification

- `bash -n android/nova-lab/deploy-gamescope-headless-ahb-test.sh`
- `git diff --check`

This is a harness repair, not a result from the pending socket-trace device
experiment. The next device run must include the preflight artifact in its
provenance and must not proceed if any reset or cleanup marker fails.
