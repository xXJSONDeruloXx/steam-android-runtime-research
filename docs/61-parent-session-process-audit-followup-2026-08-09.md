# Parent session process audit — follow-up 6 — 2026-08-09

## Scope

- Source: `/Users/kurt/.codex/sessions/2026/08/07/rollout-2026-08-07T10-58-54-019fdcbb-f967-7153-bc2e-2a2eb9a26093.jsonl`
- Audit window: `2026-08-08T23:05:55Z` through `2026-08-09T01:05:55Z`.
- Compared with the lifecycle contract and prior audits in docs 35, 40, 43,
  46, 50, and 55. References below are parent JSONL line numbers.
- Documentation-only audit; no device or source change was made by this
  audit.

## Executive finding

The parent correctly applied the previous audit before the next device run:
ordinary profiles rejected `86400`, the long-lived profile required a
watchdog, the post-stop verifier was added and passed, and the queue and
timeout experiments were predeclared, bounded, run-scoped, and cleanly
closed. The remaining failures are narrower but still capable of producing
misattributed evidence.

## New recurrences and refinements

### P1 — Dynamic X11 discovery is still followed by hard-coded capture

The queue run discovered `0x240003b` from the current tree at lines
`43586–43594`, then passed that literal to the baseline and post-input
captures at `43590` and `43596`. The timeout run repeated the same shape:
it discovered `0x1e0003b` at `43976`, then embedded the literal in the capture
at `43980`. This is a direct recurrence of the run-scoped target problem in
doc 55, not a harmless shorthand.

Repair: have the tree parser write `X11_WINDOW` into the run manifest and
make every capture read that value. Before capture, compare a fresh tree
lookup with the manifest ID and fail/quarantine the sample on mismatch.
Never accept a manually copied XID in an acceptance command.

### P1 — Log polling can still consume stale device records

The queue marker loop repeatedly dumps the entire retained `logcat` buffer and
selects the last matching `wait_ack` line with `tail -1` (`43603`). The saved
record shows the device log timestamp `20:49:29` while the host poll was at
`00:50:18Z` (`43617`); the PID/run identity was not part of the marker
predicate. The run had a fresh directory, but that alone does not prove that
the selected log line belongs to the current process.

Repair: capture the launched Android PID and a unique run-start marker, then
filter every poll/result by PID plus a monotonic/current-run marker. Prefer a
run-specific log stream or clear-and-record the logcat sequence baseline.
Write `marker_source_pid`, `marker_start_utc`, and `marker_freshness=pass` to
the manifest; otherwise emit `marker_timeout` and do not produce a normal
boundary result.

### P2 — Teardown still has unchecked shell steps before the fail-closed gate

After both bounded runs, the parent issued `cp ...report` and `adb forward
--remove` as separate commands without a shell-level `set -e` or explicit
status aggregation (`43658–43663`, repeated at `44003–44008`). The new
verifier subsequently checked the report/forward state and passed, so these
runs remain valid; however, a failed intermediate command can still be
misread before verification, and the workflow duplicates the helper’s
responsibility.

Repair: make one teardown wrapper perform stop, report transfer/hash,
forward removal, and `verify-nova-post-stop.sh` under `set -euo pipefail`,
with named status output for each step. The wrapper should refuse to publish
the run result unless the verifier passes; retain manual retry only as an
explicitly labelled recovery attempt.

### P2 — Parallel evidence collection does not aggregate failures

The final capture batches use `Promise.all` over shell commands and print
their output, but do not require each `exec_command` result to have a zero
exit code (`43972`, `44014`). This is efficient for read-only collection, but
it can leave a partial artifact set that looks complete until a later hash or
verifier happens to expose the gap.

Repair: use a small run-scoped collector that records each command’s exit
status and expected artifact, fails the collection on required-command
failure, and writes a machine-readable `capture_status=pass|fail` marker.

## Phase and timing assessment

No new audit/source overlap was found after the prior handoff: the parent
waited for audit 55, applied its guards, predeclared the next experiment,
published the diagnostic checkpoint, and only then ran the device tests
(`43377–43571`). The 90-second marker poll and finite 900-second run limits
were appropriate. Keep this serialized barrier, but include the X11/log
freshness and collector status in the next manifest so the improved timing
discipline cannot be undermined by stale selection.

## Repairs to carry forward

1. Make the manifest authoritative for X11 ID and reject copied IDs.
2. Correlate log markers to the current Android PID/run-start sequence.
3. Collapse report copy, forward removal, and post-stop verification into one
   fail-closed teardown wrapper.
4. Aggregate parallel capture exit statuses and required artifact checks.
