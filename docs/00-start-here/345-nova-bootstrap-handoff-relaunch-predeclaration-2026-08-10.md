# Nova bootstrap handoff relaunch predeclaration — 2026-08-10

Status: predeclared before the next destructive device run. This experiment
changes only the direct Termux:X11 Steam client handoff and the truthful APK
status text; it does not change Steam's updater, OOBE views, network adapter,
Gamescope, or AHardwareBuffer path.

## Hypothesis

On a clean Steam seed, the native bootstrapper can finish successfully and
create `package/steam_client_*_linuxarm64.installed`, then exit before the
normal SteamUI restart marker is written. The existing launcher tears down the
otherwise healthy X11 session at that point, making a normal update handoff
look like a crash and requiring a second **Start Steam** tap.

## Change under test

`nova-termux-x11-steam-client.sh` records whether an installed-client marker
was present before the first attempt. It performs at most one automatic
relaunch only when:

- bootstrap was allowed for this launch;
- the marker was absent before launch;
- the client did not time out; and
- a matching installed-client marker exists after the client exits.

The relaunch adds the existing `-nobootstrapperupdate`,
`-skipinitialbootstrap`, and `-no-child-update-ui` flags. Normal SteamUI
restart detection remains separately bounded by its existing restart limit.

The APK home screen now says that the truthful host-update adapter is enabled
and returns no-update status `7`. It does not report that an Android device can
apply a SteamOS image update.

## Run identity and gates

- Device: Retroid Pocket Nova, serial `675a2365`
- Planned run: `fresh-apk-bootstrap-relaunch-20260810T224245Z`
- APK SHA-256: `31566c6a3ed0f4a3a0ef7ccca33a0da1d6c7c8973b517fd0845fdeac472f942f`
- APK size: `3361472` bytes, version `0.3`, version code `3`
- Required purge: exact Nova scrub, APK uninstall, runtime/data removal,
  Termux:X11 preserved
- First-tap gate: one visible Start action, native Steam update may run, then
  the same session must relaunch into Steam OOBE without a second tap
- Safety gate: no unconditional update-success result, no view patch, no
  authentication export, no QR capture retained
- Success evidence: fresh client log shows
  `client_bootstrap_relaunch=1`, a second client attempt, and live OOBE
- Failure evidence: cleanly separate marker absence, timeout, client exit,
  and exact-scope cleanup status

If the one-shot condition does not match, the launcher must retain the current
second-tap behavior rather than relaunching an unrelated client failure.
