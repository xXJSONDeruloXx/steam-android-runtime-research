# Nova rootless supervisor contract — 2026-08-10

Status: implementation checkpoint; host-static validation passed, device R0
replay pending.

## Scope

This checkpoint turns the rootless predeclaration into an executable boundary
without touching the signed-in rooted session. The new profile lives under
`android/nova-lab/rootless/` and is separate from the rooted APK launcher.

The profile records the pinned Holo runtime, direct Termux:X11 package closure,
official Steam ARM64 seed, SteamRT3C snapshot, Proton 11 and Runtime 4 App IDs,
and the no-auth-copy policy. It is metadata only; no Steam, Proton, runtime, or
PRoot binary is committed.

## Implemented contract

`nova-rootless-proot-supervisor.sh` now:

- requires an Android app UID and fails if its real UID is root;
- verifies the Holo ARM64 loader and `/usr/bin/id`, the external PRoot loader,
  the PRoot dependency directory, state directories, free space, and optional
  X11 socket;
- sets `PROOT_LOADER`, `PROOT_TMP_DIR`, and an app-private `TMPDIR` explicitly,
  avoiding the Termux-only default that caused the first R0 failure;
- binds only app-owned home, Steam-client, `/tmp`, and `/run` directories into
  the guest, leaving the immutable Holo rootfs untouched; and
- executes the guest command as argv after `--`, so Steam URLs and paths cannot
  become shell syntax.

The profile uses a fresh app-owned home and client tree. It does not copy or
inspect the rooted Steam home, authentication files, or current session logs.
The supervisor has no `su`, `chroot`, mount, DRM, KMS, or uinput escape hatch.

`nova-rootless-transport-probe.sh` is read-only and fail-closed. It requires
the Termux:X11 package and an explicitly reachable, non-root-owned X11 socket;
it excludes the rooted `/data/local/tmp/nova-runtimes` and legacy rootfs socket
paths from evidence. A package being installed alone is not treated as a
rootless display result.

## Validation

The host check passed:

```text
rootless_profile_static=pass
```

It verified shell syntax, required profile pins, the Runtime 4 dependency, the
authentication policy, and the absence of privileged escape commands in the
supervisor. This does not yet prove that the Android UID can execute the
profile or connect to X11; those are the next fresh R0/R1 runs.

## Next boundary

Stage the official PRoot package and its three dependency libraries into a new
run-specific app-owned directory, invoke the supervisor through `run-as`, and
run `id`, `uname`, and an app-home write probe. Preserve the rooted session and
clean only the exact rootless staging path on exit. If R0 passes, run the
transport probe separately; do not launch a second Steam client until a
rootless-readable X11 socket exists.
