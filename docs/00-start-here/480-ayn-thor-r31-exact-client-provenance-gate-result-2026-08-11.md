# AYN Thor rootless R31 exact-client provenance gate — host-only result — 2026-08-11

Status: **R31 remains blocked by exact-client provenance.** This record closes
the required host-only gate before another Thor device mutation. No device was
changed and no Thor R31 launch was performed by this gate.

The predeclared R31 experiment requires the sanitized rooted public-beta
archive and selected ARM64 files used by the Nova R28 baseline. The declared
archive was not found in the permitted host roots or Git object history. The
only local Steam seed is an older public bootstrap with different bytes and
different selected files, so it cannot be relabeled as R31.

## Decision

Do not run [the Thor R31 predeclaration](475-ayn-thor-rootless-r31-vk-driver-files-replication-predeclaration-2026-08-11.md)
with the available seed. Recover the exact archive from a declared sanitized
source first. If only the sanitized tree is recovered, inspect the historical
packaging recipe and predeclare a separate full-tree equivalence gate; matching
selected files alone does not establish the declared archive hash.

The Vulkan-loader inspection is ready for a later valid R31 run, but it does
not prove that the loader accepted `VK_DRIVER_FILES`, opened the ICD, or
enumerated a physical device. No `VK_LOADER_DEBUG` variable was added.

## Host and repository provenance

```text
date=2026-08-11
branch=feat/rootless-steamclienttermux-profile
head=3264a9edd38d27f0dc450c8c4cb9921483499701
sibling=/Users/kurt/Developer/steamclienttermux
sibling_status=## main...origin/main
sibling_head=8d14c10195b34fe2714ba59df1680df27a852532
```

The host working tree already contained the README navigation edit and the
uncommitted Thor records 478 and 479. They were preserved; this document does
not overwrite or reset them.

The exact command records were:

```text
$ git status --short --branch
## feat/rootless-steamclienttermux-profile...origin/feat/rootless-steamclienttermux-profile
 M docs/README.md
?? docs/00-start-here/478-ayn-thor-rootless-public-seed-refresh-x11-foreground-result-2026-08-11.md
?? docs/00-start-here/479-ayn-thor-rootless-short-temp-public-seed-predeclaration-2026-08-11.md

$ git rev-parse HEAD
3264a9edd38d27f0dc450c8c4cb9921483499701

$ git log -8 --oneline
3264a9e docs: predeclare Thor X11 refresh rerun
02049aa docs: predeclare Thor public seed refresh probe
ec9fedd docs: predeclare AYN Thor rootless R31 replication
1f26e5a docs: audit SteamClientTermux upstream contracts
bc6d821 docs: record rootless R30 provider control
d3983c5 docs: record rootless R29 provider crash
50e8488 docs: predeclare rootless R29 KGSL provider parity
7f5f4d9 docs: record rootless R28 rooted environment result

$ git -C /Users/kurt/Developer/steamclienttermux status --short --branch
## main...origin/main

$ git -C /Users/kurt/Developer/steamclienttermux rev-parse HEAD
8d14c10195b34fe2714ba59df1680df27a852532
```

## Exact-client recovery gate

R31 requires:

```text
archive_bytes=3447515136
archive_sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
```

The permitted local public artifact is different:

```text
path=android/nova-lab/build/steam-bootstrap/steam-home.tar.gz
bytes=1756623692
sha256=1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124

path=android/nova-lab/build/steam-arm64/package/bins_linuxarm64_linuxarm64.zip.0f238017c65e844f71581d1fae8fb42f410e1032
bytes=109767361
sha256=1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82
```

The selected files extracted from the older bootstrap are also not the R31
files:

```text
steamrtarm64/steam       cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85
steamrtarm64/steamui.so  972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0
steamrtarm64/vgui2_s.so  a3e010415d3b1cda22a9fe6ad8e5a33e558113483cbc7639ec4cae560c676dd7
```

The documented exact-archive paths were checked without broad filesystem
searches and were all absent:

```text
/tmp/nova-r26-rooted-public-20260811T130824Z.tar                 absent
/tmp/nova-r27-rooted-public-20260811T133336Z.tar                 absent
/tmp/nova-r28-rooted-public.tar                                  absent
/tmp/nova-r29-rooted-public.tar                                  absent
/data/local/tmp/nova-r26-rooted-public.tar                      absent
/data/local/tmp/nova-r27-rooted-public-20260811T133336Z.tar      absent
/data/local/tmp/nova-r28-rooted-public.tar                       absent
```

The bounded Git object check also returned no exact archive object:

```text
$ git rev-list --objects --all | rg 'steam-home\.tar\.gz|nova-r(26|27|28|29).*public.*\.tar'
<no output>
```

No Steam userdata, authenticated home, login state, cookies, or personal
profile was searched or copied.

## Vulkan-loader readiness inspection

The fixed R28/R31 library order begins with:

```text
/opt/nova-steam/home/.local/share/Steam/steamrtarm64
/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu
/usr/lib
/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu
/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
```

The first existing `libvulkan.so.1` candidate is the bundled Steam client
loader. Its host-side inspection is:

```text
path=android/nova-lab/build/steam-bootstrap/home/.local/share/Steam/steamrtarm64/libvulkan.so.1
bytes=592464
sha256=d114974137bb80154f08c12531a2adef6431dde112566a0d2625e307fbd7eedf
file=ELF 64-bit LSB shared object, ARM aarch64, dynamically linked, stripped
strings=VK_DRIVER_FILES, VK_ICD_FILENAMES
```

The other static candidates also contain both selector strings:

```text
SteamRT3C libvulkan.so.1.3.239
  bytes=494120
  sha256=dfea51d13180fe78ca7c99dacc7898865a5e5bd31e4eee79fa03c0b5001d343c

Holo /usr/lib/libvulkan.so.1.4.328
  bytes=657480
  sha256=9858a253ce4a125eb0408f5b309657dd96f5f032b630d2cd8a54a8f445eda238
```

The [Khronos Vulkan loader contract](https://github.com/KhronosGroup/Vulkan-Loader/blob/main/docs/LoaderInterfaceArchitecture.md)
documents `VK_DRIVER_FILES` as the newer override and
`VK_ICD_FILENAMES` as its deprecated equivalent; it also documents the loader
version requirement for `VK_DRIVER_FILES`. The predeclared R31 selector is
therefore kept exact:

```text
unset VK_ICD_FILENAMES
export VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

Static presence of the strings is only a readiness check. A valid R31 run
must still capture the actual loader/provider behavior, physical-device
enumeration, and app-UID KGSL evidence separately.

## Validation and next action

The rootless static contract passed during this gate:

```text
$ android/nova-lab/test-rootless-profile.sh
rootless_profile_static=pass
```

The next permitted action is exact-client recovery. Once the declared archive
is recovered and reverified, rerun the static profile test and execute the
Thor R31 procedure without importing the broader SteamClientTermux Mesa,
D-Bus, audio, network, PRoot, `/dev/shm`, Proton, Gamescope, or packaging
contracts. The separate short-temporary-path predeclaration remains a
provenance/infrastructure experiment and is not a substitute for R31.

No Steam authentication secret or authenticated Steam state was read, copied,
backed up, committed, or exported.
