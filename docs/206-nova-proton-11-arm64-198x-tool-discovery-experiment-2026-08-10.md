# Nova Proton 11 ARM64 198X tool-discovery experiment — 2026-08-10

Status: phase 1 predeclared.

## Question

Steam has now downloaded Valve's Proton 11.0 (ARM64) package, AppID
`4628740`, and its required Steam Linux Runtime 4.0 - Arm64 package, AppID
`4185400`. The installed 198X configuration still maps AppID `1086010` to
`proton_hotfix`:

```text
"CompatToolMapping"
{
    "1086010"
    {
        "name" "proton_hotfix"
        "config" ""
        "priority" "250"
    }
}
```

The user requires 198X to use Proton 11 ARM64. Before changing this mapping,
start a fresh native ARM64 Steam client and record the exact compatibility-tool
name Steam registers for the newly installed AppID. The name must come from
the current client/tool manifests or Steam's own selection state; it will not
be guessed from the directory name or manually invented.

This phase does not launch 198X or modify the selected compatibility tool. It
only restarts the normal one-click Steam session and establishes a fresh
registration baseline. The next phase will set AppID `1086010` to the verified
ARM64 Proton tool through Steam's compatibility mapping path, restart Steam
again, and then attempt the game launch.

## Predeclared run

Run ID: `proton-arm64-20260810T014513Z-tool-discovery`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`, ABI `arm64-v8a`;
- branch `feat/nova-one-click-launcher`, source commit `2da5475`;
- APK package `com.xjsonderulo.steamandroid.novalab`, installed APK SHA-256
  `0ff3b753b113e0a5c9ecadd7b1f88a66113b1891ec7e698fbe5eaa1950fa18f8`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- direct Termux:X11 Steam path, software CEF, fullscreen, 1280x960;
- installed Proton 11 ARM64 directory and Steam Linux Runtime 4 ARM64
  directory are read-only discovery targets;
- no game launch, compatibility mapping change, physical input, synthetic
  input, keyboard input, pointer input, or touch input.

The run will:

1. execute the exact preflight cleanup and capture fresh process/log baselines;
2. launch the one-click test APK's Steam session;
3. capture the new session's Steam `compat_log.txt`, `client.log`, launcher
   log, and `config.vdf` compatibility mapping;
4. record every newly registered tool line for AppIDs `4628740` and `4185400`
   and inspect the corresponding `toolmanifest.vdf` files; and
5. stop through the exact cleanup helpers and verify processes, mounts, and
   X11/rootfs temporary sockets are absent.

Success means the fresh client registers the ARM64 Proton package with an
explicit usable tool name. A stable installation without a fresh registration
is a tool-catalog lifecycle boundary, not a game-launch result.

## Discarded harness attempts

The first launch attempt was discarded before interpreting any Steam result.
The preflight left the prior `/data/local/tmp/nova-android-launcher/ready`
marker in place, so a one-second readiness poll observed stale state before
the new launcher had written its session. The actual new session was
`20260810T015120Z-25822`; it was captured only as a control artifact and then
terminated through the exact helpers. No compatibility registration or game
result from that attempt is used here.

The following start was also discarded: the APK Activity had not been
force-stopped after that teardown, so Android reported that the intent was
delivered to the already-running top-most Activity and no new runtime was
created. The retry below therefore force-stops the APK after every discarded
session and requires both a missing old marker before launch and a new session
ID after launch.

## Phase 1 retry predeclared run

Run ID: `proton-arm64-20260810T015323Z-tool-discovery-retry`

The retry keeps the original profile and source commit. It adds an explicit
APK force-stop, removes only the prior launcher state markers (`ready`,
`client-active`, `server-token`, `client-token`, and `session`), records the
pre-launch compatibility-log line count, and accepts readiness only after the
session ID and launcher log belong to this retry. It will not launch 198X or
change `CompatToolMapping`.

## Decision boundary

The next run may change only the 198X compatibility mapping after this phase
records the exact tool name. It must preserve the current mapping as a
rollback artifact, use a fresh Steam process, and capture the resulting
`StartSession`, Proton/Wine/FEX/pressure-vessel process tree, Proton logs,
game lifetime, and a frame correlated to the same run ID.

## Cleanup contract

The exact Nova/X11 cleanup helper and rootfs runtime cleanup helper must run
before launch and on every exit or interruption. The final process filter must
contain no matching Nova rootfs, Steam, Gamescope, Termux:X11,
compatibility-runtime, or relay process. Existing Steam account, game,
shader-cache, prefix, and installed tool data must be preserved.
