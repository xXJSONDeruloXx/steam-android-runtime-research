# Nova fresh APK bootstrap, OOBE, and QR result — 2026-08-10

Status: pass. A clean-device run with the current APK provisioned the Holo
ARM64 runtime, completed Steam's native bootstrap update, automatically
relaunched the client, reached the host-network OOBE path, and displayed the
Steam QR sign-in page. No second **Start Steam** tap was required after the
bootstrap update.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`
- Run: `fresh-apk-bootstrap-network-fix-20260810T225411Z`
- Repository: `main` at `0492c04` (`fix: reapply network adapter after bootstrap relaunch`)
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `4fe7660e809ca424c970a35f4685b6b3f779014e942a85279fae9dcb4de7519b`
- APK size: `3361472` bytes, version `0.3`, version code `3`
- Profile: direct Holo ARM64 glibc through Termux:X11, `1280x960` target,
  software CEF, audio bridge, and the current input relay

The device was scrubbed with the exact Nova scope before installation. The
scrub passed with `package_removed=1` and `termux_x11_preserved=1`. The first
tap was correctly interrupted by Android's notification permission dialog; a
separate setup-only attempt was rejected by Magisk and is not counted as the
runtime result. After explicitly granting Nova Steam root access, the clean
run below completed normally.

No Steam authentication secret was exported or backed up. The QR screenshot
was inspected only as transient evidence and deleted immediately; no QR image,
token, account name, or password is retained.

## Fresh first-launch sequence

Provisioning kept the Nova APK visible while downloading and validating the
versioned runtime and package closure:

```text
nova_provision_root=uid0
nova_provision_free_kb=92426164 required=8388608
nova_provision_free_inodes=13483345 required=200000
nova_provision_steam_seed_rebase=pass prefix=20
nova_provision_active=pass root=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
nova_provision_status=pass version=nova-holo-direct-x11-20260810-v4
```

The verified v4 artifacts and SteamRT3C ARM64 seed were staged atomically;
Gamescope/AHardwareBuffer remained outside the critical path. The native
Steam updater then displayed its normal `657758 KB` update modal and completed
its download/install handoff.

The fresh client log proves the relaunch and network-adapter boundary:

```text
client_attempt_status=42
client_bootstrap_handoff=1
client_steamui_present_after_bootstrap=1
client_network_api_compat_status=0
client_bootstrap_relaunch=1
client_flags_relaunch=... -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
client_attempt=2
client_attempt_status=42
client_bootstrap_handoff=0
client_attempt=3
```

The adapter was initially deferred because SteamUI did not exist yet. The
relaunch re-evaluated SteamUI, applied the existing network compatibility
rewrite successfully, and continued in the same X11 session. This closes the
previous result in [346](346-nova-bootstrap-relaunch-network-gap-2026-08-10.md),
where OOBE showed **No networks found** after the automatic relaunch.

The visible OOBE path then proceeded through the language/timezone setup and
the network selection page. **Continue with Android host network** was
accepted, and the Steam sign-in page with a live QR challenge appeared. The
operator performed the final network selection manually during the clean run;
no authentication was attempted afterward.

## Acceptance

| Gate | Result |
| --- | --- |
| Exact project-state purge | pass |
| Fresh APK install | pass |
| Root and free-space gates | pass |
| Verified Holo/SteamRT3C provisioning | pass |
| Native Steam bootstrap update | pass |
| Automatic post-bootstrap relaunch | pass; no second Start tap |
| Network adapter after relaunch | pass; status `0` |
| Language/timezone/network OOBE | pass |
| QR login handoff | pass |
| Signed-in Big Picture baseline | intentionally deferred |

The current display, network path, and QR handoff are therefore ready to ship
on `main`. The next product work can focus on making the provisioning screen
more polished and on the post-login controller/audio/game-launch baseline;
Gamescope/AHardwareBuffer remains optional rather than part of this critical
path.
