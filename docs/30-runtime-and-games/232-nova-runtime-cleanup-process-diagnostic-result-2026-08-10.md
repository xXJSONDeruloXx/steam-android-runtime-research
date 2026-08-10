# Nova runtime cleanup process diagnostic result — 2026-08-10

Status: preflight rejection explained; the cleanup matcher was catching transient
Magisk policy-log wrapper processes, not Nova runtime descendants.

This is the result for the predeclared [run 231](231-nova-runtime-cleanup-process-diagnostic-2026-08-10.md).

## Run identity and artifacts

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `nova-runtime-cleanup-process-diagnostic-20260810T065951Z`.
- Run directory:
  `android/nova-lab/build/runs/nova-runtime-cleanup-process-diagnostic-20260810T065951Z`.
- Cleanup snapshot implementation: commit `2daf17b`.
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`.
- APK SHA-256:
  `4c2bdf1f23ac617036cdcbee3195ac9adb60acbf9eff8bd58cb91dbe9277a373`.
- AHB metadata SHA-256:
  `630323125e8fd4db052bd46e4665e84de6e8082e4586df750d37cf1a425bfe42`.
- Preflight manifest SHA-256:
  `79c176b69bc867d6498f30836264151d9467a40121c55b8573921d677ab582ee`.

The artifact identity and libei setup markers passed, but the run stopped before
Gamescope/AHB or Steam launch as required.

## Diagnostic evidence

The new snapshots showed matching PIDs with these command lines:

```text
app_process /system/bin com.android.commands.content.Content call ... --command:s:cp /data/local/tmp/nova-gamescope-stage/nova-steam-network-api-compat.sh /data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver/nova-steam-network-api-compat.sh; chmod 755 ...
app_process /system/bin com.android.commands.content.Content call ... --command:s:cat /data/local/tmp/nova-holo-rootfs/tmp/nova-eis-touch.log ...
```

The latter `cat` wrapper was regenerated between cleanup attempts because the
outer touch helper was actively polling the same log while its nested AHB test
ran preflight. The wrapper contains the root path in its `--command` argument,
so the existing `index(args, root)` rule classified it as a Nova runtime process.
It is not a chrooted Gamescope, Steam, webhelper, relay, or bridge process.

This accounts for all observed behavior:

- the cleanup helper saw a new matching PID during each three-cycle pass;
- the external residual audit passed after the polling call completed; and
- the outer final cleanup passed once the wrapper stopped polling.

The Android touch/libei setup markers remain setup-only. No touch event, Steam
surface, AHB frame, or fullscreen presentation was produced.

## Decision

The cleanup matcher should retain exact Nova launcher/descendant matching while
excluding the specific `com.android.commands.content.Content` policy-log wrapper
class. The same exclusion must be applied to the external residual audit so both
checks use the same process scope. Then rerun the fixed-input preflight under a
new run ID; only a clean manifest may allow the compositor test to proceed.
