# Parent session process audit — follow-up 4 — 2026-08-08

## Scope

- Source: `/Users/kurt/.codex/sessions/2026/08/07/rollout-2026-08-07T10-58-54-019fdcbb-f967-7153-bc2e-2a2eb9a26093.jsonl`
- Audit window: `2026-08-08T21:54:33Z` through `2026-08-08T23:54:33Z`.
- Compared with: `docs/35-parent-session-process-audit-2026-08-08.md`, `docs/40-parent-session-process-audit-followup-2026-08-08.md`, `docs/43-parent-session-process-audit-followup-2026-08-08.md`, `docs/46-parent-session-process-audit-followup-2026-08-08.md`, `docs/48-nova-preflight-manifest-2026-08-08.md`, and `docs/49-nova-ahb-socket-trace-result-2026-08-08.md`.
- Evidence references below are JSONL line numbers, not repository source lines.
- This audit is documentation-only. No source, script, README, staging, commit, or push was performed for this audit.

## Executive finding

The latest socket-trace run demonstrates that the preflight, provenance,
dynamic-target, bounded-poll, and cleanup controls can work together: the
result in `docs/49` records a passed preflight, finite 900-second launch
timeouts, dynamic X11 selection, a bounded 60-second CDP poll, and clean
post-stop state. The exact window nevertheless contains three recurring
workflow problems from the earlier audits: ad-hoc fixed-delay/generic capture
continues to appear before the run-scoped contract is used; a manual launch
still uses 86,400-second process lifetimes; and the parent resumes source
inspection immediately after starting a fresh audit handoff. These are
evidence-backed process recurrences, not claims that the final socket result
is invalid.

## Repeated findings and prioritized repairs

### 1. P1 — Fixed-delay and generic evidence collection still recurred

Early in this window, the parent launched the manual session with the prior
diagnostic profile (JSONL line `38976`), then captured to host-level
`source-compare-*` artifacts and sampled after `sleep 3` and `sleep 6`
(`39006`, `39019`, `39014`). Additional Gamescope screenshot probes used
separate `sleep 2`/`sleep 3` commands around X11 properties (`39096`,
`39104`, `39108`). This is the same fixed-delay, generic-artifact pattern
identified by `docs/35`, `docs/40`, and `docs/46`.

The later `manual-20260808T234314Z-ahbsockettrace` run improved materially:
`docs/49` records run-scoped artifacts, dynamic X11 discovery, focus checks,
and a bounded CDP poll. That improvement does not remove the earlier
unscoped samples from the parent workflow, where they remain easy to cite as
if they were part of the final run.

Repair: make run-scoped, marker-driven capture the only acceptance path. Put
input ID, CDP target/route, focus assertion, selected X11 window/geometry,
and the latest app/Gamescope marker in one record before each capture. Reject
generic host paths and fixed-delay samples, or quarantine them explicitly as
non-acceptance diagnostics.

### 2. P2 — 86,400-second manual-session lifetimes remain in use

The manual launch at JSONL line `38976` explicitly set
`NOVA_STEAM_CLIENT_TIMEOUT=86400` and
`NOVA_STEAM_GAMESCOPE_TIMEOUT=86400`. This repeats the long-lived-session
risk documented in `docs/35`, `docs/40`, and `docs/46`, even though the later
socket-trace run recorded finite 900-second values in its metadata (`docs/49`).

Repair: make every named manual and acceptance profile finite by default.
Require an explicitly named long-lived profile to provide a watchdog,
heartbeat, and automatic exact-scope teardown, and record whether teardown
was deadline- or operator-initiated.

### 3. P1 — Focus contamination remains a live precondition around diagnostics

The final run had to dismiss `com.rp.settings` and start an overlay guard
before becoming ready (`41967`). The run then passed its focus assertions and
`docs/49` correctly reports that the settings overlay did not own focus during
the evidence pair. This is an improvement, but it confirms that the focus
contamination condition from `docs/46` is still operationally possible in the
same workflow; it cannot be treated as permanently solved merely because the
guard repaired this run.

Repair: keep the guard mandatory and fail closed. Record a focus assertion
immediately before and after every root-side diagnostic, input event, and
capture; if `MainActivity` is not focused or `com.rp.settings` appears, mark
the sample invalid and re-establish focus before collecting acceptance
evidence.

### 4. P1 — Audit handoff and next source investigation still overlap

After committing the socket-trace result (`42146–42147`), the parent spawned a
fresh audit at `23:52:47` (`42162–42163`) and then resumed AHB source inspection
within seconds (`42168`, `42172`). The handoff also required repeated waits
that timed out before the audit returned. This repeats `docs/43` and `docs/46`:
the next hypothesis begins while the audit intended to police the workflow is
still in flight.

Repair: serialize the phases: stop and clean; document and publish the result;
run the audit to completion; incorporate its report; then create or inspect
the next experiment card. Do not edit or broaden protocol investigation while
the audit is pending. Use one bounded handoff/wait operation and record its
completion or timeout as part of the audit record.

## Controls that were not counted as new failures

- The linked-worktree/remote-shell issue that motivated `docs/48` was not
  observed as a failure in this window; the latest run's preflight passed
  before Activity launch.
- The latest run included APK, Gamescope, source-status/diff/submodule, and
  preflight hashes, addressing the provenance gap called out in `docs/43` and
  `docs/46`.
- The latest socket-trace result used a fresh run directory, dynamic X11
  discovery, bounded route polling, and passing cleanup/reset. Those controls
  should remain mandatory rather than being counted as repeated mistakes.

## Repair order

1. Keep the mandatory preflight/provenance/cleanup gate as a hard deployment
   prerequisite.
2. Remove fixed-delay and generic-path evidence from acceptance workflows.
3. Replace 86,400-second defaults with finite named profiles and watchdogs.
4. Treat focus/overlay assertions as mandatory around every diagnostic and
   input pair.
5. Complete each audit before beginning the next source investigation.

