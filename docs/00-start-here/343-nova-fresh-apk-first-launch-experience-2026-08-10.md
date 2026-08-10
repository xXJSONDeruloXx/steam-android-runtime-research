# Nova fresh APK first-launch experience — 2026-08-10

Status: the guarded purge, fresh APK install, first-run provisioning, native
Steam bootstrap update, OOBE, and QR login handoff all completed on the Nova.
The experience is usable, but not yet smooth: the native client update ends
the first one-click session and requires a second **Start Steam** tap.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`
- Run: `fresh-apk-20260810T180057Z`
- Repository: `main` at `62c7b5e` (`docs: record fresh APK OOBE QR result`)
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `244d13cf1dd40702719732c8db4a007f0c2a98bb22f4220f1e0ce4d1e2cf15e1`
- APK size: `3361472` bytes, version `0.3`, version code `3`
- Profile: direct Holo ARM64 glibc through Termux:X11, target surface
  `1280x960`, X11 `1280x800` stretched to the device surface, native Steam
  OOBE, software CEF, audio bridge, and uinput relay

The local QR screenshot was deleted immediately after inspection. No QR image,
Steam token, account name, password, or other authentication secret was
exported, backed up, or committed.

## Purge and first-run provisioning

The guarded scrub completed before installation:

```text
nova_device_scrub=pass scope=/data/local/tmp/nova*-and-listed-project-artifacts
nova_device_scrub=pass package_removed=1 termux_x11_preserved=1
```

The scrub removed the Nova APK, Nova app data, Nova-owned top-level temporary
runtime set, and the two explicitly listed legacy project artifacts. It did
not remove Termux:X11 or unrelated Android data. The freshly installed APK
then requested notification permission and a Magisk root grant; both prompts
were explicit and completed normally.

The first provisioning pass reported:

```text
nova_provision_root=uid0
nova_provision_free_kb=92421104 required=8388608
nova_provision_free_inodes=13483345 required=200000
nova_provision_steam_seed_rebase=pass prefix=20
nova_provision_active=pass root=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
nova_provision_status=pass version=nova-holo-direct-x11-20260810-v4
```

The activated runtime's hash manifest records:

```text
rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
steam_manifest_sha256=b81089d01988870f565fbc9f35b8de89b7f3658c4c5555bbe850ff742e3aef6f
steam_seed_sha256=b2de13c267e101679750445c9c449fbfb58dbb7c9851729e95ac69637b9df563
steamrt_snapshot=3c.0.20260714.251839
steamrt_sha256=f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0
package_closure_sha256=dbcf8284bac5877ff2c168bbaf55ad20d4a41910c7240cecbf70b16379aba515
turnip_driver_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
turnip_icd_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
package_closure_count=59
steam_data_policy=fresh-runtime-qr-login
auth_secrets_exported=0
gamescope_critical_path=0
ahardwarebuffer_critical_path=0
```

The Android UI displayed phase progress while the rootfs, package closure,
Steam seed, SteamRT, driver, and helper assets were acquired and verified.
Activation occurred only after the complete candidate passed validation.

## First Start: native Steam bootstrap update

The first **Start Steam** tap reached a live Termux:X11 surface and the real
Steam bootstrap updater. It downloaded and installed the `657758 KB` client
update. The display showed the native progress dialog throughout; there was no
gray SurfaceView or compositor failure.

After the update, the client exited normally, but the one-click supervisor did
not treat the bootstrap handoff as a request to relaunch. The Android app
returned to its home screen with:

```text
nova_launcher_client_exit=0
nova_launcher_stop=fail status=1
Nova launcher exited with status 1
```

This is the same first-launch handoff defect recorded in
[the earlier bootstrap result](341-nova-fresh-apk-steam-bootstrap-update-handoff-result-2026-08-10.md):
the native updater uses `logs/updateui_child.txt`, while the current supervisor
only watches the SteamUI restart marker. It is not evidence that provisioning
or the display path failed.

## Second Start: OOBE and QR

The second **Start Steam** tap was idempotent. The provisioner reported
`nova_provision_status=already-active`, and the runtime was not redownloaded.
The session recreated Termux:X11, the audio bridge, Steam, SteamWebHelper, and
the uinput relay. Controlled non-authentication input advanced the native OOBE
through:

1. English;
2. Eastern Standard Time; and
3. Continue with Android host network.

There was a short black transition after the network selection while Steam
reloaded its UI. Steam and SteamWebHelper remained alive, and the real Steam QR
sign-in page appeared afterward. The live device session was intentionally left
at that login handoff for the operator; no authentication action was taken.

The fresh SteamOS log still reports the expected host-contract gaps:

```text
SteamOSManager: daemon not present
SteamOSManager: failed to connect to OS service
Error: failed to initialize SteamOS telemetry service
jupiter-initial-firmware-update check returned: 127
Error: failed to run steamos-mandatory-update check
YldSetAtomUpdateProxyConfig: failed to set atomupd proxy: :0
```

Those missing Holo host services did not prevent this run from reaching QR.
The separate “Unable to download the required update (2)” failure remains a
distinct historical OOBE result and still needs a contract-level fix rather
than a view patch or unconditional-success shim.

## Acceptance

| Gate | Result |
| --- | --- |
| Exact project-state purge | pass |
| Fresh APK install | pass |
| First-run root prompt and provisioning | pass |
| Verified v4 runtime activation | pass |
| Native Steam bootstrap update | pass, but first session ends |
| Automatic post-bootstrap relaunch | fail; second tap required |
| Display through OOBE | pass |
| Language, timezone, host-network selection | pass |
| QR login handoff | pass after second tap |
| Signed-in Big Picture baseline | deferred; live QR handoff left running |

## Follow-up

1. Make the launcher recognize a completed native bootstrap handoff and perform
   one bounded automatic relaunch, while separating an already-absent X11
   cleanup result from the user-visible launch result.
2. Reconcile the launcher’s actual
   `nova_launcher_steamos_update_compat=enabled` marker with the home-screen
   text claiming the SteamOS host-update shim is disabled by default. The next
   run should make that setting explicit in the run identity.
3. Keep `steamos-manager`, `atomupd-manager`, and the mandatory-update helpers
   out of the critical display path until their exact Holo contracts are
   reproduced; this run confirms that the manager absence is observable but not
   the immediate reason QR was unreachable.
