# Nova libredirect reconstruction audit and scoped use — 2026-08-10

## Status

This is a read-only audit of the sibling checkout
`/Users/kurt/Developer/libredirect`. No libredirect artifact has been copied
into the Nova tree, and no Nova device run was performed for this record.

The checkout was at `e56035c9e4a4a3fe0d499d9a8d721641e754887c`
(`app.gnlime-e56035c`), with `origin/main` at the same commit. Its only
working-tree change was an untracked `.DS_Store`.

## Why this checkout is useful

The local repository contains more than a conceptual reimplementation. It
contains an extracted GameNative reference artifact and a source reconstruction
based on that artifact:

| Artifact | SHA-256 | Size | Interpretation |
| --- | --- | ---: | --- |
| `device_wx.so` | `acc50fb4ebe96895dcac51468a63948ae286ead72c31718161c13c48d2ab6419` | 41,528 bytes | Reference `libredirect-bionic-wx.so` recorded by the audit |
| `device_libredirect.so` | `06bde544ee5fb762efa264558170aac555a21896ff173d9e5595f0e6071e2bc2` | 43,344 bytes | Device glibc-layer artifact |
| `device_libredirect-bionic.so` | `a6a0ee59bac93112f84bf75994def7607a278e8cb011a6e23414cb0107abc2cd` | 12,680 bytes | Device simple-Bionic artifact |
| `out/libredirect-bionic-minimal.so` | `2e73f9f128f58474c43d6d6a33e7889a8bfca50136df326bc1988c666767d60a` | 11,792 bytes | Source-built diagnostic/minimal variant |

The reference binary comparison records matching package obfuscation, major
exports, redirect data structures, diagnostic counters, Wine APEX strings, and
the W^X-related entry points. See the sibling checkout's
[`OBSERVED_VS_SOURCE.md`](https://github.com/xXJSONDeruloXx/libredirect/blob/main/OBSERVED_VS_SOURCE.md)
and [`BUILD_COMPARISON.md`](https://github.com/xXJSONDeruloXx/libredirect/blob/main/BUILD_COMPARISON.md).

This is substantially stronger evidence than inferring behavior from the
GameNative APK alone. GameNative's own notice says that `libredirect.so` is a
proprietary `LD_PRELOAD` shim loaded into Wine/Proton child processes, where it
handles package compatibility and Android process-launch restrictions; it is
not the Android renderer or application UI.

Reference:
[GameNative third-party notices](https://github.com/utkarshdalal/GameNative/blob/master/THIRD_PARTY_NOTICES#L938-L1036).

## Reconstructed variants

### glibc layer

`preload_replace.c` provides a broad glibc preload layer. Its documented scope
includes package/imagefs path rewriting across filesystem, loader, process,
Unix-socket, shared-memory, and X11 calls. The intended transformation is
roughly:

```text
com.winlator/files/rootfs  ->  <package>/files/imagefs
```

This could help only when a glibc-side binary actually contains or receives
the old Winlator path. It is not necessary if the Nova Holo launcher already
provides correct paths and environment variables directly.

### simple Bionic layer

`preload_replace_bionic.c` and the later
`preload_replace_bionic_minimal.c` isolate the lower-risk responsibilities:

- package/path rewriting;
- selected input-name rewriting;
- `/proc/self/exe` redirection;
- no W^X `mprotect`/`mmap`/SIGSEGV machinery in the minimal variant.

Commit `317972d` explicitly records that the full W^X handling was crashing
GameNative while the minimal variant was stable in a Yakuza 6 test at roughly
949 MB RSS. That is a useful hypothesis and historical result, but it has not
been independently reproduced in the Nova project.

### Bionic W^X layer

`preload_replace_bionic_wx.c` reconstructs the modern Android-facing behavior:

- XOR-obfuscated package name, matching `app.gamenative` with key `0x5a`;
- package and Wine APEX path redirects;
- input-device blocking for `/dev/input/event*`, `/dev/input/js*`, and
  `/dev/hidraw*`;
- `mprotect`, `mmap`, and `mmap64` handling for W^X rebaking;
- chained SIGSEGV/SIGBUS handling and diagnostic counters;
- `openat` syscall-site patching in libc/linker paths;
- `execve`/`execv` handling for Wine and linker64 launches.

The latest commit, `e56035c`, restored upstream-style execution behavior after
a simplified `/proc/self/exe` implementation caused a game boot hang. The
current source handles the `wine-preloader` boundary, direct system paths,
`/proc/self/exe`, ELF detection, and linker64 execution. See
[`preload_replace_bionic_wx.c`](https://github.com/xXJSONDeruloXx/libredirect/blob/main/preload_replace_bionic_wx.c)
around the `execve` hook.

The repository's own comparison remains appropriately cautious: it describes
strong parity for symbols, strings, and core redirects, but identifies
remaining risk in signal-handler chaining, VMA parsing, cache policy, and W^X
edge cases. The W^X source should therefore be treated as a functional
reimplementation under investigation, not as proven bit-for-bit equivalence.

The input filtering is especially important for Nova. Physical controller
input is currently working through the existing Android/input path, so blindly
introducing the W^X shim could regress that behavior by denying direct device
access. It must not be added as an input “fix.”

## Relevance to the current Nova blocker

The libredirect work addresses a different layer from the current rendering
failure:

| Layer | Could libredirect help? | Current Nova interpretation |
| --- | --- | --- |
| Package/imagefs paths | Yes, if logs show hardcoded `com.winlator` paths | Conditional; not yet a demonstrated failure |
| Android linker64/private executable launch | Yes, especially the modern Bionic `execve` path | Worth preserving as future launch-compatibility prior art |
| Wine JIT/W^X policy | Possibly, on Android versions where the policy blocks Wine | Not yet shown to be the current failure |
| Controller input | It can block or rewrite direct device access | Already solved; do not change this path casually |
| Vulkan device/swapchain/WSI | No | Current game-frame investigation remains here |
| Gamescope/AHardwareBuffer/SurfaceFlinger | No | Separate compositor architecture |

The existing GameNative/WinNative audit already concluded that their Android
renderer does not make `libredirect` a rendering solution. The Nova Bionic
track is also intentionally paused in
[`docs/00-start-here/302-nova-bionic-track-closure-glibc-steamrt-plan-2026-08-10.md`](../00-start-here/302-nova-bionic-track-closure-glibc-steamrt-plan-2026-08-10.md),
while the current primary path remains Holo/glibc. The observed
`VK_KHR_swapchain`/WSI failure cannot be fixed by a package-path preload shim.

## Recommended future use

Keep this as an auxiliary compatibility track rather than integrating it into
the current rendering path.

1. If a future game launch fails before Vulkan initialization, first look for
   concrete evidence of `com.winlator`, `/apex/.../wine`, `/proc/self/exe`,
   `wine-preloader`, or linker64 execution errors.
2. If that evidence exists, test the minimal or glibc shim in a fresh,
   run-scoped experiment with the exact library hash and effective
   `LD_PRELOAD` recorded.
3. Rebuild the W^X variant from the current `e56035c` source with the matching
   NDK/API configuration before treating the older `out/` binary as evidence;
   the on-disk W^X output predates the current HEAD.
4. Test W^X separately from input and renderer changes, capture its diagnostic
   counters, and verify that the working physical controller remains working.
5. Do not use libredirect as a substitute for the current Proton/runtime/WSI
   controls, and do not fold the Bionic artifacts into the Holo rootfs without
   a separate ABI and launch experiment.

## Decision

The local reconstruction is valuable and should be preserved. The minimal
Bionic and glibc variants are credible future startup-compatibility tools; the
W^X variant is a meaningful source of Android 15/process-launch knowledge but
still carries enough risk to remain isolated. No libredirect integration is
justified in the current Nova rendering branch until a fresh launch log shows
that package rewriting, linker64 execution, or W^X—not Vulkan WSI—is the first
failed boundary.
