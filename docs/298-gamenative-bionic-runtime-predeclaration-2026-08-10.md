# GameNative Bionic runtime predeclaration — 2026-08-10

## Goal

Run the official GameNative Proton 11 ARM64EC payload through the Android
Bionic runtime boundary that GameNative actually uses, then try Geometry Wars
against the existing signed-in Steam prefix and Termux:X11 display. This is the
follow-up to the glibc-rootfs control in document 297, which stopped at the
missing `/system/bin/linker64` interpreter before Wine started.

The experiment is intentionally staged and run-scoped. It must not modify the
persistent Nova glibc rootfs, Steam client files, or the AppID 8400 prefix
except for files that are backed up and restored byte-for-byte.

## Hypothesis and controls

GameNative and WinNative do not solve this through a special Proton swapchain
patch. Their relevant compatibility boundary is an Android/Bionic process:

1. invoke the Bionic ARM64EC Wine executable through Android's
   `/system/bin/linker64`;
2. provide GameNative's Bionic imagefs libraries, including X11, Vulkan,
   `libandroid-sysvshm.so`, and `libevshim.so`;
3. preload the Bionic redirect library used by modern Android builds;
4. keep the existing X11 endpoint and Nova Vulkan/WSI layer as the display
   control; and
5. set `HODLL=libwow64fex.dll` for Proton 11 ARM64EC.

The first gate is a Bionic `wine --version`/loader smoke test. Only if that
gate starts successfully will the run attempt Geometry Wars. A successful
Wine start without a game frame will be classified separately from an ABI
failure and a Vulkan/WSI failure.

## Run identity and provenance

- Predeclared run ID:
  `nova-game-gamenative-bionic-geometry-wars-20260810T131000Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Persistent rootfs (read-only test input): `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Display: the existing one-click Termux:X11 `:0` session, Android
  `1280x960`, stretched X11 `1280x800`
- GameNative source revision:
  `4c3269c63851849fbe16e462733494755ce47524`
- WinNative source revision:
  `89daef3bc5693762868b2254054b47f4cdf27edf`
- GameNative Proton Wine source revision:
  `147d88ee0c4eee8b356110dd0c53cc44b7515f73`
- Proton WCP URL:
  `https://downloads.gamenative.app/proton-11.0-1-arm64ec.wcp`
- Proton WCP SHA-256:
  `be248bf8baf354c4426f997605c6b78debbc93b091a3be3339c1bbc2176b596f`
- GameNative APK source URL:
  `https://downloads.gamenative.app/releases/1.1.1/gamenative-v1.1.1.apk`
- GameNative APK SHA-256:
  `3276618c1a11d49cc28586629031184493dfda000e1a309b93443b22f68e7d8a`
- Bionic imagefs primary URL:
  `https://downloads.gamenative.app/imagefs_bionic.txz`
- Bionic imagefs fallback URL:
  `https://pub-9fcd5294bd0d4b85a9d73615bf98f3b5.r2.dev/imagefs_bionic.txz`
- Bionic imagefs size:
  `183506500` bytes compressed, `841.6 MiB` uncompressed
- Bionic imagefs ETag:
  `"097908c18db114f071716b5898c3a80f"`
- Bionic imagefs SHA-256:
  `368db62bfc58b72c97e5169bda9aa64d4246f07964c447e27c79a065e7e9c48b`
- APK `redirect.tzst` extracted `libredirect-bionic.so` SHA-256:
  `a6a0ee59bac93112f84bf75994def7607a278e8cb011a6e23414cb0107abc2cd`

## Planned staging

The imagefs archive and extracted runtime will live only under the run's
temporary device directory. The archive is not copied into Git. The WCP,
WSI layer, redirect library, and any generated Android-path ICD manifest will
also use run-scoped paths.

The Bionic launcher will model GameNative's environment rather than the
previous chroot wrapper:

```text
DISPLAY=:0
HOME=<run imagefs>/home/xuser
PATH=<WCP>/bin:<run imagefs>/usr/bin
LD_LIBRARY_PATH=<run imagefs>/usr/lib:/system/lib64:<WCP>/lib
ANDROID_SYSVSHM_SERVER=<run imagefs>/tmp/.sysvshm/SM0
LD_PRELOAD=<run imagefs>/usr/lib/libandroid-sysvshm.so:<run lib>/libevshim.so:<run imagefs>/usr/lib/libredirect-bionic.so
REDIRECT_EXEC__PROC_SELF_EXE=<WCP>/bin/wine
WINEPREFIX=<persistent AppID 8400 prefix>
HODLL=libwow64fex.dll
WINE_X11FORCEGLX=1
WINE_NEW_NDIS=1
```

Because this is not a chroot, the run will use an Android-visible copy of the
Nova ICD manifest whose `library_path` points at the persistent driver file by
its full Android path. The X11 socket will be exposed to the Bionic process in
its private mount namespace at `/tmp/.X11-unix/X0`; the socket itself remains
the one created by the existing launcher.

## Acceptance and teardown

Capture, with the same run ID:

- archive, WCP, APK-derived library, ICD, WSI manifest/library, wrapper, and
  game hashes;
- fresh parent-session readiness and X11 screenshot evidence;
- Bionic loader smoke status/output;
- Wine, DXVK, Vulkan, and Geometry Wars process/log evidence;
- screen capture checksum before and after the game attempt;
- exact AppID 8400 prefix hashes before and after; and
- exact-scope launcher, X11, Wine, and temporary-file cleanup markers.

The result will be one of:

- **Bionic ABI gate passed, game reached rendering**;
- **Bionic ABI gate passed, game failed in Wine/translation**;
- **Bionic ABI gate passed, Vulkan/WSI failed**; or
- **Bionic ABI gate failed**, with the first failing loader/library boundary.

Regardless of outcome, the run-scoped archive and device staging will be
removed after evidence capture. The persistent prefix must be restored and
verified before the next experiment.

