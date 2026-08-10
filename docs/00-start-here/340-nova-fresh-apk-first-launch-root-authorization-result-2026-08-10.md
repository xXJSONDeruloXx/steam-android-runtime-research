# Nova fresh APK first-launch root authorization result — 2026-08-10

Status: the clean first launch was blocked before provisioning because Magisk
had not authorized the newly installed APK UID. The authorization was then
granted explicitly and a same-profile retry is predeclared below.

## Run identity and provenance

- Device: Retroid Pocket Nova, serial `675a2365`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `9f352805235ca005d9cffcb2c50aad9674d1ed1ea2a4218a44aa17f10324e07a`
- Provisioner source SHA-256:
  `4c7b420f3291e15774dfe8e5869131a6942bf877ef4923a51d60a6ab24215718`
- Profile: direct Holo ARM64 glibc through Termux:X11, current one-click
  launcher, truthful SteamOS update adapter, software CEF path, audio bridge,
  uinput relay, KGSL ICD, and one in-session Steam restart.
- No OOBE view rewrite was enabled.

## Purge boundary

The repository scrub completed before APK installation and removed the prior
Nova package, runtime, legacy rootfs, and listed project state while preserving
Termux:X11. Device storage increased from approximately 87,016,692 KiB free
to 92,418,004 KiB free. A post-failure exact cleanup also removed the
interrupted staging log directory, three old Nova launcher-session directories,
and these project helper libraries:

```text
/data/local/tmp/nova-runtimes
/data/local/tmp/launcher-20260809T223146Z-x11-custom-1280x960
/data/local/tmp/launcher-20260809T223146Z-x11-custom-1280x960-retry
/data/local/tmp/launcher-20260809T223146Z-x11-stretch-1280x800
/data/local/tmp/libffmpeg-avutil-compat.so
/data/local/tmp/libsdl3-compat.so
/data/local/tmp/libsysv-sem-shim.so
```

The remaining top-level `/data/local/tmp` entries are unrelated or retained
Android/device tooling (`codex-gameassistant-configs.db`, `dalvik-cache`, and
`mount.out`). No matching Nova, Steam, Xwayland, Termux:X11, Gamescope, uinput,
or libei process remained after cleanup. No Steam authentication data was
exported or backed up.

## Fresh APK result

After installing the APK, the first Activity launch was visually clean. The
operator tapped **Start Steam**, accepted Android's notification permission,
and the app began provisioning. The rooted command failed immediately because
the new APK installation had no Magisk grant:

```text
NovaLauncher: Provisioning versioned Nova runtime
NovaLauncher: Permission denied
NovaLauncher: Nova provisioner exited with status 13
NovaLauncher: Nova provisioning failed; attempting preserved rollback
NovaLauncher: Starting rooted Steam session
NovaLauncher: Permission denied
NovaLauncher: Nova launcher exited with status 13
NovaAudioBridge: audio_bridge=stopped frames=0 bytes=0
```

The Activity then opened Termux:X11 even though provisioning had failed. The
visible result was Termux:X11's black `Not connected` screen. This is a first-
launch UX defect: the app should not open the display surface or leave the
foreground service running after a root preflight failure. It should present a
retryable Magisk/root error instead.

## Diagnosis

Magisk's Superuser list showed `Nova Steam`
(`com.xjsonderulo.steamandroid.novalab`) disabled. Enabling that entry produced
the explicit confirmation `Superuser rights of Nova Steam are granted`.

This isolates the failure to per-package root authorization, not to the pinned
artifact URLs, storage, or APK helper execution. With the grant in place, a
manual root-side check successfully ran the packaged `nova-zstd` helper and
reported version 1.5.7. A bounded manual provisioner diagnostic also reached
the pinned Holo rootfs download phase before it was stopped; its staging was
then removed. The APK's provisioner and launcher code were not changed for
this diagnosis.

## Predeclared retry

Repeat the same clean-install profile with only the Magisk authorization state
changed:

1. clear the device log baseline;
2. launch the already installed APK and tap **Start Steam**;
3. observe the determinate phase/progress UI through rootfs, package closure,
   Steam seed, SteamRT, and atomic activation;
4. continue through native Steam OOBE to the QR/login surface if reached; and
5. record any remaining first-launch handoff or service-lifecycle defect.

Do not patch Steam OOBE views or change the display/network/game variables in
this retry. If provisioning succeeds, the next productization change should
make root denial a clearly handled preflight state and suppress the Termux:X11
launch on failure.
