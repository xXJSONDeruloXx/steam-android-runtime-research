# Nova rootless R3 — PRoot IPC boundary — 2026-08-11

Run: `nova-rootless-r3-20260811T040543Z`
Sub-run: `R3a-native-steam-version`
Status: native Steam gate failed before UI; the next one-variable replay is
predeclared by the supervisor change in this commit.

## Gates that passed

- APK installed: `e4fa393a018e2b35311a124848e6e17a852ce2c54d3f72a85b9f4084e4fa6830`.
- Fresh Termux:X11 `:77` process: PID `7828`, UID `10129`.
- Fresh loopback listener: TCP port `6077` (`0x17BD`).
- App-UID route shadow:
  `nova_rootless_proc_net=pass ... default_route=absent`; the connected
  `wlan0` route was present, but no UID-visible default route was fabricated.
- App-private PRoot staging matched all selected hashes.
- Guest identity: `uid=0(root)` through PRoot; architecture: `aarch64`.
- Clean Valve ARM64 seed rebase/extraction: `55` entries, `r3_seed_rebase=pass`,
  `r3_seed_extract=pass`.

## Staging-only observations

The first `adb push` attempt failed because nested root-owned staging
directories had not been created. The retry also demonstrated that the
directories must be temporarily writable by the `shell` UID before the exact
files are pushed and then mode-locked. No runtime was launched during either
copy failure.

The first guest invocation copied the PRoot loader as mode `0644`; PRoot then
reported `execve("/usr/bin/env"): Permission denied`. Changing only that
app-private loader to executable mode (`0755`) made the guest `id` and
`uname -m` gates pass. The R3 staging contract must preserve executable mode
for the loader, not only for the PRoot binary.

## Native Steam result

The first native ARM64 command was:

```text
/opt/nova-steam/steamrtarm64/steam --version
```

It reached Steam Tier0 initialization but produced no version and no UI. The
fresh output included:

```text
src/tier0/threadtools.cpp (2526) : Assertion Failed: Function not implemented
src/tier0/threadtools.cpp (2121) : Assertion Failed: semaphore creation failed No such file or directory
src/steamexe/steamglobalinstance.cpp (384) : m_NamedPipe >= 0
src/tier0/threadtools.cpp (1951) : Thread synchronization object is unuseable
```

The current supervisor invoked stock Termux PRoot without `--sysvipc`. The
installed PRoot advertises a `--sysvipc` mode, and the clean comparison
checkout records SysV semaphore/shared-memory and robust-list emulation as a
required Steam compatibility boundary. The supervisor now adds `--sysvipc`
to every bind combination. This is a narrowly scoped hypothesis test; it does
not claim that the stock binary contains the comparison project's robust-list
patch set.

The failed Steam invocation left a PRoot wrapper attached to the exact R3
command after Steam exited. The wrapper was terminated by exact PID after
verification; no process with the R3 path remained. The X11 listener remains
intentionally alive for the next R3 sub-run.

## Evidence boundary

R3a does not prove Steam UI, QR/OOBE, Runtime 4, Proton 11, Vulkan, WSI,
audio, networking inside Steam, controller input, or a game frame. The next
sub-run may change only the PRoot IPC flag and must repeat the fresh guest and
native Steam gates before any broader runtime or display change.
