# Nova rootless X11 R1b result — 2026-08-10

Status: failed before X11 client execution; transport server and PRoot
preflight were not the failing layer.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`.
- Termux display: `:77`, temporary PID `6065`, stopped after the run.
- Rootless staging: `/data/local/tmp/nova-rootless-x11-r1b-20260810T`.
- App-private state: `files/rootless-x11-r1b-20260810T`.
- Rooted signed-in Steam session: left running and untouched.

## Evidence

The Termux-side server started under the Termux app UID and Nova’s app UID
could open `127.0.0.1:6077`. The rootless supervisor also passed app-UID
preflight. The guest client then failed immediately:

```text
nova_rootless_exec=proot display=127.0.0.1:77
env: '/opt/nova-steam/nova-x11-animate': No such file or directory
```

The client had been copied into the configured `NOVA_ROOTLESS_STEAM_CLIENT`
directory, but the supervisor bound an internal `state/steam-client` directory
instead. This is another supervisor configuration bug, not evidence against
rootless X11 or PRoot. No X11 protocol client or window was created.

The exact Termux `:77` process, app-private state, and rootless staging tree
were stopped/removed after the failure. The rooted `:0` session remains the
only active Steam display.

## Correction and next run

The supervisor now binds the validated `NOVA_ROOTLESS_STEAM_CLIENT` directly to
guest `/opt/nova-steam`, matching the already-correct configured-home binding.
R1c must repeat the same X11 client test with a fresh run identity and require
an actual X11 window/tree result before this transport can be considered a
pass.
