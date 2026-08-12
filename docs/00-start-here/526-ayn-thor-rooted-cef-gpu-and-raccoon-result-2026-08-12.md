# AYN Thor rooted CEF GPU and RACCOIN result — 2026-08-12

Status: pass for the interim rooted display/game path. This record does not
claim that the official Nova Steam Proton launch path is complete.

## Run identity and provenance

- Device: AYN Thor, serial `d234a848`.
- Repository branch: `feat/rooted-cef-gpu-games`.
- Active rooted Steam run: `20260812T214550Z-13875`.
- Rootfs: `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs`.
- Game display endpoint: `unix:/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/tmp/.X11-unix/X0`.
- Installed Nova APK SHA-256: `761037ccc461c10a1d7dfa71ccfa433b80184d01274259ac4b4409685a675cb5`.
- GameNative source checkout: `4c3269c63851849fbe16e462733494755ce47524`.
- GameNative ARM64EC Wine launcher SHA-256: `d01ee33c36225c9f21db568a32fa0795651b91ee35db21d1fe364758d7d865d9`.
- GameNative EVSHIM SHA-256: `383a5ae1b9daebcefd73bf1b3b85b1224a52ac02242c2b738562df260d5f6a4e`.

The game payload was already installed in the GameNative Steam library:
`RACCOIN.exe` is a PE32+ x86-64 executable and its installed directory is
approximately 509 MiB. To satisfy the Bionic redirect layer's path contract,
the game directory was copied into the app-owned imagefs temporary directory
before launch; no authentication data was copied.

## Acceptance result

The exact production-style GameNative invocation was:

```text
wine explorer /desktop=shell,1280x960 RACCOIN.exe
```

The repeatable environment wrapper is
`android/nova-lab/device/nova-gamenative-rooted-bionic-game.sh`; it takes the
rootfs, GameNative imagefs/Wine/prefix paths, EVSHIM path, game path, and
explicit X11 display as arguments.

with the GameNative ARM64EC/FEX environment, the rooted Nova X11 socket above,
and the production prefix at `imagefs/home/xuser/.wine`.

Same-run evidence:

- `RACCOIN.exe` remained alive as the app UID while the screenshot was taken.
- Screenshot: `/tmp/nova-raccoon-success.png`.
- Screenshot SHA-256: `cb879be1e5319b75136c1856bcb4bb7e9f3c1fa86082779f015ee5b3363f660d`.
- The screenshot shows the RACCOIN playable main menu, not a Wine or Steam
  placeholder.
- The game log reported DXVK `2.4.1`, Vulkan, `Turnip Adreno (TM) 740`, Mesa
  driver `25.1.99`, Vulkan 1.3, and repeated X11 surface presents.
- The rooted input relay resolved the physical Xbox Wireless Controller at
  `/dev/input/event9` and exposed the virtual Xbox controller at
  `/dev/input/event11` while the game ran.

## Related rooted improvements

- Steam CEF GPU mode is enabled through the exec-boundary environment shim;
  the installed APK contains the updated shim and the standalone GPU child
  reached the compositor/GL 4.6 path.
- The root launcher now discovers the Xbox Wireless Controller from
  `/proc/bus/input/devices` instead of relying only on the historical event-7
  fallback.
- The rootless session guard now accepts the actual `/dev/null` symlink text on
  a second run.

## Remaining boundary

The official Nova Steam Proton 11 ARM64 path still stops at Runtime 4 user
namespace setup or the FEX CPU-feature probe. This successful game result is
therefore an interim, app-side Bionic GameNative compatibility-layer launch
using the rooted Nova X11 display and hardware Vulkan path; it has not replaced
Nova's rooted Holo/direct-X11 architecture with GameNative's PRoot stack.
