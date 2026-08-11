# Nova rootless X11 R1d package-visibility result — 2026-08-10

Status: failed at package discovery; the X11 endpoint was not disproved.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`.
- Termux display: fresh `:77`, temporary PID `10723`, stopped after the run.
- Probe staging: `/data/local/tmp/nova-rootless-termux-r1d-20260810T`.
- Rooted signed-in Steam session: left running and untouched.

## Evidence

The updated TCP transport probe was run from Nova's app UID while the
Termux-owned `:77` server was accepting `127.0.0.1:6077`. It reported:

```text
nova_rootless_transport=fail reason=missing_termux_base
```

The device did have `com.termux` installed, but Nova's existing APK declared
only `com.termux.x11` in its Android package-visibility queries. Consequently
`pm path com.termux` returned no visible package to the app UID. This is an
APK metadata/integration defect, not a failed network or X11 connection.

The probe now accepts `NOVA_ROOTLESS_TERMUX_PRESENT=1` only as a caller-verified
override for standalone diagnostics, and the APK declares both Termux packages
plus `com.termux.permission.RUN_COMMAND`. The product launcher must still
check the package with Android `PackageManager` and obtain the user-granted
RUN_COMMAND permission before invoking the Termux-side launcher.

The exact `:77` process and probe staging were stopped/removed. The rooted
`:0` session and all Steam data remain untouched.

## Next run

Build/install the APK with the new package visibility declaration, rerun the
transport probe with no override, and then exercise the Java RUN_COMMAND path
using the pinned Termux-side launcher. Keep the TCP endpoint classified as
experimental until an authenticated loopback or app-owned X11 bridge replaces
`-ac`.
