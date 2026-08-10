# Nova one-click X11 stretch incomplete acceptance — 2026-08-10

## Classification

This run is not a product acceptance result. It did prove that the new
launcher wrote the intended Termux:X11 profile and that Termux:X11 applied a
fresh 1280×800 buffer, but the run identity and teardown gates were invalid:

- the readiness poll accepted a stale `/data/local/tmp/nova-android-launcher/ready`
  marker immediately (`ready=1 poll=0`) from the previous session;
- the external test stop used `am startservice` against the app's non-exported
  service and Android rejected it with `Requires permission not exported from
  uid 10121`; and
- the root-side runtime cleanup invoked during preflight matched its caller
  wrapper, terminated the wrapper, and left the newly applied preference backup
  pending until an exact manual restore.

The test therefore does not claim fresh Steam readiness, clean stop, or final
preference restoration from its own stop path. The later manual recovery
restored the original XML and mode exactly.

## Useful partial evidence

The run's during-session preference file was:

- owner/group/mode `10120:10120:660`;
- `displayResolutionMode=custom`;
- `displayResolutionExact=1280x800`;
- `displayResolutionCustom=1280x800`; and
- `displayStretch=true`.

Termux:X11 logged a fresh `window changed: 1280 800 builtin` and subsequently
sent/received 1280×800 buffers. This supports the intended geometry change,
but it is not enough to accept the one-click lifecycle because the session
baseline was stale and the Android screenshot was not tied to a fresh
readiness token.

## Run identity and artifacts

- Run ID: `nova-one-click-x11-stretch-20260810T095417Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- APK SHA-256:
  `b5e21517b02125bccffa813f6a46b97e0c94ba4a0e45fecb2fc8bbcf7752575d`
- Before preference SHA-256:
  `25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895`
- During preference SHA-256:
  `0989cb3336c9bf61b06213a01176a81c206b8b80458358be81527c5df20fef50`
- Evidence directory:
  `android/nova-lab/build/runs/nova-one-click-x11-stretch-20260810T095417Z/`

The original preference was restored manually from the run-scoped backup,
with final owner/group/mode `10120:10120:660` and the original SHA-256. The
rootfs runtime and temporary Steam artifacts were then cleaned by exact paths.

## Required fixes before retry

1. Clear or rotate the launcher readiness/state identity before starting, and
   require a new session token plus a fresh `ready` write before polling.
2. Route stop through the same root launcher command used by the APK service,
   or add a product-owned exported stop entry point; do not use an invalid
   external `startservice` shortcut.
3. Restore the Termux:X11 preference backup before invoking a runtime cleanup
   helper that may see the launcher caller in its exact rootfs match set, and
   exclude the launcher/stop wrapper PIDs from that cleanup without excluding
   their actual Nova descendants.
