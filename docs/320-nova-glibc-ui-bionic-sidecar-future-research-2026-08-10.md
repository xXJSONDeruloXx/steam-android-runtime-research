# Nova glibc Steam UI with a Bionic sidecar — future research proposal — 2026-08-10

Status: future potential research. This is an architecture proposal, not an
active experiment or a claim that the two runtimes are already interoperable.

## Question

Can we keep the working Steam UI and client path built for Linux/glibc while
using selected Android/Bionic Steam components at the Android boundary?

The answer appears to be yes, but only if the components remain in separate
processes with an explicit IPC boundary. It is not a safe plan to load Bionic
`.so` files into the glibc Steam process, Proton process, or Steam Runtime by
using `LD_LIBRARY_PATH`, `LD_PRELOAD`, or a mixed linker namespace.

## Current artifact picture

The ARM client currently used by the Holo path comes from the Valve
`steam_client_steamdeck_publicbeta_linuxarm64` seed selected by
[`fetch-steam-arm64-seed.sh`](/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/fetch-steam-arm64-seed.sh:9).
The main `steam` executable is AArch64 Linux/glibc and uses the Linux dynamic
linker, so it is not an Android/Bionic client.

The same Valve client manifest also contains an
`bins_androidarm64_linuxarm64` package:

- depot: [`bins_androidarm64_linuxarm64.zip.fd332f5de832268634b636873de78d80cf3280a1`](https://client-update.steamstatic.com/bins_androidarm64_linuxarm64.zip.fd332f5de832268634b636873de78d80cf3280a1)
- manifest entry: `steam_client_steamdeck_publicbeta_linuxarm64`
- recorded size: `18,004,620` bytes
- recorded SHA-256: `19556da707d0054cd9bfeb146fdf2a3586bb4c424cad0abbf55f428c20bc91d1`

The inspected Android package contained Android-native versions of:

```text
libsteamclient.so
libsteamnetworkingsockets.so
libtier0_s.so
libvstdlib_s.so
steamservice.so
```

It did not contain a complete Android Steam UI (`steam`, `steamui.so`, or
`steamwebhelper`). Its Android linker/build markers make it a plausible Bionic
component package, but it should be treated as a service/library depot rather
than a drop-in replacement for the current glibc UI.

GameNative provides useful prior art and additional packaged components. Its
current source downloads a similarly purposed, separately versioned
`steam-androidarm64-20260709.tzst`, a Bionic `imagefs`, ARM64EC Proton, FEX,
DXVK/VKD3D, Turnip drivers, and Proton-matched `lsteamclient` assets:

- [GameNative manifest](https://raw.githubusercontent.com/utkarshdalal/GameNative/master/manifest.json)
- [Bionic Steam asset dependency](https://raw.githubusercontent.com/utkarshdalal/GameNative/master/app/src/main/java/app/gamenative/utils/launchdependencies/BionicSteamAssetsDependency.kt)
- [Bionic program launcher](https://raw.githubusercontent.com/utkarshdalal/GameNative/master/app/src/main/java/com/winlator/xenvironment/components/BionicProgramLauncherComponent.java)
- [GameNative third-party notices](https://github.com/utkarshdalal/GameNative/blob/master/THIRD_PARTY_NOTICES)

The GameNative package and the current Valve Android depot are not byte-for-
byte identical builds. They are evidence of the same component family and
role, not interchangeable artifacts. GameNative's `libsteambootstrap.so` is
also identified as proprietary/source-withheld in its notices; it should not
be copied into this repository or redistributed without resolving its terms.

## Proposed architecture

Treat this as one product with two userlands rather than one process with two
libcs:

```text
Android/Bionic helper process
  Android-native Steam libraries and boundary services
  optional display/audio/input/networking integration
                 |
                 | explicit IPC: Unix socket, local TCP, shared memory, or fds
                 v
Holo/glibc Steam session
  Steam UI / webhelper / Steam Runtime / Proton / Wine / FEX
```

The glibc side remains responsible for the user-facing Steam client: QR login,
library navigation, downloads, and the UI state that is already working. A
Bionic helper could provide narrowly defined Android-native functionality where
that is useful, without asking the glibc client to load Android ELF objects.

Possible helper responsibilities, in increasing order of coupling, are:

1. Android-native audio, input, or surface services.
2. A small Steam service/networking or Steamworks-facing broker.
3. Launch support for a Bionic Wine/Proton game process, paired with Bionic
   `libsteamclient.so` and the matching Wine-side `lsteamclient`.

The third item is a separate execution mode, not an automatic enhancement to a
glibc Proton game. A glibc game process will continue to need its glibc
`lsteamclient` path unless a deliberately designed proxy protocol replaces it.

## What must remain separate

- Do not inject Bionic libraries into the glibc Steam or Proton process.
- Do not assume that Android `libsteamclient.so` can satisfy a glibc process's
  ELF, libc, pthread, linker-namespace, or ABI requirements.
- Do not assume that a Bionic helper automatically fixes Gamescope, Vulkan WSI,
  or SurfaceFlinger presentation. A display claim requires a changed surface
  artifact and fresh logs; process placement alone is not a rendering result.
- Do not let the UI and helper share one writable Steam configuration, cache,
  lock, or socket tree until session ownership is understood. Prefer separate
  state roots and explicit, read-only handoff where possible.
- Do not claim that backend connectivity, Steam login, Steam pipe access, app
  ownership, and game-frame presentation are the same success condition. Each
  needs its own observable acceptance signal.

## Research phases

### 1. Artifact and ABI audit

Fetch and verify the exact Valve Android depot listed above, inspect its ELF
interpreter, `DT_NEEDED` entries, build IDs, and exported symbols, and compare
those results with the GameNative-repackaged assets. This phase should remain
host-side and must not alter the known-good glibc deployment.

### 2. Minimal Android/Bionic helper smoke test

Start a helper from an Android app-private process or namespace and load only
the Android-native Steam libraries. Record linker diagnostics, process
lifetime, and clean teardown. The first gate is simply that the helper starts
through Android's linker without a root-side chroot or glibc namespace hack.

### 3. Define the IPC contract

Specify ownership and message boundaries before connecting it to the Steam UI:

- authentication/session identity;
- networking or Steamworks requests and responses;
- display, audio, and input events if those are in scope;
- shared-memory or file-descriptor ownership;
- startup, crash, reconnect, and shutdown behavior.

The protocol should make it possible to tell whether a result came from the
glibc client, the Bionic helper, or an unrelated Android service.

### 4. Add boundary services one at a time

If the helper is useful, trial Android-native audio, display, or input as
independent experiments. Keep the glibc UI unchanged and compare fresh
artifacts and logs for each service. This gives us a lower-coupling test of the
hybrid model before attempting game launch integration.

### 5. Evaluate a Bionic game-launch mode

Only if the service boundary is sound, test a Bionic Wine/Proton launch using a
matched Bionic runtime, FEX, Proton ARM64EC, and `lsteamclient`. Use a fresh
prefix and separate state. Compare it directly with the existing glibc/Holo
launch path; do not silently mix the two dependency graphs.

## Acceptance criteria

The proposal is worth advancing only if all of the following can be shown with
fresh, separately identified evidence:

- the glibc Steam UI still reaches login, library, and normal network/download
  behavior;
- the Bionic helper starts and stops cleanly through the Android linker;
- no Bionic ELF object is loaded into the glibc process tree;
- IPC reconnect and failure behavior are observable and bounded;
- any claimed audio, input, display, or networking improvement is measured at
  that boundary rather than inferred from process startup;
- any Steamworks/game result distinguishes login, service connectivity, app
  ownership, game initialization, and actual frame presentation.

## Recommendation

Preserve the current glibc Steam UI as the primary path. Record the Valve
Android depot and GameNative components as reusable inputs for a future,
optional Bionic sidecar or parallel game-launch track. Do not replace the UI or
merge a Bionic runtime into the current launcher until the artifact audit and a
minimal IPC-backed helper have passed their own predeclared experiments.

This keeps the promising Bionic prior art available while avoiding a broad
rewrite around an unproven assumption that two libc environments can share a
process. The existing rendering and Bionic-track results should remain the
historical boundary conditions for that future work:

- [`docs/296-nova-gamenative-winnative-proton-rendering-audit-2026-08-10.md`](/Users/kurt/Developer/steam-android-runtime-research/docs/296-gamenative-winnative-proton-rendering-audit-2026-08-10.md)
- [`docs/299-nova-gamenative-bionic-direct-namespace-result-2026-08-10.md`](/Users/kurt/Developer/steam-android-runtime-research/docs/299-nova-gamenative-bionic-direct-namespace-result-2026-08-10.md)
- [`docs/301-nova-gamenative-bionic-android-namespace-adapter-result-2026-08-10.md`](/Users/kurt/Developer/steam-android-runtime-research/docs/301-nova-gamenative-bionic-android-namespace-adapter-result-2026-08-10.md)
- [`docs/302-nova-bionic-track-closure-glibc-steamrt-plan-2026-08-10.md`](/Users/kurt/Developer/steam-android-runtime-research/docs/302-nova-bionic-track-closure-glibc-steamrt-plan-2026-08-10.md)
