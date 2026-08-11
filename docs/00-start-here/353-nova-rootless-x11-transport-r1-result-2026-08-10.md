# Nova rootless X11 transport R1 result — 2026-08-10

Status: fail closed; the current device has no rootless-readable X11
transport.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`.
- Run staging: `/data/local/tmp/nova-rootless-transport-r1-20260810T`.
- Invocation: `run-as com.xjsonderulo.steamandroid.novalab`.
- Rooted signed-in Steam session: left running and untouched.

## Device evidence

The app-UID transport probe reported:

```text
nova_rootless_transport=fail reason=missing_termux_base_and_shared_x11_socket
```

Package visibility showed `com.termux.x11` installed and no `com.termux` base
package. The rooted session's socket exists under the versioned runtime, but
that is not rootless evidence and was not accepted by the probe. The exact
probe staging directory was removed after the run.

This closes the current device's R1 negative boundary: the app-UID PRoot path
is viable, but the installed Termux:X11 APK does not by itself provide Nova a
rootless-readable X11 socket. A second Steam client must not be launched on
the rooted session's display as a workaround.

## Hardening found during the run

The first probe revision excluded rooted socket paths during automatic
discovery but would have accepted one if a caller supplied it explicitly. The
probe now rejects `/data/local/tmp/nova-runtimes/*` and the legacy
`/data/local/tmp/nova-holo-rootfs/*` paths in both cases. Static validation
covers that guard.

## Next boundary

The next implementation should establish one of the declared rootless display
contracts: install/use the Termux base + Termux:X11 user session and prove a
socket readable by the Nova UID, or implement a Nova-owned X11 bridge with an
explicit app-to-server transport. Until then, Runtime 4, Proton, audio, and
input work can be staged but cannot produce a rootless Steam frame.
