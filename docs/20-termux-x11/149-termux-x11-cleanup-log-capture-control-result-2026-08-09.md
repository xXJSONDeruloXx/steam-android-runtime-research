# Termux:X11 cleanup and log-capture control result — 2026-08-09

Status: partial harness-control result. The cleanup/logging repair was
exercised successfully, but this launch used the default synthetic X11
animator rather than native Steam. No Steam conclusion is drawn.

## Run identity and profile provenance

```text
run_id=termux-x11-20260809T164100Z-cleanup-log-control-display-0
repo_commit=b85a4f03ac7d5a6d3e9ae03b521630b0bbe60ac1
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
client_artifact=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-x11-animate
client_artifact_sha256=884853cdc47c0d10a644153404fcd25e155b8784e24903f3ced568649b10bc04
client_profile=synthetic_x11_animator
bind_android_dev=1
client_namespace_mode=chroot-dev
steam_uid=501:20
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

The launch command omitted `NOVA_X11_ANIMATE=.../nova-termux-x11-steam-client.sh`,
so the harness selected its documented default synthetic ELF. The metadata
and artifact hash make that profile mismatch explicit.

## Harness result

The synthetic client completed and its final output was captured after the
host-side launcher wait:

```text
mount_private=pass path=/
nova_x11_frames=600
```

The synthetic X11 window was viewable and the Android screen showed the blue
animated test surface with its white square and cursor. The synthetic X11
readback again returned its known depth-24 `XGetImage` observational failure,
so the Android screenshot was the accepted presentation gate for this profile.

Cleanup completed without the prior manual procfs intervention:

```text
namespace_cleanup=pass
nova_x11_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

Run artifact hashes:

```text
android-screenshot.png sha256=f0233fb0e6640f90b97e5da26dfc92ed9add9d0eb5ad32e4a494ac62a5cea223
x11-tree.txt sha256=5531bc0d3397dfb7d70c88be07cd702a9ee2071f0adabe430790d57896403933
x11-capture.txt sha256=58106f25c5e76567060944b7b1d15b52eccc51ac37b8c28651e97465eba31133
termux-x11-client.log sha256=4dc536f960a5f3330a7f3b9be671b922c92ce635a9343e566e8f99f2a2ca7753
termux-x11-client.stdout sha256=0f5ffab23c1c7e517108b3e8e6b1e811aa72672ebfd6ff213eb24b4d1886c0f2
termux-x11-client.stderr sha256=ae786d270268792b7e12aafeddf73e81052ff992f2b057157969326fb54bb5bd
cleanup-output.txt sha256=22269c47b984575fb61e3b73829aad90fb88b80480fec8a5ade8234d728c7f55
```

The three Steam log artifacts were empty because Steam was never launched.

## Decision

The cleanup helper's PID matching and the host wait-before-log-copy repair
survived this control with clean post-stop/runtime markers. The native Steam
control must explicitly set:

```text
NOVA_X11_ANIMATE=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/device/nova-termux-x11-steam-client.sh
```

That corrected profile is the next device experiment; it must retain the same
mounts, flags, APK, UID/GID, renderer, and fresh run identity.
