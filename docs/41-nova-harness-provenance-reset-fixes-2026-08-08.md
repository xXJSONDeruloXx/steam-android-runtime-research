# Nova harness provenance and trace-reset fixes

Date: 2026-08-08

## Fresh-run observation

The fresh traced manual launch `legacy-20260808T224741Z-57891` stopped before
starting the device runtime. Its binary provenance was complete, but the
Gamescope source was the linked worktree
`android/nova-lab/build/gamescope-headless-source-seven`. The provenance gate
treated the worktree's `.git` file as missing and printed:

```text
gamescope_source_commit=unknown
missing required Gamescope provenance
```

The subsequent exact stop also reported
`native_steam_ahb_trace_reset=fail`. A focused root probe showed the Android
shell was executing only the first token after `su -c` as root when the command
was passed as separate arguments. `mkdir` ran as root, but the following
`printf` ran as the shell user and could not update the rootfs trace file.

## Resolutions

- The Gamescope metadata gate now asks Git for `rev-parse --git-dir` and then
  records `rev-parse HEAD`, which accepts both ordinary repositories and linked
  worktrees.
- Trace-state writes in the bounded AHB deployer and manual-session stop path
  now pass one quoted remote `su -c` command, keeping the complete `mkdir` and
  write operation under root.
- The next traced run must set
  `NOVA_GAMESCOPE_INPUT_EMULATION=enabled` explicitly so the recorded feature
  provenance is not `unset`.

The failed launch was cleaned with the exact Nova runtime helper and did not
produce a device presentation result. These harness fixes are a prerequisite
for the next trace run; no AHardwareBuffer ownership or protocol behavior was
changed in this checkpoint.
