# Nova rootless R2 PRoot path failure — 2026-08-10

Run ID: `nova-rootless-r2-20260810T230711Z`
Sub-run: `R2a-guest-id`
Status: failed gate; supervisor fix staged for the next fresh replay.

## Evidence boundary

The rooted signed-in Steam tree on display `:0` remained running throughout.
The rootless state was isolated under:

```text
files/rootless-r2-20260810T230711Z/
```

The app-owned preflight passed as UID `10128`:

```text
nova_rootless_preflight=pass uid=10128 rootfs=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs proot=files/rootless-r2-20260810T230711Z/proot/bin/proot
nova_rootless_free_kib=84798076
nova_rootless_proc_net=files/rootless-r2-20260810T230711Z/state/config/proc-net
```

The route snapshot also passed and preserved the app-visible connected `wlan0`
route. Termux:X11 `:77` was a separate UID `10129` process and its TCP listener
was observed at `0.0.0.0:6077`; the rooted UID `0` `termux-x11` process remained
separate.

## Failure

The first guest command was intentionally `/usr/bin/id`, not Steam:

```text
nova_rootless_exec=proot display=127.0.0.1:77
env: 'id': No such file or directory
```

PRoot itself launched and the guest `/usr/bin/env` executed. The failure was
the supervisor's omission of a guest `PATH`, so `env` could not resolve the
known-good `/usr/bin/id` preflight target by name. This is a launcher contract
bug, not evidence against the Holo rootfs, PRoot binary, route shadow, or X11
transport.

## Fix

The supervisor now exports the explicit Holo path:

```text
PATH=/usr/bin:/bin:/usr/sbin:/sbin
```

The static rootless test was extended to require this export. The next replay
must use a fresh log and command baseline after the fix; this failed `id`
result is closed and must not be used as a Steam readiness result.
