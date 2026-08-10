# Nova runtime cleanup PID-snapshot warning fix result — 2026-08-10

## Result

The cleanup helper repair passed on the attached Retroid Pocket Nova while no
Nova runtime was active. The exact rootfs-scoped helper returned:

    nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=

There were no toybox `awk` warnings, no matching Nova/Gamescope/Steam/input
processes, no rootfs `/tmp` sockets, and no staged helper remaining after the
check. The two baseline rootfs `/run/udev` sockets remained unchanged.

This verifies the snapshot-format repair, but it does not replace a fresh
normal Gamescope teardown check. The next bounded rendering run must verify
the warning-free path while terminating a real process tree.

## Run identity and artifacts

- Run ID: `nova-runtime-cleanup-awk-fix-20260810T20260810T094534Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Helper: `android/nova-lab/device/nova-runtime-cleanup.sh`
- Helper SHA-256:
  `9db2931fb25ccddfce43441be024e879f0dce4b4852ad77b10787a52c9cdfd0f`
- Evidence directory:
  `android/nova-lab/build/runs/nova-runtime-cleanup-awk-fix-20260810T20260810T094534Z/`

The run records the helper output, before/after process tables, rootfs socket
inventories, and staged-helper removal check.
