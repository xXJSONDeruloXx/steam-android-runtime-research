# AYN Thor rootless public-seed refresh probe — predeclaration — 2026-08-11

Run identity: `thor-rootless-public-seed-refresh-20260811T153030Z`;
sub-run: `Thor-rootless-public-arm64-seed-normal-updater`.

Status: predeclared. This is an infrastructure/provenance probe required
because the exact sanitized rooted public client used by Nova R26–R31 is not
available in the current host workspace. It is not an R31 selector result and
must not be compared to R30/R31 as though the client bytes were fixed.

## Question

Can Valve's public ARM64 Steam seed update itself, under the app-UID Holo
rootless layout and direct Termux:X11 transport, to the same public-beta
client bytes that were previously copied from the rooted Nova tree? If so,
the resulting tree can be sanitized and independently hash-gated before a
real Thor R31 selector replication. If not, the exact client archive must be
transferred or recreated from the Nova public tree.

## Fixed scope

Target hardware and app state are the Thor R31 staging target:

```text
model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
```

Keep fixed:

- the verified Holo archive and app-UID atomic 161-package/GTK2 closure;
- app-UID PRoot `-0`, `/dev` and `/proc` bindings, inherited Android network,
  app-owned resolver, fresh state, and direct TCP Termux:X11
  `DISPLAY=127.0.0.1:77`;
- the nested client layout under
  `/opt/nova-steam/home/.local/share/Steam`;
- the rooted SteamRT-first `PATH`/`LD_LIBRARY_PATH` contract where files are
  available; and
- no Steam authentication state, QR/session data, cookies, userdata, or
  user configuration.

The input client is explicitly the older public seed bootstrap artifact:

```text
archive=android/nova-lab/build/steam-bootstrap/steam-home.tar.gz
archive_bytes=1756623692
archive_sha256=1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124
seed_version=1785979169
seed_sha256=1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82
```

The filename-only scan found no `loginusers.vdf`, `config.vdf`, `ssfn*`,
`registry.vdf`, `userdata`, `webstorage`, `htmlcache`, or cookie/auth paths.
The selected ARM64 files intentionally do not match the R31 rooted-client
hashes; that mismatch is the reason for this probe.

## One changed launch contract

Use the normal public-seed updater: omit
`-nobootstrapperupdate` and do not export `VK_DRIVER_FILES` or
`VK_ICD_FILENAMES`. Keep the provider files out of the effective Vulkan
environment for this refresh probe. Do not add Mesa overrides, `/dev/shm`,
D-Bus, Runtime 4, Proton, Gamescope/AHardwareBuffer, or SteamUI patches.

The other Steam flags remain:

```text
-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox
-skipinitialbootstrap -no-child-update-ui
```

## Evidence and outcome

Capture the exact initial and post-run client hashes, updater/bootstrap log,
Steam/SteamUI/webhelper milestones, X11 log, process/listener state, and a
screenshot with the Android log-consent gate handled. Classify as:

- `refresh-pass-exact-client` only if the resulting sanitized tree matches
  archive `4c62a8...` and the three selected R31 binary hashes;
- `refresh-pass-different-public-client` if it updates but produces another
  public tree; or
- `refresh-fail` if the seed cannot update or exits before producing a usable
  client tree.

No outcome closes Vulkan, WSI, `/dev/shm`, D-Bus, or SteamUI. After capture,
remove only this run's app/device/Termux scopes and terminate the exact fresh
X11 process. Restore the Thor Termux `allow-external-apps` file from its
run-scoped backup. Do not claim Nova rollback-path preservation on Thor.
