# Nova rootless supervisor R0 replay — 2026-08-10

Status: failed at launcher argument preflight; no guest process was started.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`.
- Run staging: `/data/local/tmp/nova-rootless-supervisor-r0-20260810T`.
- App-private state: `files/rootless-supervisor-r0-20260810T` in the Nova APK.
- Invocation: `run-as com.xjsonderulo.steamandroid.novalab`.
- Rooted signed-in Steam session: left running and untouched.

## Result

The supervisor was invoked as the Nova app UID with the verified Holo rootfs
and the official Termux PRoot package/dependencies staged into the exact run
directory. It stopped before guest execution with:

```text
nova_rootless_status=fail reason=missing_file:/data/local/tmp/nova-rootless-supervisor-r0-20260810T/proot/loader
```

This was an implementation error, not a rootless platform result. The caller
passed the PRoot executable as `NOVA_ROOTLESS_PROOT`, while the first supervisor
revision treated that value as a directory containing both the executable and
loader. Preflight did the intended thing by refusing to continue rather than
guessing a loader path.

The supervisor now separates `NOVA_ROOTLESS_PROOT_BIN` and
`NOVA_ROOTLESS_PROOT_LOADER`. The exact staging tree and app-private state were
removed after the failed invocation; no Steam process, X11 socket, rooted
runtime, or authentication data was changed.

## Next run

Repeat the same R0 with only those two environment variables corrected, then
run `id`, `uname -m`, and an app-home write probe through the supervisor. A
passing R0 still does not establish rootless X11; that remains a separate
transport gate.
