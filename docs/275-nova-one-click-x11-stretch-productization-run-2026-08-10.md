# Nova one-click Termux:X11 stretch productization — 2026-08-10

## Question

The direct Termux:X11 path is the working Steam presentation path, but the
Nova surface is 1280×960 while Steam's native Big Picture child is 1280×800.
A fresh no-input run already showed that Termux:X11's supported
`displayResolutionMode=custom`, `displayResolutionCustom=1280x800`,
`displayResolutionExact=1280x800`, and `displayStretch=true` profile fills the
Android surface. The profile is currently temporary and must be applied by
hand, so the one-click APK still launches with the black-band geometry.

## Implementation under test

Extend `nova-one-click-root-launcher.sh` to make that proven profile part of
the product session:

- back up Termux:X11's preference XML and its owner/group/mode in the Nova
  state directory before changing it;
- apply the three geometry keys before starting the Termux:X11 Activity;
- restore the original XML after exact runtime/X11 teardown, including on a
  stop request after a partial launch; and
- recover a stale backup before a new start if a process was interrupted.

The default profile is enabled for this Nova launcher and can be disabled with
`NOVA_ANDROID_LAUNCHER_X11_STRETCH=0`. This change does not alter Steam data,
game files, controller forwarding, audio, or the Gamescope/FROG research
path. A device run must prove the fresh 1280×800 X11 root, the full-surface
Android capture, and byte-for-byte preference restoration.
