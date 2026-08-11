# Nova rootless session/log guard — 2026-08-10

Status: guest guard implemented and statically validated; device execution is
pending ADB transport restoration.

## Contract

`android/nova-lab/rootless/nova-rootless-session-guard.py` is the rootless
counterpart to the SteamClientTermux session guard. It runs inside the Holo
guest through PRoot and provides four bounded operations:

- `preflight` checks free space and protects the two known noisy Steam/CEF log
  paths with exact `/dev/null` symlinks while Steam is stopped;
- `create-log` makes a private, timestamped session log;
- `stream` mirrors only the configured stdout budget, writes only the log
  budget, and drains remaining child output so a noisy process cannot block on
  a full pipe;
- `crash-mode` normalizes the optional PRoot crash-trace setting without
  allowing an inherited `0` value to enable tracing accidentally.

The profile records a 64 MiB session-log cap and a 1 MiB mirrored-stdout cap.
The guard does not kill processes, alter Steam authentication data, or decide
whether a run is ready; those remain the exact-scope launcher and evidence
layers.

The guard also exposes the target-derived `crash-mode` normalization used by
the launcher boundary and opens the canonical log with a descriptor above
standard input/output/error. Truncation markers are included inside the
configured cap, and the remaining child output is drained after either sink
reaches its limit.

## Validation and boundary

```text
crash0=disabled
crash1=enabled
guard_cap_test=pass log_bytes=256 stdout_bytes=256
rootless_profile_static=pass
```

The code is packaged as a rootless asset and its cap behavior was exercised on
the host with 256-byte test sinks. No device pass is claimed. The Nova USB/ADB
transport disappeared while R2 was running, before this helper could be
copied into a fresh guest baseline. The next device replay must use a new run
identity and verify the guard in the Holo guest with fresh logs.
