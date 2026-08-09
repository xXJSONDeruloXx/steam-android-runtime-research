# Termux:X11 private-namespace client retry — 2026-08-09

Status: partial device result; the corrected X11 client entry still did not
map a synthetic window. The run isolated a capability loss in the
backgrounded `su` launch and a process-identity mismatch in teardown. The
device was manually returned to a clean exact-scope state, and the next
repair is committed with this result before another run.

## One-variable retry

This retry kept the official APK, display, rootfs, synthetic client, capture
helper, and 600-frame target from [doc 118](118-termux-x11-display-bring-up-experiment-2026-08-09.md).
The changed harness path was the run-scoped `unshare -m` helper for chroot,
plus its exact cleanup helper. It was run from repository commit `e669a67`.

```text
run_id=termux-x11-20260809T145500Z-private-namespace-display-0
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
display=:0
termux_x11_source_commit=d8013ac5d174bb16120f915c10a7255948c59c17
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_animate_sha256=884853cdc47c0d10a644153404fcd25e155b8784e24903f3ced568649b10bc04
x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

Run artifacts are under
`android/nova-lab/build/manual-runs/termux-x11-20260809T145500Z-private-namespace-display-0/`.

## Result

The Termux:X11 server gate passed and fresh Android logs again showed the
official server commit, the rootfs `TMPDIR`, Adreno EGL, the 1280x864
renderer surface, and the Activity-side XCB connection. The X11 tree still
contained only the root:

```text
nova_x11_display=pass display=:0 screen=0 root=0x511
nova_x11_window id=0x511 parent=0x0 depth=0 map_state=viewable x=0 y=0 width=1280 height=714 border=0 name="<none>" res_name="<none>" res_class="<none>"
nova_x11_tree=pass root=0x511
```

The external client stderr was:

```text
unshare: Operation not permitted
```

Because the client command was backgrounded inside the flattened
`adb shell su -c` payload, its `unshare -m` did not receive the capability
that the foreground private-namespace root probe has demonstrated on this
device. This is a launch-lifecycle failure, not evidence that the chroot
client or Termux:X11 cannot render. No synthetic window, X11 PPM, or Android
screenshot acceptance was produced.

## Teardown result

The cleanup helper removed the socket and staged files, but its first process
matcher looked at `/proc/*/comm`. On this Android build the live server was:

```text
/proc/25235/comm    = main
/proc/25235/cmdline = termux-x11
```

The helper therefore recorded no server PID and left its shell parent. The
run reported:

```text
pre_cleanup_server_pids=
pre_cleanup_client_pids=
namespace_cleanup=pass
server_state=absent client_state=absent server_parent_state=present socket_state=absent
nova_x11_cleanup=fail
```

The exact residual server tree was then removed by its recorded live PIDs
`25235`, `25234`, and `25230`, followed by a fresh process and socket check.
No Termux:X11 server, `CmdEntryPoint` process, or `X0` socket remained. This
manual recovery is included as evidence of the teardown gap; it is not a
passing automatic cleanup result.

## Repair published with this result

The harness now:

- matches the server by exact `/proc` command line `termux-x11` plus its
  Android process identity, and matches the client by this run's staged
  `nova-x11-animate-<run-id>` token while excluding shell wrappers;
- discovers and kills the server's exact shell parent before namespace file
  cleanup; and
- keeps the root `adb shell su` client command in the foreground while the
  host-side `adb` process is backgrounded, so `unshare -m` retains its root
  capability and the harness can still capture concurrently.

The next run changes only this launch/identity repair. It must pass the
synthetic mapped-window, X11 PPM, Android screenshot, and automatic teardown
gates before any Steam process is introduced.
