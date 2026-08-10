# Nova standalone runtime acquisition product requirement — 2026-08-10

## Decision

The distributed Nova app must not require the end user to install or
configure root, Magisk, Termux, or Termux:X11. Those components may remain
useful in the research harness, but they are not product prerequisites.

The APK must provide a first-run runtime bootstrap that downloads, verifies,
extracts, updates, and launches the Linux/Steam session from app-owned storage.

## Required first-run acquisition

The bootstrap needs a signed or otherwise authenticated manifest containing
versioned URLs, device/ABI requirements, sizes, and SHA-256 digests for at
least:

1. the Holo/Arch-compatible ARM64 glibc rootfs;
2. the native ARM64 Steam client and its compatible SteamRT3C runtime, fetched
   through the permitted Valve distribution path;
3. the required Wayland/Xwayland, Gamescope, Mesa/Turnip, Vulkan, input, and
   session-service package closure;
4. the Android-native presentation, input, and audio bridge components; and
5. the selected ARM Proton/FEX compatibility payloads and any per-game support
   data that is not obtained directly through Steam.

The exact artifact list remains a packaging task. The important contract is
that a fresh supported device does not depend on a manually prepared
`/data/local/tmp/nova-holo-rootfs` or an undocumented host-side file copy.

## Bootstrap behavior

The app should:

- check ABI, Android version, storage, and network readiness before download;
- support resumable downloads with progress, retry, cancellation, and
  corruption recovery;
- verify every archive and extracted manifest before activation;
- extract into app-private storage and activate versions atomically;
- retain a last-known-good runtime for rollback and cleanup old versions only
  after confirming the active session is stopped; and
- launch the session through app-owned Android surfaces and process
  supervision, without an external X11 application or adb script.

Steam account data and game content should remain user-controlled and should
be downloaded through Steam where appropriate. Large runtime binaries should
not be committed to this evidence repository; the repository should retain
manifests, provenance, hashes, URLs, and reproducible bootstrap logic.

## Current implementation gap

The current `nova-lab` launcher is a research harness. It checks for
Termux:X11, invokes `su`, and expects a pre-populated rootfs at
`/data/local/tmp/nova-holo-rootfs`; it does not yet implement this bootstrap.
Its successful one-click behavior therefore means “one click on a prepared
research device,” not “install the APK on a clean device and run Steam.”

The next productization phase must preserve the working Steam/controller
evidence while replacing those harness dependencies with an app-owned runtime
installer, Android-native presentation, and rootless process boundary.

## Acceptance gate

On a clean supported Nova-class device, after installing only the APK and
granting normal Android permissions, the app must be able to:

1. discover that the runtime is absent;
2. download and verify the required runtime closure;
3. start the native Steam session on an app-owned Android surface;
4. preserve the accepted physical controller path; and
5. stop, resume, update, and recover the session without root, Magisk,
   Termux:X11, adb, or manually staged rootfs files.
