# AYN Thor rootless updater-derived public-client equivalence — predeclaration — 2026-08-11

Run identity: `thor-rootless-public-client-generated-file-equivalence-20260811T232603Z`;
sub-run: `R36-public-client-generated-file-equivalence`.

Status: predeclared as the single next experiment after [doc
502](502-ayn-thor-rootless-public-client-provenance-refresh-result-2026-08-11.md).
This is a credential-free public-client provenance gate. It is not a SteamUI,
Vulkan, `/dev/shm`, D-Bus, Runtime 4, Proton, Gamescope/AHardwareBuffer, or
APK experiment.

## Question and one changed operation

R35's normal public updater completed and produced a sanitized archive that
was exactly the R35 seed plus one public generated file:

```text
./steamrtarm64/.cef-dev-tools-size.vdf
size=71
sha256=d82fc37374e2668f6569102bd2ed13b8d21ebad019c5d1bf7fb825617d0d32a4
```

The only changed operation in R36 is to quarantine that one named public file
from the fresh updater output before creating the equivalence archive. The
original file must be retained inside the fresh run scope as evidence until
the archive gate is complete; no other file may be removed, patched, or
renamed. The source tree remains a fresh updater output, not an authenticated
Steam home.

The gate succeeds only if the normalized archive exactly matches the
historical fixture:

```text
expected_archive_bytes=3457525760
expected_archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
expected_tar_entries=21513
expected_regular_files=19633
expected_symlinks=369
expected_forbidden_filename_scan=empty
```

If the normalized archive still differs, record the complete public-only
entry/hash difference and stop. Do not relabel the tree as the historical
fixture or launch a graphics experiment from it.

## Fixed inputs and launch boundary

Reuse only verified immutable payloads from R35:

```text
seed_archive_bytes=3457524736
seed_archive_sha256=3b54ebe8dd92ebbe304376335d59da28ebd88b1467999d39fee1c07ec98cee9a
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
```

Recreate fresh app-owned Steam state, logs, resolver, temporary directories,
X11 process/listener, screenshots, and readiness baselines. Preserve the
rooted rollback paths and keep the real outer UID at app UID 10138. Use the
same direct TCP Termux:X11 display `:77`, inherited Android network, nested
Steam layout, SteamRT-first environment, and normal updater command from R35.
Keep all Vulkan selectors, loader diagnostics, Mesa overrides, CEF flags,
`/dev/shm`, machine-id, D-Bus, Runtime 4, Proton, FEX, Gamescope, and
AHardwareBuffer changes absent.

Before launch, record the Android device-log consent state. If the modal is
present, verify its exact text, scroll only the dialog, and select one-time
access with targeted ADB input. Never grant persistent all-device log access.
If absent, record `log_access_consent=not-shown`.

## Acceptance and classification

1. Any wrong device, hash, UID, stale scope, authentication exposure, helper
   drift, or preserved-root mutation is **invalid**.
2. If the normalized archive is exactly the expected fixture and the
   quarantined file is the only difference, classify
   `normalized-pass-exact-public-client`.
3. If the archive remains different, classify
   `normalized-pass-different-public-client` and stop.
4. If the updater or archive gate fails, classify `normalized-refresh-fail`.

This experiment does not claim SteamUI or OOBE success. A later run must be
separately predeclared before launching Steam from a normalized fixture.

## Evidence and cleanup

Capture the pre/post seed and normalized archive size/hash/entry counts,
quarantined-file hash, selected native client hashes, updater manifest/version,
effective environment, app UID/SELinux identity, X11 PID/listener/handshake,
process state, and a screenshot only as transport evidence. Record the exact
host evidence paths and hashes.

Remove only the R36 device/app/Termux scopes and the quarantined file after
capture. Restore any temporary Termux property edit byte-for-byte. Verify no
matching Steam/PRoot/webhelper/X11 process and no port-6077 listener remain;
verify both rooted rollback paths and post-cleanup free space.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read, copied,
backed up, committed, or exported.
