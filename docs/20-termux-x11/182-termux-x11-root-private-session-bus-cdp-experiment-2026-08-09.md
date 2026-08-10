# Termux:X11 root-private session-bus CDP confirmation — 2026-08-09

Status: predeclared; not run yet.

## Question

The root-private session-bus run proved that a D-Bus socket can exist beside
Steam, but the visual state and Steam logs did not improve. This run repeats
that same runtime profile and adds one read-only host-side CDP observation
while the fresh webhelper is alive. It directly tests the acceptance boundary
identified in the earlier login probe:

```text
typeof SteamClient.User.GetStartupUserChooserState
typeof SteamClient.User.StartLogin
typeof SteamClient.User.GetLoginUsers
typeof SteamClient.User.GetCurrentUser
document.body.innerText
```

The CDP probe creates only an exact run-scoped `tcp:9222 -> tcp:8080` ADB
forward, evaluates the expression, records the output, and removes the
forward on every exit. It does not mutate Steam state, call a login method, or
change the network path.

## Fixed profile and one added observation

Keep the root-private session-bus variant from experiment 180 unchanged:

```text
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
steam_uid=501:20
NOVA_TERMUX_X11_DBUS_SESSION=1
NOVA_TERMUX_X11_DBUS_SESSION_USER=root
NOVA_TERMUX_X11_NETWORK_OBSERVER=1
NOVA_TERMUX_X11_NETWORK_OBSERVER_DURATION_SECONDS=45
NOVA_TERMUX_X11_NETWORK_OBSERVER_INTERVAL_SECONDS=5
input_mode=android-keyevent-sequence
input_keycodes=66,66,66
input_after_delay_seconds=8
capture_delay_seconds=8
steam_timeout_seconds=75
```

The APK, X11 client, capture helper, display, window wait, Steam flags, and
artifact hashes must match the preceding root-private run. Use a fresh run
identity such as:

```text
termux-x11-<UTC>-network-root-session-bus-cdp-0
```

Read `docs/00-start-here/34-nova-runtime-harness-lifecycle.md` immediately before launch.

## Acceptance gates

1. The deployment passes the existing exact-scope preflight and full
   Termux:X11 display/input/network observer gates.
2. The client log and observer prove the private bus started, while cleanup
   proves the bus process, socket, mount, Steam tree, and ADB forward are gone.
3. The CDP target is the fresh Steam Big Picture `steamloopback.host` page,
   and the JSON output records the four User method types, title, URL, and
   body text.
4. The result explicitly classifies whether the User methods remain absent,
   whether the body remains `Waiting for network...`, and whether a QR/login
   surface appeared. No inference from an HTTP success alone is accepted.

The run is diagnostic confirmation, not a new UI patch or a new route/NAT/
proxy experiment. Document, commit, and push its result before adding or
testing a system-bus/NetworkManager service boundary.
