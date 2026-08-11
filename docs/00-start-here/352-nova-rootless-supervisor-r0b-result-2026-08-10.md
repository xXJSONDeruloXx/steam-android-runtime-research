# Nova rootless supervisor R0b result — 2026-08-10

Status: pass; guest execution and the configured app-home write contract are
verified.

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

The first replay exposed an implementation mismatch: it bound internal
`state/home` while validating the caller-provided `NOVA_ROOTLESS_HOME`. That
was fixed and the fresh R0c replay then placed the marker at the configured
app-private home:

```text
app_home_write=pass
```

This closes the PRoot/app-UID boundary. It does not establish display, audio,
input, networking semantics, Steam UI, or Proton execution.

The exact staging tree and app-private state were removed after the run. No
rooted runtime, Steam data, authentication file, X11 socket, or long-lived
process was changed.

## Next boundary

The next independent boundary is rootless X11 transport. It must be tested
with a separate run identity and must not reuse the rooted Termux:X11 socket.
