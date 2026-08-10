# Parent session process-audit follow-up 3 — 2026-08-08

## Scope

- Source: `/Users/kurt/.codex/sessions/2026/08/07/rollout-2026-08-07T10-58-54-019fdcbb-f967-7153-bc2e-2a2eb9a26093.jsonl`
- Parent session: `019fdcbb-f967-7153-bc2e-2a2eb9a26093`
- Audit window: `2026-08-08T21:20:00.054Z` through `2026-08-08T23:20:00.054Z`
- Compared with: `docs/10-ahb-and-harness/35-parent-session-process-audit-2026-08-08.md`, `docs/10-ahb-and-harness/40-parent-session-process-audit-followup-2026-08-08.md`, and `docs/10-ahb-and-harness/43-parent-session-process-audit-followup-2026-08-08.md`.
- Evidence references below are JSONL line numbers, not repository source lines.
- This report is a fresh sidecar audit. It is documentation-only and was not staged, committed, or pushed by this audit.

## Executive finding

The parent materially improved experiment discipline in the final part of the
window: the `legacy-20260808T225322Z-ahbtrace` and
`legacy-20260808T231050Z-ahbseqpacket` runs used unique directories, fresh
focus/readiness evidence, dynamic X11 discovery, immutable artifact metadata,
and passing cleanup/reset markers. The seqpacket result is therefore a useful
negative transport checkpoint.

The recurring weakness is that these controls are still being discovered and
repaired during the workflow rather than enforced before it. A traced launch
was rejected because the linked-worktree `.git` representation was not
handled, and a trace reset probe exposed incorrect remote-shell quoting
(`40422–40476`). Earlier in the same window, fixed-delay/generic capture
workflows, stale X11 IDs, and a root diagnostic that stole Android focus again
contaminated evidence (`39807–39868`). These are the same classes of risk
identified by audits 35, 40, and 43, although the final seqpacket run shows
that the parent is converging on the required contract.

## Prioritized findings

### 1. P0 — The pre-run gate is still not a complete preflight

At `22:50:21Z` the traced launch reached the harness only to discover that
the linked Gamescope worktree had `.git` as a file rather than a directory
(`40422`). At `22:52:01Z`, a second probe found that Android shell flattening
of a multi-command `su -c` invocation caused only `mkdir` to run as root while
the trace write ran as the shell user (`40476`). The parent then patched,
committed, and pushed both fixes before the next run (`40504`). The failed
attempt did tear down cleanly, so this is primarily a gate-ordering defect,
not evidence of a leaked device process.

This repeats audit 43's atomic pre-publish/pre-deployment concern. A future
artifact can still pass local-looking checks and fail only when the real
deployment shell or linked-worktree layout is exercised.

Repair: make a single host-side preflight command validate every actual launch
operation before starting a session: `git rev-parse --git-dir` for linked
worktrees, source status/diff/submodule digests, binary/APK hashes and feature
markers, the exact remote `su -c` reset/write command, and a double cleanup
probe. Refuse deployment unless the command prints one complete pass manifest.
Keep the preflight result beside the run ID and include the exact command
variant tested.

### 2. P1 — Fixed-delay and generic capture workflows still recur before the run-bound capture contract is applied

The parent used generic `current-oobe-*` captures and persistent Steam log
tails early in the window, with repeated `sleep 2/3/4/5/6` sampling around
CDP and screenshots. During the X11 diagnostic, the transition command used
hard-coded `WINDOW=0x240003b` and fixed `+3s/+12s/+27s` captures
(`39800` and surrounding records). A shell-loop quoting error then produced
an invalid `sleep "3 3s"` sample that was discarded (`39807`). This repeats
audits 35 and 40's stale/fixed-delay evidence concern.

The parent did later rediscover X11 targets and correlate CDP/X11/Android
under unique run directories. That improvement does not remove the risk from
the earlier samples: discarded files and generic paths remain easy to
accidentally cite, and a delay does not identify the frame or ACK being
observed.

Repair: make the run helper reject generic output paths and hard-coded XIDs.
Have each capture record the run ID, target-window discovery output, input
event ID, CDP route, and the latest app/Gamescope frame marker. Replace
sleep-based capture phases with bounded polling on those markers; if a marker
does not arrive, record a timeout and do not create a normal-looking image
artifact. Keep invalid samples in a clearly named quarantine directory or
delete only the exact files after recording why they were rejected.

### 3. P1 — Root-side diagnostics can still change the experiment under test

Repeated root-shell capture commands brought the Nova settings USB chooser
(`com.rp.settings`) to the foreground and intercepted later A events
(`39841`). The parent dismissed it and verified focus before repeating the
transition; the clean retry then reproduced the actual presentation stall
(`39868`). The later overlay guard is a good repair, but the incident shows
that read-only evidence collection was not behaviorally read-only in the
active harness.

Repair: require a focus/overlay assertion immediately before every input and
again after every root-side diagnostic command. Make capture helpers run in a
device namespace/path that cannot launch or foreground Android settings, and
fail closed if `dumpsys input` reports anything other than the recorded
`MainActivity`. Store the focus assertion next to the input command, not only
in commentary.

### 4. P1 — Build and audit work are still interleaved through long-lived subprocesses

The parent correctly stopped the device before source edits in the final
sequence, but it still launched the APK build and Gamescope build together
(`40942`) and polled the long-running Gamescope
build with many independent waits through `23:08`. It then started a fresh
sidecar at `23:19:35Z` (`41330`) and immediately continued protocol source
inspection (`41336` onward). This is less dangerous than mutating a live device artifact,
but it makes the audit and experiment boundary moving: the sidecar is auditing
a session that continues to define the next hypothesis while the audit is in
flight.

Repair: serialize the workflow into explicit phases: stop/clean; build one
immutable artifact tuple; verify it; run one bounded device experiment;
stop/clean; document/publish; then launch the audit and pause new source
changes until its report is incorporated. Wrap parallel builds in one
supervisor that records each exit code, source tree, build directory, and
artifact hash before returning success. Avoid repeated blind `write_stdin`
polls; use one bounded wait and a final manifest check.

### 5. P2 — Manual sessions retain unnecessarily long lifetimes

The fresh manual launch still used `NOVA_STEAM_CLIENT_TIMEOUT=86400` and
`NOVA_STEAM_GAMESCOPE_TIMEOUT=86400` (`38084` and nearby tool records). The
parent manually stopped each run and cleanup passed, but this repeats audit
35's long-timeout concern and leaves a failed shell or lost continuation able
to keep Steam/Gamescope alive for a day.

Repair: use a finite timeout in every named acceptance/manual profile and let
the launcher own the deadline. Reserve long-lived sessions for an explicitly
named manual profile with a watchdog, heartbeat, and automatic exact-scope
teardown. Report the deadline and whether the stop was timeout- or
operator-initiated.

## What improved and should be preserved

- The final traced runs used unique run directories and same-run provenance.
- X11 windows were dynamically rediscovered, rather than assumed from a
  previous run, in the final evidence.
- The parent recorded APK, Gamescope, source status/diff/submodule, libei, and
  input-mode metadata before the seqpacket deployment (`41062` and following
  records).
- The seqpacket run remained one-variable and produced a useful negative
  result; no ownership/ring change was stacked onto it.
- Runtime cleanup, app-file cleanup, and trace reset all passed before the
  result was documented and published (`41336` context and the resulting
  `docs/45` report).

## Repair order for the parent

1. **P0:** Turn the linked-worktree and remote-shell checks into a mandatory
   preflight manifest that runs before any deployment or experiment.
2. **P1:** Make capture helpers marker-driven and run-scoped; reject generic
   paths, fixed XIDs, and fixed-delay evidence.
3. **P1:** Enforce focus/overlay assertions around every root diagnostic and
   input event.
4. **P1:** Serialize sidecar handoff, build completion, source inspection, and
   the next experiment card behind explicit phase gates.
5. **P2:** Replace the 86400-second manual-session defaults with finite named
   profiles and an owned watchdog.
