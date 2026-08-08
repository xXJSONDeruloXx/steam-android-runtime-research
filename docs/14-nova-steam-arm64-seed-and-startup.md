# Nova native ARM64 Steam seed and startup

Test date: 2026-08-08
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`

This checkpoint stages Valve's native ARM64 Steam client and SteamRT3C runtime
inside the disposable Holo glibc rootfs, then launches the real Steam process
through the already-proven Xwayland → Gamescope → Android AHardwareBuffer path.
It is a startup and ABI investigation, not a Steam UI acceptance result.

## Resolved inputs

The checked-in fetch script resolves moving Valve metadata at run time and keeps
the large artifacts in the ignored `android/nova-lab/build/steam-arm64/`
directory:

```text
client_version=1785979169
seed_package=bins_linuxarm64_linuxarm64.zip.0f238017c65e844f71581d1fae8fb42f410e1032
seed_size=109767361
seed_sha256=1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82
runtime_snapshot=3c.0.20260714.251839
runtime_size=52343604
```

Fetch and deploy the seed with:

```sh
android/nova-lab/fetch-steam-arm64-seed.sh --all
NOVA_STEAM_UID=1000 NOVA_STEAM_GID=1000 \
  android/nova-lab/deploy-steam-arm64-seed.sh
```

The Valve seed is a self-extracting ZIP with a short prefix that Android's
toybox `unzip` rejects. The deploy script extracts it on the host, pushes the
ARM64 tree, extracts the runtime as an uncompressed tar because toybox has no
XZ filter, creates the `.steam` layout and `steamdeck_publicbeta` beta file,
and normalizes versioned runtime SONAME links. The device-side validation
reported:

```text
steam_seed_deploy=pass
steam=.../steamrtarm64/steam
steamui=.../steamrtarm64/steamui.so
libibus=.../lib/aarch64-linux-gnu/libibus-1.0.so.5
```

No Valve binary or runtime archive is committed to this repository.

## Synchronization boundary

The existing ARM64 probe was extended with the exact System V semaphore subset
used by Steam's `libtier0_s.so`:

```text
sysv_semget=fail errno=38 error=Function not implemented
sysv_semctl_setval=skip
sysv_semop_down=skip
sysv_semop_up=skip
sysv_semctl_rmid=skip
posix_sync_status=fail failures=1
```

All POSIX semaphore, mutex/condition-variable, pthread, eventfd, pipe, futex,
and shared-memory checks passed. Static inspection of the native seed maps
Steam's `CThreadEvent` startup path to `semget`, `semctl(SETVAL)`, and
`semop`, explaining the earlier `semaphore creation failed Function not
implemented` assertion.

`android/nova-lab/device/sysv-sem-shim.c` is an explicitly experimental
LD_PRELOAD adapter. It maps the one-semaphore System V operations onto named
POSIX semaphores in the private Holo `/dev/shm` mount. With the adapter enabled,
the Steam startup trace no longer contains the `threadtools.cpp:2526` semaphore
assertion. This is a measured workaround for the disposable lab rootfs, not a
kernel or production System V implementation.

## Loader compatibility adapters

The Steam seed and the current Holo/SteamRT libraries are close enough to load
but not ABI-identical. The following adapters are built for ARM64 against the
Holo sysroot and are loaded only for the bounded Steam process:

- `libffmpeg-avutil-compat.so` forwards Steam's tracked allocator entry points
  and consumes `av_register_malloc` while retaining Holo's `libavutil`.
- `libsdl3-compat.so` provides the SDL 3.6 `SDL_TryLockJoysticks` symbol using
  the older `SDL_LockJoysticks`/`SDL_UnlockJoysticks` ABI available in the
  current runtime. Its blocking behavior is intentionally conservative for
  this startup experiment.
- Holo's newer `libstdc++.so.6`, `libgcc_s.so.1`, and VA-API libraries are
  preloaded because the SteamRT closure requires newer C++/GCC symbols and
  `vaMapBuffer2` than its bundled copies provide.

Build them with:

```sh
android/nova-lab/build-sysv-sem-shim.sh
android/nova-lab/build-ffmpeg-avutil-compat.sh
android/nova-lab/build-sdl3-compat.sh
```

The adapters are intentionally separate and logged in
`/tmp/nova-steam-client.log`; a later implementation should replace each with
a matched library set or a real upstream ABI contract.

## Completed client tree and runtime closure

The seed alone is not the same thing as a completed Steam install. For the
current test tree, the host-side Armada bootstrap generator was run under an
ARM64 Linux container against the same Valve metadata. It produced 39 package
files, 28 compressed payloads, an ARM64 `steamui.so`, and a valid
`package/steam_client_steamdeck_publicbeta_linuxarm64.installed` file. The
expanded Steam home was transferred to the disposable rootfs and measured at
about 3.2 GiB.

The Holo package named `gtk2-compat` only provides compatibility metadata; it
does not contain the GTK2 runtime that `steamui.so` needs. The actual GTK2
runtime used for this run was Arch Linux ARM `gtk2 2.24.33-2`:

```text
gtk2-2.24.33-2-aarch64.pkg.tar.xz
sha256=a2927d0e2b2b3e0b8e13cfb88adfa947a449d93856abd782f08dae5aee5aad40
```

Its versioned `libgtk-x11-2.0.so.0`, `libgdk-x11-2.0.so.0`, and `libgailutil.so`
files were extracted on the host and installed into the disposable rootfs.
Holo's `nss` and `nspr` packages were also installed so the direct
`steamwebhelper` dependency check resolves `libnss3`, `libnssutil3`,
`libsmime3`, and `libnspr4`. This makes the current failure a startup/lifecycle
boundary rather than an already-observed direct ELF dependency omission.

The repository's `fetch-steam-arm64-seed.sh` and
`deploy-steam-arm64-seed.sh` remain the reproducible Valve-input path. The
large generated bootstrap tree and GTK2 package stay in ignored build output;
neither is redistributed by this repository.

## Steam launch result

Install the Holo X11/crypto/media closure first. `gtk2-compat` is useful for
package resolution, but the real GTK2 runtime must be staged separately as
described above:

```sh
HOLO_PACKAGES='gtk2-compat nss nspr xorg-xauth xorg-xhost ffmpeg' \
  android/nova-lab/install-holo-packages.sh
```

Then run the bounded native client through Xwayland and Android output using
the checked-in convenience wrapper:

```sh
NOVA_AHB_FRAME_COUNT=30 \
  android/nova-lab/deploy-native-steam-smoke-test.sh
```

The control launches the Xwayland server as root and, only when
`NOVA_XWAYLAND_ALLOW_LOCAL=1`, grants the selected Steam UID a local UNIX X11
connection with `xhost +local:`. This is needed because Gamescope's embedded
Xwayland does not currently export an `XAUTHORITY` value to the SteamRT child
(`client_xauthority=unset`). The allowance is confined to the disposable
Xwayland instance.

The latest accepted run recorded:

```text
rootfs.resolv_conf=generated:192.168.0.1
Android AHardwareBuffer output imported: 2 x 960x540 RGBA
Starting Xwayland on :0
android_ahb_target_reached=5
offscreen_probe_status=0
probe_status=0
client_started=pass
client_installed=pass
client_preload_profile=sysv
client_status=1
Using update UI: glx
native_steam_smoke=pass
```

The Android app log independently recorded five frames, five successful Linux
acquire-fence handoffs, five completed SurfaceControl frames, and four returned
release fences. This proves the native Steam process can load the installed
ARM64 client, create its GLX update UI, and cross the existing Xwayland ->
Gamescope -> AHardwareBuffer path. It does not yet prove that the Steam UI
stays alive.

The remaining native-client boundary is:

```text
src/common/framefunction.cpp (238) : Assertion Failed:
CFrameFunctionMgr::~CFrameFunctionMgr: non static FrameFunction[Bootstrapper HTTP Client] still registered
client_status=1
steamwebhelper: not exec'd by the client in this run
```

`steamui.so` and the direct `steamwebhelper` dependency closure no longer show
missing GTK2/NSS/NSPR symbols, so the next investigation should follow the
bootstrapper HTTP-client teardown and child-process launch rather than add
another unverified library blindly. Login, persistent Gamepad UI, controller
input, and a presented Steam frame remain open gates.

## Non-root host and webhelper startup

Running the completed tree as the Steam-style non-root account produced a
different and more useful boundary than the root launch. The seed deployer can
make this choice reproducible with `NOVA_STEAM_UID` and `NOVA_STEAM_GID`; the
control reads the resulting `/opt/nova-steam/run-as-user` marker and drops from
the root Holo launcher to that uid before starting Steam:

```sh
NOVA_STEAM_UID=501 NOVA_STEAM_GID=20 \
  android/nova-lab/deploy-steam-arm64-seed.sh

NOVA_AHB_FRAME_COUNT=5 \
NOVA_STEAM_CLIENT_TIMEOUT=45 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=75 \
  android/nova-lab/deploy-native-steam-smoke-test.sh
```

The accepted bounded run recorded:

```text
client_uid=501
client_gid=20
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
native_steam_smoke=pass
```

Unlike the earlier root run, the Steam parent stayed alive for the full client
budget and generated the normal host/UI logs. The strongest startup evidence is
in `steamui_html.txt`:

```text
Started webhelper process 16548
CreateBrowser id:1820017951 type:12 ...
CreateResponse: ... handle:65536
BrowserReady: handle:65536
```

The same run produced a Chromium DevTools endpoint, a GPU report identifying
Mesa `softpipe` under X11, and a live IPv4 connectivity test to Steam. This is
the first proof that the native ARM64 Steam parent can launch its CEF helper and
create a browser in the Android/Xwayland environment. It is still not a final
Steam UI result: the SteamUI websocket could not connect back to the host, no
presented Steam frame was observed, and the bounded timeout terminated the
session.

The remaining environmental errors are now concrete rather than speculative:

```text
XDG_RUNTIME_DIR ... is not owned by us (uid 501), but by uid 0
Cannot spawn a message bus without a machine-id
.../steamrtarm32/gldriverquery: No such file or directory
.../steamrtarm32/vulkandriverquery: No such file or directory
```

The current run also still reports expected disposable-rootfs limitations such
as no system SteamOS D-Bus service, `lspci`, `xwininfo`, or XRandR output
backend. These do not prevent the helper from reaching `BrowserReady`. The
large raw client and helper logs are pulled into ignored
`android/nova-lab/build/` files for diagnosis and are not committed.

## Normal bootstrap/update boundary

The `skip` smoke mode above is useful for fast ABI and compositor checks, but it
does not exercise the normal updater lifecycle. A longer run with
`NOVA_STEAM_BOOTSTRAP_MODE=normal` was therefore used against the complete tree:

```sh
NOVA_STEAM_BOOTSTRAP_MODE=normal \
NOVA_STEAM_CLIENT_TIMEOUT=180 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=220 \
NOVA_AHB_FRAME_COUNT=5 \
android/nova-lab/deploy-native-steam-smoke-test.sh
```

This run established a separate, later boundary:

```text
Downloaded new manifest: ... version 1786141909, installed version 1785979169
Process started ... -child-update-ui ...
Using update UI: glx
Download complete.
Installing update...
Extracting package...
client_status=124
```

The client downloaded the full 209770 KB update over the rooted Android network
namespace and began extracting it into Steam's package staging directory before
the bounded 180-second client budget expired. Gamescope still reached
`android_ahb_target_reached=30`, `offscreen_probe_status=0`, and `probe_status=0`.
No `steamwebhelper` launch or persistent Steam UI was observed in this run. The
timeout is now propagated through the probe and stored in the disposable rootfs
so the next run can reuse the downloaded package with a longer installation
window.

The promoted client was then launched with the updater bypassed. It reported
the new build and reproduced the same early lifecycle failure across the Deck,
desktop, `-vgui`, `-console`, and `-inhibitbootstrap` profiles:

```text
Startup - updater built Aug  7 2026 20:15:47
Init: Installing breakpad exception handler for appid(steam)/version(1786141909)
Using update UI: glx
src/common/framefunction.cpp (238) : Assertion Failed:
CFrameFunctionMgr::~CFrameFunctionMgr: non static FrameFunction[Bootstrapper HTTP Client] still registered
client_status=1
```

This isolates the current failure from the initial Valve download, from the
Steam Deck flags, and from the old seed binary. The updated native client still
creates the GLX update window and crosses the five-frame Xwayland to Android
buffer run, but it does not launch `steamwebhelper` before shutting down.

## Direct steamwebhelper loader smoke

The control now accepts `NOVA_STEAM_EXECUTABLE` for a bounded diagnostic. This
allows the shipped helper to be run under the same Holo loader, Xwayland, and
preload environment without pretending that a helper with no Steam host IPC is
a full UI session:

```sh
NOVA_STEAM_EXECUTABLE=/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steamwebhelper \
NOVA_STEAM_CLIENT_FLAGS='--version' \
NOVA_STEAM_BOOTSTRAP_MODE=skip \
NOVA_STEAM_CLIENT_TIMEOUT=30 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=60 \
NOVA_AHB_FRAME_COUNT=5 \
NOVA_GAMESCOPE_AHB_SKIP_WAYLAND=1 \
NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM=1 \
NOVA_GAMESCOPE_AHB_XWAYLAND=1 \
NOVA_GAMESCOPE_AHB_CONTROL=android/nova-lab/device/gamescope-headless-steam-xwayland-control.sh \
android/nova-lab/deploy-gamescope-headless-ahb-test.sh || true
```

The diagnostic exits after the helper terminates because no hosted Steam window
can produce the normal AHardwareBuffer frame markers. For this direct helper
case, pull the device logs explicitly if they are needed for diagnosis; the
hosted native-client wrapper automatically collects its bounded client logs in
`android/nova-lab/build/`.

The direct executable smoke produced:

```text
client_executable=/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steamwebhelper
client_status=0
Chromium 126.0.6478.183
```

`ldd` also resolves the helper's GTK2, NSS/NSPR, CEF, X11, GL, and media
dependencies in the Holo rootfs. The helper's version path exits before creating
a Steam-hosted window, so the missing persistent frame remains a Steam parent
bootstrap/IPC problem rather than proof that the final CEF UI works.

## Runtime experiments that did not become defaults

The Holo Mesa stack must stay ahead of SteamRT's Mesa libraries. Reversing that
order immediately returned the earlier `libgbm`/GLX segmentation fault. A
second experiment split SteamRT X11/XCB libraries from Holo Mesa/DRM libraries;
it also segfaulted during Steam GLX startup and was removed from the runtime
path. These are useful negative results, not supported launch profiles.

With the default Holo `msm`/`kgsl` path, the device reached a SIGILL in
Holo Mesa's anonymous JIT code. The captured instruction was an ARM SVE
`index` instruction while the Nova's `/proc/cpuinfo` exposed no SVE feature;
`LP_NATIVE_VECTOR_WIDTH=128` did not prevent it. `swrast` plus `softpipe`
avoids that fault and is the current software-rendering control. Hardware
Mesa/Turnip Steam UI rendering is therefore a separate open issue.

## Network and bootstrap boundary

The chroot shares the rooted Android network namespace. The probe now derives
the active Android default gateway and generates `/etc/resolv.conf` for the
disposable rootfs; an in-chroot `curl -I` to Valve's client manifest returned
HTTP 200. This removes the earlier DNS hypothesis. The fast `skip` launch still
stops with the `Bootstrapper HTTP Client` assertion above, while the longer
normal launch now reaches the update download and extraction stages, so network
reachability and Steam bootstrap completion remain separate measurements:

```text
chroot curl -I https://client-update.steamstatic.com/steam_client_steamdeck_publicbeta_linuxarm64
HTTP/2 200
CFrameFunctionMgr::~CFrameFunctionMgr: non static FrameFunction[Bootstrapper HTTP Client] still registered
```

The next bootstrap experiment is to let the package installation finish, then
capture the post-update client restart and `steamwebhelper` launch. Login,
Gamepad UI, controller input, and a presented Steam frame remain open gates.
