# Parent-session process-audit summary

Status: current synthesis of the parent-session audits through 2026-08-09.
The numbered audit records remain the detailed evidence archive; this page is
the operational summary.

## Current controls

Every Nova run must follow the lifecycle contract in
[doc 34](34-nova-runtime-harness-lifecycle.md): establish a fresh run identity,
clean the exact process/socket/mount scope before launch and on exit, use fresh
readiness evidence, and record artifact provenance. The bounded
[1280x960 acceptance profile](36-nova-bounded-acceptance-profile.md),
[preflight manifest](48-nova-preflight-manifest-2026-08-08.md), and
[manual-session guards](56-nova-manual-harness-guards-2026-08-09.md) are
separate profiles and must not be compared as if they were one run.

The later repairs add run-scoped X11 discovery and capture status in
[doc 62](62-nova-harness-audit-repairs-2026-08-09.md), and fail-closed CDP
forward/capture preconditions in [doc 65](65-nova-harness-cdp-forward-guard-2026-08-09.md).
The acceptance harness also validates a Gamescope source through Git itself,
so linked worktrees are valid source artifacts.

## Audit history

| Record | Durable focus |
|---|---|
| [35](35-parent-session-process-audit-2026-08-08.md) | stale readiness, failed cleanup, and missing atomic acceptance gates |
| [40](40-parent-session-process-audit-followup-2026-08-08.md) | live sessions mixed with mutable source, fixed-delay captures, and hard-coded X11 targets |
| [43](43-parent-session-process-audit-followup-2026-08-08.md) | repeated manual-session and artifact-attribution risks |
| [46](46-parent-session-process-audit-followup-2026-08-08.md) | preflight, capture, and phase-serialization risks |
| [50](50-parent-session-process-audit-followup-2026-08-08.md) | timeout, cleanup, focus, and evidence-correlation gaps |
| [55](55-parent-session-process-audit-followup-2026-08-09.md) | finite timeouts, path validation, polling, teardown, and phase barriers |
| [61](61-parent-session-process-audit-followup-2026-08-09.md) | hard-coded X11 identity, stale-log correlation, teardown, and capture status |

## Working rules

- Stop and clean a device session before changing its source or build artifact.
- Build from an explicitly identified tree and record source commit, patch state,
  binary hash, APK hash, profile, and feature markers together.
- Use current-run markers and process identity for readiness; an old Steam log or
  familiar UI line is not evidence for a new run.
- Use dynamic X11/CDP target discovery and run-scoped output paths; fixed IDs,
  generic `current-*` files, and wall-clock sleeps are diagnostic hints only.
- Treat a failed preflight, patch check, timeout, or post-stop verifier as a
  failed experiment, not as partial evidence to carry into the next one.

The detailed experiment results remain intentionally immutable historical
evidence. This summary is the place to update when the harness contract changes.
