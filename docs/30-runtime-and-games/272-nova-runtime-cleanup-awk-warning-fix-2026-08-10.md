# Nova runtime cleanup PID-snapshot warning fix — 2026-08-10

## Question

The Geometry Wars FROG teardown returned the required
`nova_runtime_cleanup=pass` marker, but toybox `awk` emitted
`newline in string` warnings while rendering the TERM/KILL PID snapshots.
The cleanup helper passes a newline-separated PID list through `awk -v`;
Android toybox rejects that multiline assignment even though the numeric PID
membership test is otherwise valid.

## Change under test

`android/nova-lab/device/nova-runtime-cleanup.sh` now normalizes each
newline-separated snapshot list to space-separated numeric tokens before
passing it to `awk -v`. The process selection, exact Nova rootfs scope, TERM /
KILL sequence, and pass/fail contract are unchanged.

## Verification plan

1. Run `sh -n` against the edited helper.
2. Push the helper to the attached Nova and execute it against the exact
   `/data/local/tmp/nova-holo-rootfs` scope while no Nova runtime is active.
3. Require a clean `nova_runtime_cleanup=pass` output with no toybox `awk`
   warning.

This is a harness-observability repair, not a rendering or application
acceptance result. A later fresh Nova run must still verify it during normal
teardown.
