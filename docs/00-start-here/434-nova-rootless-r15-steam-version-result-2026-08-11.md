# Nova rootless R15 — Steam version result — 2026-08-11

Run ID: `nova-rootless-r15-steam-version-20260811T094945Z`  
Sub-run: `R15-rootless-supervisor-steam-version`  
Status: rootless runtime, native updater, and X11 update window passed; the
public ARM64 client then failed at its SteamUI module handoff. The exact run
was cleaned.

## Result

R15 kept the R14 app-UID PRoot environment unchanged and ran the declared
command:

```text
/opt/nova-steam/steamrtarm64/steam --version
```

The first invocation crossed the Holo glibc loader, app-UID PRoot, inherited
Android networking, and the direct Termux:X11 transport. It entered Steam's
native client updater and downloaded the pending `steamdeck_publicbeta`
client. The captured updater output reached at least:

```text
Downloaded new manifest: /steam_client_steamdeck_publicbeta_linuxarm64 version 1786141909
Downloading update (268161 of 657758 KB)...
Set percent complete: 40
```

The original updater stream was too large for the terminal capture, so its
final process exit was not used as evidence. The post-update package state was
queried before teardown: 39 files, `660020 KiB`, and a matching
`steam_client_steamdeck_publicbeta_linuxarm64.installed` marker. A same-command
replay with output redirected into the app-owned R15 scope gave the decisive
fresh result:

```text
nova_rootless_preflight=pass uid=10128 rootfs=files/r15/guest-rootfs-closure proot=files/r15/proot/proot
nova_rootless_exec=proot display=127.0.0.1:77
[2026-08-11 09:59:06] Verifying installation...
[2026-08-11 09:59:10] Verification complete
[2026-08-11 09:59:10] Destroy window
[2026-08-11 09:59:11] Shutdown
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
execl failed, errno 2
[2026-08-11 09:59:11] Shutdown
```

The replay exited with status `255`. Its app-owned log was 3407 bytes with
SHA-256
`84f69e15de6fea2c30890a9e73d7348f9ddaafbea2541a0488f5240b2c37fe48`.

This is a useful partial pass: the rootless supervisor, guest identity, Holo
dynamic loader, Steam updater, and X11 update-window path are all live. It is
not a SteamUI, Big Picture, login, Proton, game, or first-frame result.

## First failing boundary

The staged ARM64 client contains:

```text
steamrtarm64/vgui2_s.so
```

with source-input SHA-256
`a3e010415d3b1cda22a9fe6ad8e5a33e558113483cbc7639ec4cae560c676dd7`, but no
`bin/vgui2_s.dll`. The downloaded client package manifest also contains no
`vgui2` entry. The Steam executable nevertheless requests the relative
`bin/vgui2_s.dll` module after the updater's verification window closes.

Therefore the current blocker is the ARM64 Steam-client filesystem/layout
contract, after native client startup and before SteamUI. It is not currently
evidence of a PRoot loader failure, a missing X11 display, a network namespace
failure, or a Vulkan/WSI failure. Do not guess that the `.so` can be copied or
symlinked to the `.dll` name: declare that layout hypothesis separately and
verify its ABI and loader behavior.

Two local replay attempts did not invoke Steam because their capture commands
referenced paths relative to an already-changed directory. The corrected
replay above used the exact predeclared paths and is the only replay result
counted here; no code, runtime, package, network, display, or client variable
changed.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Predeclaration: [R15 Steam version predeclaration](433-nova-rootless-r15-steam-version-predeclaration-2026-08-11.md).
- Code under test at run start: `cd1cc7a`; predeclaration commit: `b3a3dab`.
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
- Public Steam client input: 51 files, approximately 330120 KiB. Key hashes:
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
- Fresh Termux:X11 transport was ready on `127.0.0.1:6077` for the run.
- No Steam authentication data was read, copied, exported, or backed up.
- No Steam Runtime 4 shadow, `/proc/net` bind, Proton, Gamescope, or
  AHardwareBuffer variable was introduced.

## Exact cleanup verification

Only these R15 scopes were removed:

```text
/data/local/tmp/nova-rootless-r15-steam-version-20260811T094945Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r15/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK launcher assets were retained. After cleanup and a short
settling interval:

```text
no matching Steam/SteamUI/Steamwebhelper/PRoot/Nova-rootless process
no :6077 listener
remote_r15=absent
app_r15=absent
termux_rootless=absent
rollback_rootfs=present
active_runtime=present
free_space=85994332 KiB
```

## Decision and next boundary

R15 advances the rootless path through native Steam updater and X11 startup,
but stops before SteamUI because the current ARM64 client seed/update layout
does not provide the module name the ARM64 Steam executable requests. The next
bounded experiment should keep the R15 profile fixed and inspect the exact
SteamClientTermux/upstream ARM64 client layout and launch working directory.
Only then should a separately predeclared compatibility-layout experiment test
whether the correct artifact is a package extraction fix, a launcher cwd/path
fix, or an upstream client/runtime pairing issue. After `steam --version`
passes, advance to the separate SteamUI/X11 gate; do not combine that with
Runtime 4, Proton, login, or game variables.
