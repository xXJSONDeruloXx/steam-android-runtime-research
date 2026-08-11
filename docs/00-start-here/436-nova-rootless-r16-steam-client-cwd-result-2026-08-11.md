# Nova rootless R16 — Steam client working-directory result — 2026-08-11

Run ID: `nova-rootless-r16-steam-client-cwd-20260811T100427Z`
Sub-run: `R16-rootless-supervisor-steam-version-client-cwd`
Status: rootless provisioning, native updater download/install, and X11
update-window startup passed. The client-root CWD hypothesis was disproved;
the post-update Steam client still failed on the missing module handoff. The
exact run was cleaned.

## Result

R16 recreated the R15 app-UID rootless profile and changed only the guest
working directory for the Steam command. The first invocation reached the
native updater and completed the entire current public-beta payload:

```text
Downloading update (657758 of 657758 KB)...
Download Complete.
Extracting package...
Installing update...
Cleaning up...
Update complete, launching...
```

The resulting package directory contained 39 files and `660020 KiB`, with the
`steam_client_steamdeck_publicbeta_linuxarm64.installed` marker restored. The
first invocation ends at the updater's “launching” handoff because the
declared `--version` command does not provide a SteamUI acceptance path. A
same-command replay against the completed client tested the actual handoff:

```text
CWD=/opt/nova-steam
COMMAND=/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam --version'
EXIT=255
```

The fresh replay passed supervisor preflight and X11 update-window creation,
then failed with the same module request as R15:

```text
[2026-08-11 10:16:23] Using update UI: xwin
[2026-08-11 10:16:25] Show window
[2026-08-11 10:16:27] Verification complete
[2026-08-11 10:16:27] Destroy window
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
execl failed, errno 2
```

The replay log was 3407 bytes with SHA-256
`87001c34e12fd3bb2ac5de4e40cbad13e206b478490679da45c796606f4a2cd7`. The
initial full-updater log was 66361 bytes with SHA-256
`39eadef6ae4fac0142d1d755622b65faf6aecc150be64ca6368e840f1ce87243`.

## Decision on the CWD hypothesis

SteamClientTermux's launcher changes into its client root before executing the
ARM64 Steam binary. R16 reproduced that behavior with `/opt/nova-steam`, while
the supervisor's PRoot default remained `/home/nova`. The error did not
change. Therefore the simple relative-working-directory hypothesis is
disproved.

The staged and updated client still had:

```text
bin/vgui2_s.dll                 absent
steamrtarm64/vgui2_s.so        present
```

The `.so` source-input SHA-256 is
`a3e010415d3b1cda22a9fe6ad8e5a33e558113483cbc7639ec4cae560c676dd7`. R16 did
not create, rename, or symlink either artifact. The remaining boundary is the
ARM64 client package/layout or binary-pairing contract, not the PRoot CWD.

## Staging corrections within the declared scope

No source helper, APK asset, rooted runtime, Steam client, or experiment
variable changed. Three setup-only issues were corrected before the accepted
R16 run:

- the initial remote staging subdirectories were root-owned and not writable
  by `adb push`; the exact R16 directories were made writable;
- pushing a directory to an existing directory created nested `proot/proot`
  style paths, so the exact remote scope was recreated and directory contents
  were pushed with `/.`; and
- archive/package commands detach their app-UID child process after the shell
  returns on this device, so extraction and closure markers were polled before
  advancing. Both completed with their expected pass markers.

These corrections happened before Steam was run and do not count as a changed
runtime hypothesis.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Predeclaration: [R16 Steam client CWD predeclaration](435-nova-rootless-r16-steam-client-cwd-predeclaration-2026-08-11.md).
- Code/assets under test: commit `d27a7b8`; predeclaration commit `2f8049f`.
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
- Public Steam client input: 51 files, 337949869 bytes. Key hashes:
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
- Fresh app-UID Termux:X11 transport was ready on `127.0.0.1:6077`.
- Rootless guest closure marker reported `gtk2_and_ui_audio_closure=pass`,
  `rooted_runtime_modified=0`, and `steamui_patch=0`.
- The supervisor reported `uid=10128`; no privileged supervisor path was used.
- No Steam authentication data was read, copied, exported, or backed up.
- No Steam Runtime 4 shadow, `/proc/net` bind, Proton, Gamescope, or
  AHardwareBuffer variable was introduced.

## Exact cleanup verification

Only these R16 scopes were removed:

```text
/data/local/tmp/nova-rootless-r16-steam-client-cwd-20260811T100427Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r16/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK launcher assets were retained. After cleanup and a settling
interval:

```text
no matching Steam/SteamUI/Steamwebhelper/PRoot/Nova-rootless process
no :6077 listener
remote_r16=absent
app_r16=absent
termux_rootless=absent
rollback_rootfs=present
active_runtime=present
free_space=86002416 KiB
```

## Next boundary

R16 closes the client-root CWD question and advances the rootless native
updater path through the complete current payload. The next experiment should
remain separate and inspect the exact ARM64 package contents, the updater's
installed manifest, and the matching Steam executable/runtime build. Do not
copy or rename `vgui2_s.so` into a guessed DLL path. A successful
`steam --version` handoff is still required before the separate SteamUI/X11
gate, Runtime 4 registration, Proton, login, or game work.
