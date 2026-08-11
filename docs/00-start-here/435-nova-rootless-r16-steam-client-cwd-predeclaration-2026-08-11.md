# Nova rootless R16 — Steam client working-directory predeclaration — 2026-08-11

Run ID: `nova-rootless-r16-steam-client-cwd-20260811T100427Z`
Sub-run: `R16-rootless-supervisor-steam-version-client-cwd`
Status: predeclared after R15 isolated the first SteamUI handoff failure.

## Hypothesis

R15 launched the Steam executable through the rootless supervisor with PRoot's
guest working directory fixed at `/home/nova`. Steam then reported:

```text
Fatal Error: Could not load module 'bin/vgui2_s.dll'
```

The sibling SteamClientTermux launcher changes into the Steam client root
before executing its ARM64 Steam binary:

```text
cd "$6"
exec "$steam_exe" ...
```

R16 tests whether Steam's relative module lookup is sensitive to that client
root. This is a launch-contract experiment, not permission to create a
guessed `.so`/`.dll` alias or patch SteamUI.

## Controlled change

Keep the complete R15 provisioning, app-owned state, resolver, X11 endpoint,
Steam client input, and supervisor environment unchanged. Run the same public
ARM64 Steam command through one fixed guest shell that changes only its CWD:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam --version'
```

Do not add `-gamepadui`, Steam Deck flags, `-noverifyfiles`, `-no-cef-sandbox`,
Steam Runtime 4, `/proc/net`, Proton, login, game launch, authentication data,
Gamescope, AHardwareBuffer, or a SteamUI patch. The supervisor still owns the
same `/home/nova` default; only the guest command performs the declared
`cd`.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code/assets under test: commit `d27a7b8`; no runtime or launcher code changes
  are made for this experiment.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08ad8e257a682`.
- Bootstrap manifest: 18 payload entries, SHA-256
  `8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Debian external manifest: two entries, SHA-256
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.
- Public Steam client input: the same 51-file seed/update tree used by R15.
  Key hashes:
  `steamrtarm64/steam`
  `cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85`;
  `steamrtarm64/steamui.so`
  `972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0`;
  `steamrtarm64/steamwebhelper`
  `3901a2af2b9348a4b6381162c3913d607fcf7e959996b8388fd571f4a0d1cd8f`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r16-steam-client-cwd-20260811T100427Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r16/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify the rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Reread the lifecycle contract and establish a fresh process, listener, app,
   remote-scope, and rollback baseline.
2. Install/hash-verify the pinned APK, start fresh app-UID Termux:X11 on
   `127.0.0.1:6077`, and recreate the unchanged R15 archive extraction,
   package closure, and supervisor preflight in `files/r16/`.
3. Capture the exact guest command stdout/stderr, exit status, supervisor log,
   fresh package/client state, and process set. A pass requires the CWD change
   to remove the `bin/vgui2_s.dll` handoff failure or expose a later, precise
   Steam boundary; it does not authorize a SteamUI/login claim.
4. Stop X11, remove only the three R16 scopes, and verify no Steam/PRoot/X11
   residue, rollback preservation, and free-space recovery.

## Interpretation

If the CWD change removes the missing-module error, the next predeclaration can
make the working directory an explicit supervisor/profile contract and proceed
to the separate SteamUI/X11 gate. If the same error remains, keep the module
layout hypothesis separate: inspect the actual ARM64 client package/update
contents and loader expectations before testing any artifact mapping.
