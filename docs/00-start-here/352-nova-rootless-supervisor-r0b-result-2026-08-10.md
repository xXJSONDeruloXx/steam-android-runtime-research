# Nova rootless supervisor R0b result — 2026-08-10

Status: partial pass; guest execution succeeded, configured-home binding was
corrected before accepting the result.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`.
- Run staging: `/data/local/tmp/nova-rootless-supervisor-r0b-20260810T`.
- App-private state: `files/rootless-supervisor-r0b-20260810T` in the Nova APK.
- Invocation: `run-as com.xjsonderulo.steamandroid.novalab`.
- Rooted signed-in Steam session: left running and untouched.

## Evidence

The corrected supervisor passed its app-UID preflight and executed the Holo
guest through the official Termux PRoot binary and loader:

```text
nova_rootless_preflight=pass uid=10128 ...
nova_rootless_exec=proot display=:0
uid=0(root) gid=0(root) groups=0(root),...
aarch64
```

The `uid=0` line is PRoot's virtual guest identity. The real Android UID was
`10128`, and the supervisor refused a real root UID before starting PRoot.

The write probe succeeded in app-owned storage, but the first implementation
bound internal `state/home` while validating the caller-provided
`NOVA_ROOTLESS_HOME`. That meant the guest write landed at the internal path,
not the configured home. This is a launcher contract bug, not a platform
failure. The supervisor now binds the validated `NOVA_ROOTLESS_HOME` directly
to guest `/home/nova`; the next replay is required before calling R0 complete.

The exact staging tree and app-private state were removed after the run. No
rooted runtime, Steam data, authentication file, X11 socket, or long-lived
process was changed.

## Next run

Repeat with the same pinned artifacts and a new run identity. Require the
write marker to appear at the configured app-private home, then run the
read/write probe through the final supervisor and close this R0 boundary. The
next independent boundary remains rootless X11 transport.
