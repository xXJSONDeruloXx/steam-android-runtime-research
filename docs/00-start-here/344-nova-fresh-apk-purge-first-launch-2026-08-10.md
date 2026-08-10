# Nova fresh APK purge and first-launch result — 2026-08-10

Status: the guarded device purge, fresh APK install, first-run provisioning,
native Steam bootstrap update, OOBE, and QR handoff all completed. The
display/network path is good. The first **Start Steam** tap still ends after
Steam's normal self-update and requires a second tap, so the experience is not
yet one-click smooth.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`
- Run: `fresh-apk-purge-20260810T1823Z`
- Repository: `main` at `dbdeee2` (`docs: record fresh APK first-launch experience`)
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `dc441bf7e756eb987e348ea617d111c31eae3aa4b61615a2c3ec9d60dbd56c3a`
- APK size: `3361472` bytes, version `0.3`, version code `3`
- Profile: direct Holo ARM64 glibc through Termux:X11, `1280x960` target
  surface, X11 `1280x800` stretch, native Steam OOBE, software CEF, audio
  bridge, and uinput relay

The QR screenshot was deleted immediately after inspection. No QR image,
Steam token, account name, password, or other authentication secret was
exported, backed up, or committed.

## Purge

The guarded scrub ran before installation:

```text
nova_device_scrub=pass scope=/data/local/tmp/nova*-and-listed-project-artifacts
nova_device_scrub=pass package_removed=1 termux_x11_preserved=1
```

The before inventory showed the prior APK, active runtime marker, versioned
runtime tree, launcher state, Steam tree, Termux:X11 process, and uinput relay.
The after inventory showed no Nova package, no `/data/local/tmp/nova*` path,
and no matching process. Termux:X11 remained installed. Available space rose
from `87047888` KB to `92444624` KB in the scrub inventory.

## First-run provisioning

The new APK requested notification permission and a Magisk root grant, then
kept its own UI visible while provisioning:

```text
nova_provision_root=uid0
nova_provision_free_kb=92425012 required=8388608
nova_provision_free_inodes=13483376 required=200000
nova_provision_steam_seed_rebase=pass prefix=20
nova_provision_active=pass root=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
nova_provision_status=pass version=nova-holo-direct-x11-20260810-v4
```

The pinned package and runtime artifacts matched the prior verified manifest:

```text
rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
steam_manifest_sha256=b81089d01988870f565fbc9f35b8de89b7f3658c4c5555bbe850ff742e3aef6f
steam_seed_sha256=b2de13c267e101679750445c9c449fbfb58dbb7c9851729e95ac69637b9df563
steamrt_snapshot=3c.0.20260714.251839
steamrt_sha256=f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0
package_closure_count=59
gamescope_critical_path=0
ahardwarebuffer_critical_path=0
```

The runtime marker was activated only after the staged tree passed validation.
The subsequent launch reused that active runtime without downloading it again.

## First Start: native Steam bootstrap

The first **Start Steam** tap opened the real Termux:X11 surface and Steam's
native `657758 KB` bootstrap update. The visible modal progressed from download
through extraction, installation, cleanup, and `Update complete, launching...`.
There was no display failure, missing-network error, or SteamOS update error.

Steam then shut down the bootstrap child normally. The client returned
`nova_launcher_client_exit=0`, but exact-scope teardown raced the Termux:X11
process shutdown and reported `nova_launcher_stop=fail status=1`; the Android
home screen showed `Nova launcher exited with status 1`. This is not a Steam
rendering crash. The client-side restart loop watches the SteamUI
`Restarting Steam` marker, while this fresh bootstrap path records its handoff
in `logs/updateui_child.txt` and creates the installed client marker instead.

## Second Start: OOBE and QR

The second **Start Steam** tap reused the active runtime and launched Steam with
the post-bootstrap flags. Controlled input advanced through:

1. English;
2. Eastern Standard Time; and
3. Continue with Android host network.

After a short black loading transition, the actual Steam sign-in page with a
live QR challenge appeared. Steam and SteamWebHelper remained alive, the
surface was visible, and the run was left at QR without authenticating.

The current SteamOS compatibility adapter was installed at the exact legacy
path and reported capability status `0`, then no-update status `7` for both
check/apply. Missing `SteamOSManager`, firmware-update, and mandatory-update
services remained logged warnings, but did not block this clean route.

## Acceptance

| Gate | Result |
| --- | --- |
| Exact project-state purge | pass |
| Fresh APK install | pass |
| Notification/root prompts | pass |
| Verified v4 runtime activation | pass |
| Native Steam bootstrap update | pass, but first session ends |
| Automatic post-bootstrap relaunch | fail; second tap required |
| Display through OOBE | pass |
| Language, timezone, host-network selection | pass |
| QR login handoff | pass after second tap |
| Signed-in Big Picture baseline | deferred at QR |

## Next change

Add one guarded relaunch inside the direct Steam client when all of these are
true: the run initially allowed native bootstrap, the installed-client marker
was absent before launch, Steam exited without timing out, and the marker is
present afterward. The relaunch will add the existing post-bootstrap flags and
will not change Steam's updater or fabricate an update-success result. Keep the
normal SteamUI restart limit separate so genuine failures still surface.
