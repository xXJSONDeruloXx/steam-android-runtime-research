# Termux:X11 system-D-Bus profile packaging — 2026-08-09

Status: the repeatable profile is now named for handoff; this is a packaging
change, not a new device experiment.

`android/nova-lab/run-termux-x11-system-bus-profile.sh` selects the four
settings established by the successful runs:

```text
NOVA_TERMUX_X11_DBUS_SESSION=1
NOVA_TERMUX_X11_DBUS_SESSION_USER=steam
NOVA_TERMUX_X11_DBUS_SESSION_UID_RECORD=1
NOVA_TERMUX_X11_DBUS_SYSTEM=1
```

Caller-provided values still take precedence, so the no-bus baseline remains
reproducible. The wrapper delegates to the existing deployment harness and
does not alter the APK, Steam flags, presentation path, or cleanup contract.

The profile is supported by the two fresh QR/login results in
[docs/188](188-termux-x11-system-dbus-only-result-2026-08-09.md) and
[docs/190](190-termux-x11-system-dbus-repeat-result-2026-08-09.md).
