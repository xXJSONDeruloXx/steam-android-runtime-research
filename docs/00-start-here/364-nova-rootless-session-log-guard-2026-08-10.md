# Nova rootless session/log guard — 2026-08-10

Status: guest guard implemented and statically validated; device execution is
pending ADB transport restoration.

## Contract

`android/nova-lab/rootless/nova-rootless-session-guard.py` is the rootless
counterpart to the SteamClientTermux session guard. It runs inside the Holo
guest through PRoot and provides three bounded operations:

- `preflight` checks free space and protects the two known noisy Steam/CEF log
  paths with exact `/dev/null` symlinks while Steam is stopped;
- `create-log` makes a private, timestamped session log;
- `stream` mirrors only the configured stdout budget, writes only the log
  budget, and drains remaining child output so a noisy process cannot block on
  a full pipe.

The profile records a 64 MiB session-log cap and a 1 MiB mirrored-stdout cap.
The guard does not kill processes, alter Steam authentication data, or decide
whether a run is ready; those remain the exact-scope launcher and evidence
layers.

## Validation and boundary

```text
rootless_profile_static=pass
```

The code is packaged as a rootless asset, but no device pass is claimed. The
Nova USB/ADB transport disappeared while R2 was running, before this helper
could be copied into a fresh guest baseline. The next device replay must use a
new run identity and verify the guard's cap behavior with fresh logs.
