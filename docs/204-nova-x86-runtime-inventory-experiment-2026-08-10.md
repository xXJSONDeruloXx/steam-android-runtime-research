# Nova x86-64 compatibility-runtime inventory — 2026-08-10

Status: complete; no x86-64 user-mode translator or emulator was found in
the scoped device/rootfs inventory.

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

## Device result

The Nova reports `uname -m=aarch64` and Android ABI `arm64-v8a`. The scoped
device and rootfs searches returned no exact executable or symlink basename
for Box64, Box86, FEX, QEMU x86 user mode, proot, Wine, or ExaGear. The
`binfmt_misc` directory exists, but its status file and registration list are
absent. No candidate was executed.

The installed game/runtime architecture is internally consistent with the
earlier launch failure:

- `198X.exe` is an MS PE32+ x86-64 executable, SHA-256
  `ce03bffd959a5153fddf2af1565700ce7d29d7ca67028e86e097ae67f08c8730`;
- both installed `pressure-vessel-wrap` copies are ELF64 x86-64, SHA-256
  `d591669878339b21bffeaa68c8ad7c2b5d51d01f91cabe1c87e6c3e7c2aeb554`;
- both wrappers request `/lib64/ld-linux-x86-64.so.2`;
- the rootfs exposes `/usr/lib/ld-linux-aarch64.so.1` and no x86-64 loader;
- the installed Proton entries are Python scripts, not an architecture
  translation layer.

The result is therefore the first inventory case: no usable x86-64
translator/emulator is present in the scoped device or rootfs paths. The
198X launch path cannot reach Proton/Wine until a compatible translation layer
is deliberately added or a native ARM64 game is used as a separate lifecycle
control.

The evidence bundle is
`/tmp/compat-20260810T005559Z-x86-runtime-inventory`, including the selected
artifact hashes, `file`/`readelf` output, candidate searches, cleanup markers,
and `evidence-sha256.txt`.

The preflight and postflight exact helpers both returned
`nova_x11_cleanup=pass` and `nova_runtime_cleanup=pass`. The final filtered
process table was empty for Nova, Steam, X11, compatibility-runtime, and relay
patterns. The Termux:X11 preferences remained at SHA-256
`25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895`, owner
`10120:10120`, mode `660`. Because the inventory exposed 226 ownerless
transient `dbus-*` and `steam_chrome_shmem_uid501_spid*` sockets left in the
rootfs `/tmp` by older sessions, those exact socket patterns were removed;
the post-cleanup socket search is empty. No Steam data, account state, or
installed game content was removed.

## Decision boundary

The result separated four cases:

- no translator/emulator is present in the scoped device or rootfs paths;
- a candidate is present but is not executable or is the wrong architecture;
- a candidate is present and executable, but its runtime dependencies are
  incomplete; or
- a usable candidate is present and should receive a separate, explicitly
  predeclared launch experiment.

This run cannot prove that 198X renders. It determines that the next
game-launch experiment must either package and explicitly validate a
translator, or stop treating the current ARM64 rootfs as an x86 game runtime
and use a native ARM64 control.

## Cleanup contract

The exact Nova/X11 and rootfs cleanup helpers will be checked before the
inventory and again at exit. Since this run launched no process, success still
required a fresh final process table with no Nova rootfs, Steam, Gamescope,
X11, compatibility-runtime, or relay process. No run-scoped device files were
retained.
