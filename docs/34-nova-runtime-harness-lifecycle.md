# Nova runtime harness lifecycle hygiene

Status: resolved in the harness on 2026-08-08; keep this as a regression gate.

## Incident

During the fullscreen Steam input loop, a manual-session stop killed the named
`gamescope-headless`, libei, and uinput processes but left the Steam tree under
`/data/local/tmp/nova-holo-rootfs/opt/nova-steam` alive. A subsequent launch
could therefore satisfy readiness checks from old `steamui_html.txt` and
`webhelper_js.txt` lines while the new Activity's SurfaceView was still gray.
The same cleanup shape could leave a shell wrapper for
`gamescope-headless-ahb-control.sh` or a reparented Gamescope descendant alive.

The incident was made harder to recognize because the manual launcher allowed
the Gamescope binary to be selected implicitly. The bounded run and the
long-lived run could therefore use different locally built artifacts. The
successful historical long-lived report initialized libei, while the failing
current binary reported that it was built without libei; this was a provenance
gap in the harness, not evidence that the two runs were equivalent.

## Harness contract

Every Nova run must satisfy this sequence:

1. Stop only the prior Nova runtime, identified by the exact rootfs and Nova
   driver launch paths.
2. Force-stop the test APK and remove its stale bridge sockets.
3. Launch the selected artifact and record its path, SHA-256, and relevant
   input/presentation mode.
4. Readiness must be based on fresh process/log baselines from that launch.
5. On bounded completion, interruption, or manual-session stop, terminate the
   same Nova process tree and verify that no matching process remains.

The cleanup scope must not become a broad `pkill`: unrelated Android services,
other rootfs experiments, and the host shell are outside this test's authority.

## Implemented fix

`android/nova-lab/device/nova-runtime-cleanup.sh` now:

- matches the exact Nova rootfs Steam launcher and Nova Gamescope/input paths;
- walks descendants so chrooted children whose argv no longer contains the
  rootfs path are included;
- sends TERM, waits, sends KILL to any exact-scope remainder, and verifies the
  final process set;
- is idempotent and emits a machine-readable `nova_runtime_cleanup=pass`
  marker.

The bounded AHardwareBuffer deploy path runs the helper before launch and after
report capture. The manual-session and controller smoke-test stop paths use the
same helper instead of maintaining separate partial process-name lists.

The follow-up hardening closes three less obvious lifecycle gaps:

- `stop` performs exact-scope cleanup even when the local PID file is already
  missing, so an interrupted launcher cannot make a live runtime look absent;
- cleanup push/command failures and a non-pass helper marker now fail visibly
  in the manual/controller logs instead of being swallowed by `|| true` or a
  trap; and
- the bounded deploy path force-stops the APK and removes its app-owned bridge
  sockets and reports before launch and again on teardown, then prints the selected Gamescope
  metadata (path, SHA-256, source/build identity, libei marker, and
  presentation/input flags) into the run log.

These checks are intentionally separate from exact process cleanup: a clean
process table does not prove that an old app socket or a different Gamescope
artifact was not reused.

The first run of this contract also caught an Android shell portability issue:
passing `run-as PACKAGE sh -c` as separate `adb shell` arguments flattened the
`-c` payload under the device shell, producing toybox `rm`/`sh` errors. App-file
cleanup and its residual check now pass one quoted remote command string, and a
failed cleanup remains a hard gate.

The next bounded run caught the complementary teardown case: the app's fresh
`dmabuf-double-buffer-report.txt` was valid evidence but would have become a
stale input on the next run if it remained in app storage. The deploy path now
pulls that report before teardown and then removes it, so the acceptance gate
can require an empty app-owned runtime-file set after every exit.

The first committed manual-session stop after the live input run returned
`remaining=10553` while Gamescope was still exiting; an immediate exact helper
rerun returned `nova_runtime_cleanup=pass` with no residual processes. The
device helper now performs up to three TERM/KILL/recheck cycles in one stop,
and manual/controller teardown reports app-file cleanup separately. A
transient process-exit race therefore remains visible while no longer causing
the next experiment to inherit a half-dead runtime.

The manual controller path also now applies the Android settings-overlay
focus check at readiness, not only around bounded screenshots. This closes the
observed case where `com.rp.settings` owned the USB chooser and consumed the
operator's real D-pad/touch input before Steam received it.

The OOBE compatibility patcher was then observed spending minutes in toybox
`awk` while rewriting a single 14 MB minified Steam bundle. Its substring-based
rewrite was effectively quadratic for Android's one-line input. The patcher now
uses a streamed, escaped `sed` substitution and keeps the old temp-file,
checksum, and post-write verification contract. The verifier treats the
awaited callback as a deliberate substring exception, and startup removes only
this patcher's stale temp suffix after an interruption. A future bundle-size or
patch latency regression should be treated as a harness failure, not allowed to
look like a Steam readiness timeout.

The next manual run exposed a separate false-positive in the patcher's
idempotence gate. The bundle still contained the exact update callback
`function Gm(...){...const n={};t(n)}`, but a generic search for `t(void 0)`
matched unrelated minified code and reported the file as already patched. The
no-restart patch now matches the complete `Gm` callback before declaring either
the old or new form, so an unrelated occurrence cannot mask a missed rewrite.

## Evidence and regression check

The original bad state was reproduced by a fresh app session with a gray
SurfaceView and a stale rootfs Steam process. After the cleanup change, stopping
the live session and querying the exact runtime patterns returned no remaining
Gamescope, control-wrapper, Steam, or input-relay process. The helper is also
run by every subsequent bounded launch, so a failed experiment cannot become
the hidden prerequisite for the next one.

If a future run reports gray output or stale Steam readiness, inspect the
cleanup marker and the launch artifact identity before changing presentation,
input, or Steam code.
