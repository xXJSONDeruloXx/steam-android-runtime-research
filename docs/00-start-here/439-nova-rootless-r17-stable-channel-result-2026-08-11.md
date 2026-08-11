# Nova rootless R17 — stable ARM64 client-channel result — 2026-08-11

Run ID: `nova-rootless-r17-stable-channel-20260811T102817Z`; sub-run:
`R17-rootless-supervisor-steam-stable-channel`.
Status: complete; stable-channel update crossed the prior `vgui2` fatal, but
the session stalled before `steamwebhelper` or a visible Steam frame.

## Result

R17 kept the R16 rootless Holo/PRoot, direct Termux:X11, resolver, app-UID,
client-root working directory, and launch command unchanged. It removed only
the copied client's `package/beta` selector, thereby selecting Valve's stable
ARM64 client manifest.

The stable client updated successfully from the seeded tree, reached the
post-update native Steam process, and did not emit R15/R16's fatal request for
`bin/vgui2_s.dll`. It nevertheless did not progress to `steamwebhelper`,
SteamUI logs, or a usable Steam frame. The fresh replay remained attached to a
native Steam/update-UI process after the verification window and displayed a
black 1280x960 X11 surface with only a narrow right-edge scrollbar-like mark.

This is a meaningful boundary change, not a rootless Steam UI pass:

```text
rootfs + Holo closure + PRoot       pass
stable ARM64 client update          pass
native post-update Steam process    pass
bin/vgui2_s.dll fatal               not reproduced
steamwebhelper                      not spawned
SteamUI / visible Steam frame       not reached
```

The next experiment should therefore trace the conventional installed
`.steam` layout used by the clean SteamClientTermux reference. Do not add a
guessed `.so`-to-`.dll` alias, patch SteamUI, or move to Runtime 4/Proton until
that one layout variable has been tested.

## Profile and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08ad8e257a682`.
- Display: fresh app-owned Termux:X11 session at `127.0.0.1:6077`; guest
  display `:77`.
- Supervisor: app UID `10128`, PRoot under the app-owned R17 scope, Holo
  guest rootfs closure, and the same R16 launch command:

  ```text
  /bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam --version'
  ```

- Stable manifest URL:
  `https://client-update.steamstatic.com/steam_client_linuxarm64`.
- Stable client version: `1785799196`.
- Manifest SHA-256:
  `a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91`.
- Resolved ARM64-native VZ payload:
  `bins_linuxarm64_linuxarm64.zip.vz.11771d05f91515ca5337eeb9baf835098df71d3a_60815678`.
- VZ payload size: `60815678` bytes.
- VZ payload SHA-256:
  `38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148`.
- Holo rootfs archive: `384971555` bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Debian external manifest: two entries, SHA-256
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

The clean SteamClientTermux reference was inspected at revision
`8d14c10195b34fe2714ba59df1680df27a852532`. Its successful stable-client
launch uses the same client-root working directory plus conventional links
for `sdkarm64`, `bin64`, `bin32`, and `steamrtarm64`; those links were not
present in R17 and are the controlled R18 hypothesis.

## Setup corrections kept separate from the R17 variable

The first staging attempt exposed two reproducibility issues in the existing
manual setup. They were corrected before the stable-channel observation and
are not treated as evidence for or against the channel hypothesis:

1. The copied PRoot closure lacked the known `libtalloc.so.2` and
   `libtalloc.so` links, so PRoot initially failed Android dynamic linking.
   The links were recreated from the already verified staging inputs.
2. Android app-asset copying left the PRoot loader and native Steam targets
   non-executable. The known-good executable modes were restored before
   extraction/replay.

After those corrections, the rootfs extraction, 161-package Holo closure,
external GTK2/UI-audio closure, and supervisor preflight all passed. The
closure reported `pacman_local_count=301`, and the supervisor reported fresh
free-space checks before each invocation.

## Fresh run evidence

The first stable invocation downloaded and installed the complete stable
client. Its fresh log records a 664,432-KB update, extraction, installation,
cleanup, `Update complete, launching...`, and `Shutdown`. The expected
updater handoff returned exit code `42`; this was not used as the final
acceptance result, so the installed client was replayed with the same command.

The replay log records:

```text
version(1785799196)
Using update UI: xwin
Create window
Verification complete
Steam logging initialized: directory: /opt/nova-steam/logs
```

It contains no `Fatal`, `vgui2`, or `steamwebhelper` startup line. During the
replay the exact R17 process tree was observed as the wrapper shell, PRoot,
native Steam, and its update-UI child. It was terminated by exact PID after
the evidence capture; no matching Steam/PRoot/webhelper/helper process
remained.

The post-update tree contained `linuxarm64`, `steamrt32`, `steamrt64`, and
`steamrtarm64`, but still no `bin/vgui2_s.dll`. The updated native hashes were:

```text
steamrtarm64/steam       72f48fb9c3f2c19cf64f8f7bbf4c7b7af65a73571ae0eeaab05bffd1633f4126
steamrtarm64/steamui.so  25ad66cfc78590b1745301ae7b86b70db64f5be0cd142d33134796e203fc8b76
steamrtarm64/vgui2_s.so  705f45328bb03c42509d28b748b0b499938f5e0caf2db618e8c929f0c3044186
steamrtarm64/steamwebhelper
                           3176d90436e49f7d34524ca2686cd324e2583806ba78841852b189fbcee0b83c
```

Evidence artifacts retained until this result was written:

```text
/tmp/nova-r17-steam-stable-command.log  sha256=6eacf2a3d21a1cdc6e54ad232a860acbde92eda67e48d31485fb6aab74051f78
/tmp/nova-r17-steam-stable-replay.log   sha256=10c89f02d1af617c80784c812fa62361687682ec35a063edc969b48f1343948c
/tmp/nova-r17-rootless-supervisor.log   sha256=f8af2628b4e208aacf6e799f1390d085a7836be3cf6975c961aaec5a3449b1fa
/tmp/nova-r17-stable-replay.png         sha256=d55ca8243a55d34563a28c9bca0477be90279ab1453fecd205be66c52adde98b
```

The replay screenshot is a fresh 1280x960 PNG. It is evidence of the X11
surface state only; it is not evidence of SteamUI readiness or a successful
displayed Steam frame.

## Cleanup and rollback

The exact R17 scopes were removed after process and listener teardown:

```text
/data/local/tmp/nova-rootless-r17-stable-channel-20260811T102817Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r17/
/data/data/com.termux/files/home/.nova-rootless/
```

Verification after cleanup:

```text
remote_r17=absent
app_r17=absent
termux_rootless=absent
matching Steam/PRoot/webhelper/bsdtar/pacman processes=none
127.0.0.1:6077 listener=absent
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs=present
/data/local/tmp/nova-active-runtime=present
```

The R17 app state was removed as a disposable experiment scope. No Steam
authentication secret was read, copied, or backed up; any state in that scope
was removed in place as part of exact cleanup. The rooted known-good runtime
and active-runtime marker were not modified.

## Follow-up

Predeclare R18 as a one-variable retry using the stable client and the same
rootless/X11 profile. Add only the conventional links observed in
SteamClientTermux:

```text
$HOME/.steam/steam        -> /opt/nova-steam
$HOME/.steam/sdkarm64     -> /opt/nova-steam/linuxarm64
$HOME/.steam/bin64        -> /opt/nova-steam/steamrt64
$HOME/.steam/bin32        -> /opt/nova-steam/steamrt32
$HOME/.steam/steamrtarm64 -> /opt/nova-steam/steamrtarm64
```

Require fresh evidence of `steamwebhelper`, SteamUI logs, and a correlated
visible frame. Keep Runtime 4, Proton, games, Gamescope/AHardwareBuffer,
SteamUI patching, and authentication outside R18.
