# Documentation map

This directory is organized for two readers: a person browsing the research
history and an implementation agent choosing the next bounded experiment.
Numbered filenames retain their original experiment IDs; folders provide the
navigation structure without changing the evidence identity.

## Start here

Read these in order when picking up the project:

1. [Roadmap and current execution queue](00-start-here/06-android-linux-gamescope-roadmap.md)
2. [Runtime harness lifecycle and cleanup contract](00-start-here/34-nova-runtime-harness-lifecycle.md)
3. [Standalone runtime/product requirement](00-start-here/299-nova-standalone-runtime-acquisition-product-requirement-2026-08-10.md)
4. [SteamclientTermux comparison and integration guidance](00-start-here/333-steamclienttermux-comparison-2026-08-10.md)
5. [APK first-run provisioning requirement](00-start-here/333-nova-apk-idempotent-first-run-provisioning-2026-08-10.md)
6. [Latest clean-device OOBE boundary](00-start-here/336-nova-clean-device-apk-oobe-2026-08-10.md)
7. [Truthful SteamOS update adapter boundary](00-start-here/337-nova-steamos-update-truthful-no-update-adapter-2026-08-10.md)
8. [Fresh APK bootstrap, OOBE, and QR result](00-start-here/347-nova-bootstrap-network-fix-result-2026-08-10.md)
9. [Rootless SteamClientTermux profile predeclaration](00-start-here/348-nova-rootless-steamclienttermux-predeclaration-2026-08-10.md)
10. [Rootless supervisor contract](00-start-here/350-nova-rootless-supervisor-contract-2026-08-10.md)
11. [Rootless supervisor R0 replay](00-start-here/351-nova-rootless-supervisor-r0-result-2026-08-10.md)
12. [Rootless supervisor R0b result](00-start-here/352-nova-rootless-supervisor-r0b-result-2026-08-10.md)
13. [Rootless X11 transport R1 result](00-start-here/353-nova-rootless-x11-transport-r1-result-2026-08-10.md)
14. [Rootless Termux/X11 dependency install](00-start-here/354-nova-rootless-termux-base-install-2026-08-10.md)
15. [Rootless X11 R1b result](00-start-here/355-nova-rootless-x11-r1b-result-2026-08-10.md)
16. [Rootless X11 R1c result](00-start-here/356-nova-rootless-x11-r1c-result-2026-08-10.md)
17. [Rootless X11 R1d package visibility result](00-start-here/357-nova-rootless-x11-r1d-package-visibility-result-2026-08-10.md)
18. [Rootless APK/Termux bridge implementation](00-start-here/358-nova-rootless-apk-termux-bridge-implementation-2026-08-10.md)
19. [Rootless APK/Termux bridge R1e result](00-start-here/359-nova-rootless-apk-termux-bridge-r1e-result-2026-08-10.md)
20. [Rootless runtime/network contracts](00-start-here/360-nova-rootless-runtime-network-contracts-2026-08-10.md)
21. [Rootless R2 device predeclaration](00-start-here/361-nova-rootless-r2-device-predeclaration-2026-08-10.md)
22. [Rootless R2 PRoot path failure](00-start-here/362-nova-rootless-r2-proot-path-failure-2026-08-10.md)
23. [Rootless PulseAudio TCP contract](00-start-here/363-nova-rootless-pulseaudio-contract-2026-08-10.md)

Before any Nova device run, read the lifecycle contract. Before importing
SteamclientTermux behavior, read the comparison record and inspect the clean
local checkout at `/Users/kurt/Developer/steamclienttermux`. The record pins
the evidence revision and separates portable runtime contracts from its PRoot
architecture; the sibling checkout supplies the current source revision for
follow-up work.

## Evidence bands

| Folder | Contents | Use it for |
|---|---|---|
| [`00-start-here`](00-start-here/README.md) | Foundation, current synthesis, active requirements, and latest milestones | Project orientation and agent handoff |
| [`10-ahb-and-harness`](10-ahb-and-harness/README.md) | Early Android bridge, AHardwareBuffer, Gamescope, input, and harness evidence | Presentation and low-level transport history |
| [`20-termux-x11`](20-termux-x11/README.md) | Direct Termux:X11 display, Holo rootfs, Steam OOBE, D-Bus, networking, and QR-login experiments | The current known-good display/login path |
| [`30-runtime-and-games`](30-runtime-and-games/README.md) | Steam runtime, Proton/FEX, hardware CEF, audio, WSI, and game-launch experiments | First-frame and compatibility work |
| [`40-productization`](40-productization/README.md) | One-click APK, provisioning, cleanup, packaging, later runtime refinements, and prior-art audits | Turning evidence into a product |

## Evidence conventions

Experiment and result documents remain paired by their numeric ID and filename.
“Predeclaration” or “experiment” records define the exact run; “result” records
close it. Do not reuse a prior run’s logs, screenshots, readiness, or process
state. Current guidance belongs in the roadmap and the start-here documents;
historical records should remain factual and append-only after a result is
closed.

The root project [README](../README.md) contains the product summary and links
back to this map. The Nova lab [README](../android/nova-lab/README.md) contains
build/deploy instructions and the executable profile details.
