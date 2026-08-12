# AYN Thor rootless R38 toybox-tar preparation attempt — invalid result — 2026-08-12

Run identity: `thor-rootless-r38-stable-payload-replay-20260812T001312Z`;
sub-run: `R38-official-stable-native-payload-replay`.

Status: **invalid-preparation**. The host stable-client gate passed and the
fresh public tree was transferred and verified under app UID 10138, but the
app-UID Holo archive extraction used Android toybox `tar` and failed on pinned
archive symlink/systemd entries. No Steam process was launched, so this is not
a stable-client, rootless Steam, Vulkan, WSI, or SELinux result.

## Host and client gates

The live Valve endpoint matched the R38 predeclaration exactly:

```text
manifest_sha256=a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91
stable_version=1785799196
payload_bytes=60815678
payload_sha256=38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148
decoded_zip_bytes=337453898
decoded_zip_sha256=aed451902b2239cbf8a16e1a2004e016cea803d562849a4969b01a93c9cb4821
decoded_entries=55
decoded_crc32=verified
```

The decoded payload's selected files were verified before transfer:

```text
steamrtarm64/steam=72f48fb9c3f2c19cf64f8f7bbf4c7b7af65a73571ae0eeaab05bffd1633f4126
steamrtarm64/steamui.so=25ad66cfc78590b1745301ae7b86b70db64f5be0cd142d33134796e203fc8b76
steamrtarm64/vgui2_s.so=705f45328bb03c42509d28b748b0b499938f5e0caf2db618e8c929f0c3044186
steamrtarm64/steamwebhelper=3176d90436e49f7d34524ca2686cd324e2583806ba78841852b189fbcee0b83c
```

Thor identity and the app-UID client check were valid:

```text
serial=d234a848
model=AYN Thor
device=kalama
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
package_count=161
package_beta=absent
app_uid_selected_hashes=all four matched the stable gate
steam_symlink=../.local/share/Steam
```

## Failure boundary

The exact app-UID extraction command used the pinned archive, zstd helper,
fresh R38 state, and no rooted runtime path. It reported:

```text
nova_rootless_rootfs_archive=extract archive=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/input/system.rootfs.zst stage=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/.rootfs-base.archive-staging.9246
tar: './usr/lib64' bad symlink
tar: './usr/lib/icu/78.1/pkgdata.inc' not in archive
tar: './usr/lib/systemd/system/system-systemd\x2dcryptsetup.slice' not in archive
tar: './usr/lib/systemd/system/system-systemd\x2dveritysetup.slice' not in archive
tar: had errors
nova_rootless_rootfs_archive=fail reason=archive_extract
```

Evidence is retained outside the repository at:

```text
/tmp/thor-rootless-r38-stable-payload-replay-20260812T001312Z-evidence/rootfs-extract.log
bytes=229
sha256=35f58f25bb2f8d8c902532bc12eb8d13b699a4d4ae6c2192d418a1df93e109e6
```

The rootfs destination was never activated. There was no X11 start, Steam
command, updater output, screenshot, Vulkan call, or authentication-state
access. The failure is the same archive-reader boundary already documented by
the earlier rootless Holo extraction work; it does not distinguish rooted from
rootless Steam behavior.

## Cleanup

Only the exact R38 scopes were removed:

```text
/data/local/tmp/thor-rootless-r38-stable-payload-replay-20260812T001312Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/
```

Post-cleanup checks reported:

```text
r38_device_scope=absent
r38_app_scope=absent
steam/proot/webhelper/x11_processes=absent
6077_listener=absent
rooted_rootfs=present
rooted_active_runtime=present
```

Termux properties were not changed in this attempt. No Steam authentication
secret, session token, cookie, QR state, machine-auth file, authenticated home,
or `steam.token` contents were read, copied, backed up, committed, or exported.

## Retry boundary

The next action is the fresh retry predeclared in doc 509. It keeps the stable
payload, client layout, Holo image, app UID, PRoot, network, X11, launch flags,
and all Steam environment variables fixed. It corrects only the archive
extraction infrastructure by supplying the existing pinned app-owned Holo
`bsdtar` bootstrap. No result from this invalid preparation attempt may be
used to classify `vgui2_s`, Vulkan, KGSL, or presentation.
