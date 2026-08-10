# Nova x86-64 compatibility-runtime inventory — 2026-08-10

Status: predeclared; device result pending.

## Question

The 198X command-line launch now reaches the signed-in Steam client but does
not create a compatibility-runtime child. Before changing Proton, Gamescope,
or controller handling, inventory the exact x86-64 execution options already
available on the Nova and inside the ARM64 Steam rootfs.

This is a read-only, no-input inventory. It will not launch Steam, Proton,
Wine, an emulator, or a game; it will not modify the rootfs, Termux:X11
preferences, Steam account/content, or Android settings.

## Predeclared run

Run ID: `compat-20260810T005559Z-x86-runtime-inventory`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `fa52c37`;
- rootfs `/data/local/tmp/nova-holo-rootfs`, currently clean after the
  198X CLI experiment;
- installed 198X executable and SteamLinuxRuntime/Proton directories are
  inventory targets only;
- no physical, synthetic, keyboard, pointer, touch, or controller input.

The bounded probes will record:

1. Android ABI/kernel state and any registered `binfmt_misc` handlers;
2. exact candidate paths for Box64, FEX-Emu, QEMU-user, proot, Wine, and
   related launchers in the device and rootfs search scope;
3. candidate file sizes, owners, SHA-256 values, and ELF machine headers;
4. the installed 198X, Proton, and pressure-vessel architecture metadata;
5. the current Nova process table before and after the read-only probes.

The inventory will not infer availability from package names alone. A
candidate is useful only if its path, executable mode, architecture, and
required supporting files are visible in the captured evidence. No candidate
will be executed in this run.

## Decision boundary

The result will separate four cases:

- no translator/emulator is present in the scoped device or rootfs paths;
- a candidate is present but is not executable or is the wrong architecture;
- a candidate is present and executable, but its runtime dependencies are
  incomplete; or
- a usable candidate is present and should receive a separate, explicitly
  predeclared launch experiment.

This run cannot prove that 198X renders. It only determines whether the next
game-launch experiment should investigate an existing translator, package a
translator, or stop treating the current ARM64 rootfs as an x86 game runtime.

## Cleanup contract

The exact Nova/X11 and rootfs cleanup helpers will be checked before the
inventory and again at exit. Since this run launches no process, success still
requires a fresh final process table with no Nova rootfs, Steam, Gamescope,
X11, compatibility-runtime, or relay process. No run-scoped device files will
be retained.
