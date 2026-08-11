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
24. [Rootless session/log guard](00-start-here/364-nova-rootless-session-log-guard-2026-08-10.md)
25. [Rootless R2 SteamRT3C extraction boundary](00-start-here/365-nova-rootless-r2-steamrt-xz-extraction-failure-2026-08-10.md)
26. [Rootless R3 device predeclaration](00-start-here/366-nova-rootless-r3-device-predeclaration-2026-08-11.md)
27. [Rootless R3 PRoot IPC boundary](00-start-here/367-nova-rootless-r3-proot-ipc-boundary-2026-08-11.md)
28. [Rootless R3 `/proc` path boundary](00-start-here/368-nova-rootless-r3-proc-path-boundary-2026-08-11.md)
29. [Rootless R3 Steam home-layout boundary](00-start-here/369-nova-rootless-r3-steam-home-layout-2026-08-11.md)
30. [Rootless R3 `/dev` path boundary](00-start-here/370-nova-rootless-r3-dev-path-boundary-2026-08-11.md)
31. [Rootless R3 Steam bootstrap update result](00-start-here/371-nova-rootless-r3-bootstrap-update-result-2026-08-11.md)
32. [Rootless R3 updated SteamUI GTK2 boundary](00-start-here/372-nova-rootless-r3-steamui-gtk2-boundary-2026-08-11.md)
33. [Rootless R4 SteamUI guest-rootfs predeclaration](00-start-here/373-nova-rootless-r4-steamui-guest-rootfs-predeclaration-2026-08-11.md)
34. [Rootless R4 source-rootfs readability result](00-start-here/374-nova-rootless-r4-rootfs-readability-result-2026-08-11.md)
35. [Rootless R5 app-private Holo archive extraction predeclaration](00-start-here/375-nova-rootless-r5-archive-extraction-predeclaration-2026-08-11.md)
36. [Rootless R5 toybox tar mode boundary](00-start-here/376-nova-rootless-r5-tar-mode-boundary-2026-08-11.md)
37. [Rootless R5b tar parent normalization predeclaration](00-start-here/377-nova-rootless-r5b-tar-parent-normalization-predeclaration-2026-08-11.md)
38. [Rootless R5b tar listing normalization boundary](00-start-here/378-nova-rootless-r5b-tar-listing-boundary-2026-08-11.md)
39. [Rootless R5c tar symlink normalization predeclaration](00-start-here/379-nova-rootless-r5c-tar-symlink-normalization-predeclaration-2026-08-11.md)
40. [Rootless R5c tar symlink/listing result](00-start-here/380-nova-rootless-r5c-tar-symlink-result-2026-08-11.md)
41. [Rootless R6 Holo `bsdtar` bootstrap predeclaration](00-start-here/381-nova-rootless-r6-holo-bsdtar-bootstrap-predeclaration-2026-08-11.md)
42. [Rootless R6 Holo `bsdtar` result](00-start-here/382-nova-rootless-r6-holo-bsdtar-result-2026-08-11.md)
43. [Rootless R6b Holo `bsdtar` mode retry predeclaration](00-start-here/383-nova-rootless-r6b-holo-bsdtar-mode-predeclaration-2026-08-11.md)
44. [Rootless R6b Holo `bsdtar` mode result](00-start-here/384-nova-rootless-r6b-holo-bsdtar-mode-result-2026-08-11.md)
45. [Rootless R6c owner-access normalization predeclaration](00-start-here/385-nova-rootless-r6c-owner-access-predeclaration-2026-08-11.md)
46. [Rootless R6c package closure result](00-start-here/386-nova-rootless-r6c-package-closure-result-2026-08-11.md)
47. [Rootless R6d complete Holo closure predeclaration](00-start-here/387-nova-rootless-r6d-complete-holo-closure-predeclaration-2026-08-11.md)
48. [Rootless R6d complete Holo closure result](00-start-here/388-nova-rootless-r6d-complete-holo-closure-result-2026-08-11.md)
49. [Rootless R6e closure validator predeclaration](00-start-here/389-nova-rootless-r6e-closure-validator-predeclaration-2026-08-11.md)
50. [Rootless R6e closure validator result](00-start-here/390-nova-rootless-r6e-closure-validator-result-2026-08-11.md)
51. [Rootless R7 public Steam seed and supervisor predeclaration](00-start-here/391-nova-rootless-r7-steam-seed-predeclaration-2026-08-11.md)
52. [Rootless R7 relative PRoot path result](00-start-here/392-nova-rootless-r7-relative-proot-path-result-2026-08-11.md)
53. [Rootless R7b absolute PRoot path retry predeclaration](00-start-here/393-nova-rootless-r7b-absolute-proot-predeclaration-2026-08-11.md)
54. [Rootless R7b PRoot `libtalloc` soname result](00-start-here/394-nova-rootless-r7b-libtalloc-soname-result-2026-08-11.md)
55. [Rootless R7c PRoot `libtalloc` soname retry predeclaration](00-start-here/395-nova-rootless-r7c-libtalloc-soname-predeclaration-2026-08-11.md)
56. [Rootless R7c public seed `steamui.so` mode result](00-start-here/396-nova-rootless-r7c-steamui-mode-result-2026-08-11.md)
57. [Rootless R7d public Steam seed mode retry predeclaration](00-start-here/397-nova-rootless-r7d-steam-seed-mode-predeclaration-2026-08-11.md)
58. [Rootless R7d `steamui.so` dependency closure result](00-start-here/398-nova-rootless-r7d-steamui-dependency-result-2026-08-11.md)
59. [Rootless R7e `steamui.so` dependency diagnostic predeclaration](00-start-here/399-nova-rootless-r7e-steamui-ldd-diagnostic-predeclaration-2026-08-11.md)
60. [Rootless R7e `steamui.so` dependency diagnostic result](00-start-here/400-nova-rootless-r7e-steamui-ldd-diagnostic-result-2026-08-11.md)
61. [Rootless R7f SteamUI Holo closure additions predeclaration](00-start-here/401-nova-rootless-r7f-steamui-closure-additions-predeclaration-2026-08-11.md)
62. [Rootless R7f package dependency closure result](00-start-here/402-nova-rootless-r7f-package-dependency-result-2026-08-11.md)
63. [Rootless R7g full SteamUI dependency closure predeclaration](00-start-here/403-nova-rootless-r7g-full-steamui-dependency-closure-predeclaration-2026-08-11.md)
64. [Rootless R7g full SteamUI dependency closure result](00-start-here/404-nova-rootless-r7g-full-steamui-dependency-closure-result-2026-08-11.md)
65. [Rootless R8 supervisor and Steam version predeclaration](00-start-here/405-nova-rootless-r8-supervisor-steam-version-predeclaration-2026-08-11.md)
66. [Rootless R8 supervisor and Steam version result](00-start-here/406-nova-rootless-r8-supervisor-steam-version-result-2026-08-11.md)
67. [Rootless R9 Termux:X11 and network handoff predeclaration](00-start-here/407-nova-rootless-r9-x11-network-predeclaration-2026-08-11.md)
68. [Rootless R9 Termux:X11 and network handoff result](00-start-here/408-nova-rootless-r9-x11-network-result-2026-08-11.md)
69. [Rootless R10 resolver and short-temp handoff predeclaration](00-start-here/409-nova-rootless-r10-resolver-temp-predeclaration-2026-08-11.md)
70. [Rootless R10 resolver and short-temp handoff result](00-start-here/410-nova-rootless-r10-resolver-temp-result-2026-08-11.md)
71. [Rootless R10b no-`/proc/net` retry predeclaration](00-start-here/411-nova-rootless-r10b-no-proc-net-predeclaration-2026-08-11.md)
72. [Rootless R10b no-`/proc/net` retry result](00-start-here/412-nova-rootless-r10b-no-proc-net-result-2026-08-11.md)
73. [Rootless R11 single CDN payload predeclaration](00-start-here/413-nova-rootless-r11-cdn-single-payload-predeclaration-2026-08-11.md)
74. [Rootless R11 single CDN payload result](00-start-here/414-nova-rootless-r11-cdn-single-payload-result-2026-08-11.md)
75. [Rootless R12 app-owned `bsdtar` bootstrap predeclaration](00-start-here/415-nova-rootless-r12-app-bsdtar-bootstrap-predeclaration-2026-08-11.md)
76. [Rootless R12 app-owned `bsdtar` bootstrap result](00-start-here/416-nova-rootless-r12-app-bsdtar-bootstrap-result-2026-08-11.md)
77. [Rootless R12b helper asset retry predeclaration](00-start-here/417-nova-rootless-r12b-helper-assets-predeclaration-2026-08-11.md)
78. [Rootless R12b helper asset retry result](00-start-here/418-nova-rootless-r12b-helper-assets-result-2026-08-11.md)
79. [Rootless R12c complete bootstrap closure predeclaration](00-start-here/419-nova-rootless-r12c-libc-bootstrap-predeclaration-2026-08-11.md)
80. [Rootless R12c complete bootstrap closure result](00-start-here/420-nova-rootless-r12c-libc-bootstrap-result-2026-08-11.md)
81. [Rootless R12d explicit guest library path predeclaration](00-start-here/421-nova-rootless-r12d-env-library-path-predeclaration-2026-08-11.md)
82. [Rootless R12d explicit guest library path result](00-start-here/422-nova-rootless-r12d-env-library-path-result-2026-08-11.md)
83. [Rootless R12e `/usr/lib` bootstrap layout predeclaration](00-start-here/423-nova-rootless-r12e-usr-lib-layout-predeclaration-2026-08-11.md)
84. [Rootless R12e `/usr/lib` bootstrap layout result](00-start-here/424-nova-rootless-r12e-usr-lib-layout-result-2026-08-11.md)
85. [Rootless R12f bootstrap asset replacement predeclaration](00-start-here/425-nova-rootless-r12f-bootstrap-asset-replacement-predeclaration-2026-08-11.md)
86. [Rootless R12f bootstrap asset replacement result](00-start-here/426-nova-rootless-r12f-bootstrap-asset-replacement-result-2026-08-11.md)
87. [Rootless R13 guest package closure predeclaration](00-start-here/427-nova-rootless-r13-guest-package-closure-predeclaration-2026-08-11.md)
88. [Rootless R13 guest package closure result](00-start-here/428-nova-rootless-r13-guest-package-closure-result-2026-08-11.md)
89. [Rootless R13b closure idempotence predeclaration](00-start-here/429-nova-rootless-r13b-closure-idempotence-predeclaration-2026-08-11.md)
90. [Rootless R13b closure idempotence result](00-start-here/430-nova-rootless-r13b-closure-idempotence-result-2026-08-11.md)
91. [Rootless R14 supervisor preflight predeclaration](00-start-here/431-nova-rootless-r14-supervisor-preflight-predeclaration-2026-08-11.md)
92. [Rootless R14 supervisor preflight result](00-start-here/432-nova-rootless-r14-supervisor-preflight-result-2026-08-11.md)

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
