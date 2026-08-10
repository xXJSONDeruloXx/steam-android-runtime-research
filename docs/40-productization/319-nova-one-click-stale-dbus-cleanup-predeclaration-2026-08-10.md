# Nova one-click stale system-D-Bus cleanup predeclaration — 2026-08-10

Status: predeclared; source change and device rerun are pending.

## Hypothesis

The prepared rootfs can retain `/run/dbus/system_bus_socket` and `/run/dbus/pid`
when exact teardown kills the D-Bus daemon before its client-shell cleanup
trap runs. A later APK-button launch then fails closed with
`client_dbus_system_status=fail reason=stale_socket`, even though no Nova
runtime process remains.

## Narrow fix

Extend `nova-one-click-root-launcher.sh` to remove only those two paths under
the selected Nova rootfs:

- before a new launch, after the exact runtime-present check says no matching
  Nova process is live; and
- during exact `stop`, after the rootfs process cleanup has run.

The helper must emit machine-readable absent/pass/fail markers and fail closed
if removal cannot be verified. It must not touch Android's `/run`, unrelated
rootfs trees, or any socket while a matching Nova runtime is alive. This does
not alter D-Bus configuration or client behavior; it only repairs the stale
state boundary exposed by run 318.

## Acceptance

Start from the stale-socket state retained by run 318. Build/install the fresh
APK, tap the visible `Start Steam` button with no launch extras, and require:

1. stale-D-Bus cleanup pass before Steam launch;
2. `client_dbus_system_status=pass`, fresh launcher readiness, and a visible
   signed-in Steam surface;
3. the existing default audio/relay/display markers; and
4. exact stop cleanup, an absent rootfs system-D-Bus socket/pid marker, and an
   empty matching-process audit.

The touch probe remains deferred until this lifecycle correction passes. A
successful launch from a stale socket proves recovery, not standalone rootless
operation or Gamescope product ownership.
