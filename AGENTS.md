# Steam Android runtime research guardrails

## Agent documentation discovery

For project orientation, start with the
[`docs/README.md`](docs/README.md) documentation map, then read the
[`current roadmap`](docs/00-start-here/06-android-linux-gamescope-roadmap.md)
before choosing work. Use the folder README files to narrow historical
evidence; current direction and acceptance boundaries belong in
`docs/00-start-here/`, while the numbered records in the other folders are
append-only experiment history.

## SteamclientTermux prior-art handoff

For Runtime 4, Proton 11 ARM64, Pressure Vessel, FEX/DXVK, route visibility,
PulseAudio, removable-library, or session-log work, also inspect the clean
sibling checkout at `/Users/kurt/Developer/steamclienttermux`. Verify its
remote, branch, and current revision with `git -C
/Users/kurt/Developer/steamclienttermux status --short --branch` and
`git -C /Users/kurt/Developer/steamclienttermux rev-parse HEAD` before using
it. Read the pinned comparison in
[`doc 333`](docs/00-start-here/333-steamclienttermux-comparison-2026-08-10.md),
then use the sibling checkout's current source for implementation details.
Borrow narrow contracts and record the source revision; do not vendor its
Steam/runtime/game payloads, copy authentication data, or silently replace
Nova's rooted Holo/direct-X11 architecture with its PRoot stack.

Before any Nova device run, read
[`docs/00-start-here/34-nova-runtime-harness-lifecycle.md`](docs/00-start-here/34-nova-runtime-harness-lifecycle.md).
It records the cleanup incident and the required regression contract.

## Run identity and cleanup

- Treat every bounded run and manual session as a separate experiment. Do not
  reuse a prior process, log tail, socket, screenshot, or readiness result.
- Run the exact-scope Nova cleanup helper before launch and on every exit,
  interruption, or manual stop. Verify that no matching Gamescope, control
  wrapper, Steam/webhelper, libei, or uinput process remains, and verify that
  no temporary mount or bridge socket leaked.
- Readiness must be based on a fresh process/log baseline from the current run,
  not merely on an existing Steam log containing a familiar line.

## Artifact provenance

- Record the exact Gamescope and Android APK artifact path, SHA-256, source
  tree/build directory, and relevant presentation/input flags for each device
  result. A release binary, diagnostic binary, and libei-enabled binary are
  different experiments even when they have the same filename.
- Keep bounded acceptance tests and long-lived manual sessions on explicit,
  separately named profiles. Do not compare their results when dimensions,
  timeouts, frame limits, or composition/input modes differ.

## Evidence discipline

- Before changing code, capture the smallest reproducer and identify which
  layer failed: Android Activity, SurfaceControl/AHardwareBuffer, Gamescope,
  Xwayland/CEF, Steam input, or Steam UI state.
- After each hypothesis is disproved or resolved, record it in the relevant
  document and commit/push the durable harness or documentation change before
  starting another long experiment.
- Do not escalate from a stale or ambiguous result. Stop, clean, establish a
  fresh run identity, and repeat the same test with one variable changed.
