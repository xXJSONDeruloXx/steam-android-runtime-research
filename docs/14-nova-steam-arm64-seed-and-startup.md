# Nova native ARM64 Steam seed and startup

Test date: 2026-08-07
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

## Steam launch result

Install the small additional Holo closure before repeating the launch:

```sh
HOLO_PACKAGES='gtk2-compat xorg-xauth xorg-xhost' \
  android/nova-lab/install-holo-packages.sh
HOLO_PACKAGES='ffmpeg' android/nova-lab/install-holo-packages.sh
```

Then run the bounded native client through Xwayland and Android output:

```sh
INSTALL_HOLO_GAMESCOPE=0 \
NOVA_XWAYLAND_ALLOW_LOCAL=1 \
NOVA_AHB_FRAME_COUNT=30 NOVA_AHB_WIDTH=960 NOVA_AHB_HEIGHT=540 \
NOVA_GAMESCOPE_AHB_CONTROL=android/nova-lab/device/gamescope-headless-steam-xwayland-control.sh \
NOVA_GAMESCOPE_AHB_SKIP_WAYLAND=1 \
NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM=1 \
NOVA_GAMESCOPE_AHB_XWAYLAND=1 \
  android/nova-lab/deploy-gamescope-headless-ahb-test.sh
```

The control launches the Xwayland server as root and, only when
`NOVA_XWAYLAND_ALLOW_LOCAL=1`, grants the selected Steam UID a local X11
connection with `xhost +SI:localuser:<uid>`. This is needed because Gamescope's
embedded Xwayland does not currently export an `XAUTHORITY` value to the
SteamRT child (`client_xauthority=unset`). The allowance is confined to the
disposable Xwayland instance.

The latest root-client run reached this boundary:

```text
client_sysv_sem_shim=pass
client_ffmpeg_avutil_compat=pass
client_sdl3_compat=pass
client_xhost_local_status=0
client_xhost_target=+SI:localuser:0
client_installed=absent
```

There was no `steamui.so` undefined-symbol failure after the adapters, and the
SteamRT update UI opened far enough to report its missing install manifest.
The report still has no `android_ahb_composite_frame=` marker because Steam has
not reached a persistent Gamepad UI window. The child update UI also reports
the expected Holo graphics gaps (`msm_drm_dri.so` absent and XRandR query
helpers unavailable) while Gamescope itself continues to use the known
software-glamor fallback.

## Network and bootstrap boundary

The Holo rootfs currently has only the connected WLAN subnet route and no
default route or DNS properties; `/etc/resolv.conf` is absent. Steam therefore
cannot download the channel manifest from inside the disposable namespace:

```text
Download failed: http error 0
Error: Steam needs to be online to update.
Unable to read and verify install manifest ...steamdeck_publicbetan_linuxarm64.installed
```

The next experiment is an offline bootstrap: use the host-verified Valve
manifest and seed to create the `.installed` package metadata and complete the
client tree without granting the rootfs a fabricated network configuration.
That result must be validated by Steam itself before it is treated as a real
client install. Login, Gamepad UI, `steamwebhelper`, controller input, and a
presented Steam frame remain open gates.
