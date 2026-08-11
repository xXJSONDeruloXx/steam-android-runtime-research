# Nova rootless runtime/network contracts — 2026-08-10

Status: implementation stage passes static validation; device Runtime 4,
native Steam, audio, and game-frame gates remain open.

## Scope and provenance

This stage ports the narrow runtime contracts selected from the clean
`steamclienttermux` comparison checkout. The source revision inspected was:

```text
/Users/kurt/Developer/steamclienttermux
HEAD 8d14c10195b34fe2714ba59df1680df27a852532
```

The rooted Nova profile, its signed-in Steam data, and its display `:0` remain
outside this branch's rootless state. The branch continues to use the separate
rootless display `:77` and app-owned paths.

## Implemented contracts

### App-UID route shadow

`android/nova-lab/rootless/nova-rootless-proc-net-shadow.sh` now snapshots only
the files that the Nova app UID can read from `/proc/net`:

- `route` is copied atomically and must contain at least one route entry;
- `ipv6_route` is copied when readable, otherwise an empty regular file is
  created;
- symlinked destinations, non-regular entries, and stale temporary files are
  rejected;
- the result records `default_route=present` or `default_route=absent` rather
  than fabricating a gateway that Android did not expose.

The current app-UID probe on serial `675a2365` showed a connected `wlan0`
route and:

```text
192.168.0.0/24 dev wlan0 proto kernel scope link src 192.168.0.23
```

The UID-visible route table did not expose a default gateway in that probe.
That is an explicit follow-up condition for Proton/Wine networking; it is not
silently treated as equivalent to a complete route table.

The PRoot supervisor accepts the optional
`NOVA_ROOTLESS_PROC_NET=$STATE/config/proc-net` path and binds it to the guest
`/proc/net`. If it is absent, the prior rootless transport behavior is
preserved. The supervisor also passes an optional `PULSE_SERVER` value without
claiming that a PulseAudio server exists yet.

### Official Runtime 4 / Proton 11 registration

`nova-rootless-steam-arm64-compatibilitytools.vdf.in` reproduces the official
ARM64 relationship used by the comparison project:

```text
Proton 11:       AppID 4628740, depot 4628741
Runtime 4 ARM64: AppID 4185400, depot 4185401
Proton requires: AppID 4185400
```

`nova-rootless-prepare-runtime4.sh` is an app-UID-safe staging helper. It
requires the official Runtime 4 entry point and the matching ARM64 Pressure
Vessel donor, rejects `.l2s` pseudo-hardlinks in the donor/copy, creates a
private clean `var`, verifies the wrapper hash, stages into a unique temporary
directory, and activates with a same-filesystem rename. It also writes the
compatibility-tool manifest beneath the app-owned Steam client using the
rootless guest path.

The supervisor accepts the optional
`NOVA_ROOTLESS_RUNTIME4_SHADOW` and binds it over the exact guest path Steam
resolves for `SteamLinuxRuntime_4-arm64`. This keeps the official AppID and
`require_tool_appid` contract intact while allowing the Pressure Vessel copy to
be prepared without modifying the source depot.

## Validation

The repository-side rootless contract test passes:

```text
rootless_profile_static=pass
```

The test covers the new helper syntax, route-shadow validation, optional
supervisor binds, `PULSE_SERVER` propagation, and all four official Runtime 4
/ Proton 11 AppID/depot values.

No device Runtime 4 extraction or Steam launch was performed in this stage.
The current locally staged Nova artifact is SteamRT3C, not Runtime 4, so using
the new helper against it would be an invalid experiment. The next device run
must obtain and verify the official Runtime 4 ARM64 depot first, then use a
fresh rootless state and fresh Steam logs. The Termux:X11 bridge result remains
the prior gate: [R1e](359-nova-rootless-apk-termux-bridge-r1e-result-2026-08-10.md).

## Next bounded run

The next predeclared run should:

1. install/stage PRoot and the clean app-owned Steam seed in a new rootless
   state without copying rooted authentication data;
2. start a fresh Termux:X11 `:77` session through the APK bridge;
3. capture the app-UID route snapshot and record default-route presence;
4. download/verify Runtime 4 and Proton 11, prepare the shadow, and run the
   Runtime 4 `_v2-entry-point --verb=run -- /bin/true` gate;
5. launch native ARM64 Steam and classify the first fresh UI/frame result.

PulseAudio TCP and the session/log guard remain separate subsequent contracts;
they must not be reported as passing merely because the display transport is
healthy.
