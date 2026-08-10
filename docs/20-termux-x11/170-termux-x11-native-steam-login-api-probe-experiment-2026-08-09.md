# Termux:X11 native ARM64 Steam login API probe experiment — 2026-08-09

Status: predeclared; no device launch or CDP observation has run for this
profile.

## Why this is next

The [lifetime result](169-termux-x11-native-steam-oobe-login-lifetime-result-2026-08-09.md)
shows that Steam remains in `WaitingForCredentials` for 180 seconds even when
the Android route is reachable and the local Steam UI transport is connected.
The shipped login bundle contains a concrete branch: its login panel renders
`#Login_WaitingForNetwork` whenever
`SteamClient.User.GetStartupUserChooserState()` is absent. That API boundary is
more specific than another timeout or compositor trial.

## Experiment boundary

Keep the same direct native ARM64 Steam profile, three focused Enter events,
software CEF flags, `chroot-dev` namespace, and 180-second client lifetime.
During the fresh session, use the existing webhelper CDP endpoint through an
exact ADB forward (`tcp:9222 -> tcp:8080`) and perform a read-only
`Runtime.evaluate` probe. Record:

- the live target URL/title and body text;
- the `typeof` values for `GetStartupUserChooserState`, `StartLogin`,
  `GetLoginUsers`, and `GetCurrentUser`; and
- the return value or error from `GetStartupUserChooserState()` when the method
  exists.

The probe must not call `StartLogin`, alter the DOM, patch the bundle, or inject
any login state. The forward is removed in the probe trap after observation.

## Acceptance and decision

Require a fresh CDP target, a recorded evaluation, the usual same-window
Android/X11 capture gates, and exact-scope cleanup. If the method is absent or
returns an unresolved value while the route is `/routes/login`, the run will
identify the concrete Steam-host API blocker. If it exists and returns a
startup state, preserve that result and inspect the next login-state method
before attempting any compatibility change.
