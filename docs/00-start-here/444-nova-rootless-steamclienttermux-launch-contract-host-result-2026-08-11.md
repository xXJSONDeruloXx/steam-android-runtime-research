# Nova rootless — SteamClientTermux launch-contract host result — 2026-08-11

Status: host-only prior-art audit; no Android device run.

## Finding

The successful SteamClientTermux ARM64 sessions do not use the diagnostic
command tested by Nova R17 and R18b:

```text
Nova R17/R18b:
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam --version'

SteamClientTermux:
cd "$client_root"
exec "$client/steam" -no-cef-sandbox -cef-disable-gpu \
    -chromeosnopreallocate -noverifyfiles
```

The sibling launcher also creates the `.steam` links, but it does so inside a
larger session contract that includes a patched PRoot, a prepared official
Runtime 4 shadow, a private D-Bus session, a validated `/proc/net` shadow,
PulseAudio TCP, a private Turnip ICD, a compatibility-tool manifest, and
session/log guards. R18b isolated only the links and still used `--version`,
so its fatal result cannot establish that the actual Steam session lifecycle
has the same behavior as the successful prior art.

## Audited source and evidence

- Checkout: `/Users/kurt/Developer/steamclienttermux`.
- Clean revision: `8d14c10195b34fe2714ba59df1680df27a852532`.
- Launch source: `bin/steam-arm`, including the guest script that sets
  `HOME`, `DISPLAY`, `XDG_RUNTIME_DIR`, `PULSE_SERVER`, library/ICD paths,
  creates the conventional links, changes to the client root, and executes
  the native client.
- Runtime preparation: `scripts/prepare-arm64-runtime-shadow.sh`.
- Representative successful logs under the sibling checkout's
  `docs/logs/` show a native launch with no `--version`, including
  `cef-software-fixed-20260807-162701.log` and
  `ipv4-test-20260807-151041.log`.

The sibling's source also contains a Steam UI compatibility patch and route
helper. Those are separate variables and are not imported into the next Nova
run. The audit is identifying the command-line/lifecycle gap, not claiming
that the entire sibling architecture is portable to Nova.

## Interpretation of the Nova results

R17's stable/no-link replay stalled before `steamwebhelper` without emitting
the fatal. R18b's stable replay with the four extra links emitted
`bin/vgui2_s.dll` and still did not spawn `steamwebhelper`. Both were run with
`--version`, which is not the command used by the successful sibling sessions.
The next safe test is therefore to hold the R17 stable/no-link filesystem and
display profile constant and remove only the diagnostic `--version` argument.

Do not add a guessed DLL alias, patch SteamUI, add Runtime 4/Proton, or import
the sibling's route/audio/PRoot changes in that test. If the no-version client
reaches `steamwebhelper`, add the sibling's remaining launch flags in separate
experiments. If it fails at the same module boundary, the command shape is
not the explanation and the next step returns to exact module-resolution and
loader tracing.
