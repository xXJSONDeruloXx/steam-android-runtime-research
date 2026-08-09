# Termux:X11 rootfs stdio probe result — 2026-08-09

Status: completed; the rootfs character devices are present, but uid 501
cannot open them. The expected “background stdin only” pattern was rejected.
No Termux:X11 Activity, Steam process, or compositor was launched.

## Run identity and provenance

```text
run_id=termux-x11-20260809T170000Z-rootfs-stdio-probe-0
repo_commit=e64dae67da86c04c4767a720eba4b434303aa3e8
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
probe_sha256=a14e95418dabfc2e0b5c71241cf6172f9ba6c9ecc65bd8c2dbe356ff3de90d9e
runtime_cleanup_sha256=1f647219af5d3dae2e6b8d2ebc5f8ae38bfa241598a0f8d35988dd4a4371c1ed
uid_gid=501:20
termux_x11_server=not_launched
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

## Controlled result

The probe verified all six expected nodes as character devices, with mode
`crw-rw-rw-`, but every foreground/explicit access case failed:

```text
nova_stdio_case=foreground_explicit_null status=1
/bin/sh: line 1: /dev/null: Permission denied
nova_stdio_case=background_implicit_stdin status=0
/bin/sh: line 1: cannot redirect standard input from /dev/null: Permission denied
nova_stdio_case=background_explicit_null status=1
/bin/sh: line 1: /dev/null: Permission denied
nova_stdio_case=background_explicit_zero status=1
/bin/sh: line 1: /dev/zero: Permission denied
nova_stdio_case=timeout_explicit_null status=1
/bin/sh: line 1: /dev/null: Permission denied
nova_stdio_case=timeout_background_explicit_null status=1
/bin/sh: line 1: /dev/null: Permission denied
nova_stdio_case=urandom_explicit_fd status=1
/bin/sh: line 1: /dev/urandom: Permission denied
nova_x11_stdio_probe=pass pattern=unexpected nodes=0
nova_x11_stdio_statuses foreground=1 implicit=0 explicit_null=1 explicit_zero=1 timeout=1 timeout_background=1 urandom=1
```

The implicit-background status of zero is not a success: Bash reported the
failed implicit `/dev/null` open on stderr but did not propagate that async
redirection failure through `wait`. The stderr marker, not that status alone,
is the acceptance evidence.

## Device-context comparison

The rootfs nodes are labelled as generic data files despite being character
devices:

```text
crw-rw-rw- ... u:object_r:shell_data_file:s0 1,3 ... /dev/null
crw-rw-rw- ... u:object_r:shell_data_file:s0 1,9 ... /dev/urandom
```

Android’s corresponding nodes use device-specific labels:

```text
/dev/null     u:object_r:null_device:s0
/dev/zero     u:object_r:zero_device:s0
/dev/full     u:object_r:device:s0
/dev/random   u:object_r:random_device:s0
/dev/urandom  u:object_r:random_device:s0
/dev/tty      u:object_r:owntty_device:s0
```

The device was in `Permissive` mode during the read-only inspection, so the
label mismatch is an important provenance difference but is not by itself a
complete causal explanation. The controlled fact is simpler: creating nodes
under `/data/local/tmp` as root does not make them usable by the uid-501
rootfs Steam process.

## Cleanup

The exact cleanup helper passed both before and after the probe:

```text
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

The run directory contains separate stdout, stderr, and status files for every
case under:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T170000Z-rootfs-stdio-probe-0/cases/
```

## Decision and next step

Do not patch only the launcher’s stdin redirection. That would hide the
broader device-access failure while leaving Steam’s `/dev/urandom` assertion
intact. The next predeclared experiment should change only the Steam process
identity to uid 0 in the same direct-Termux:X11 profile. A root launch is a
diagnostic A/B, not the proposed product security model: if it advances to an
X11 window, the uid-501/data-rootfs device boundary is confirmed; if it still
fails, the next boundary is Steam’s loader/runtime rather than `/dev` access.
