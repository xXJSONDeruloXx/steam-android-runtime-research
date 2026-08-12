# AYN Thor rootless public-seed refresh recovery — result — 2026-08-12

Run identity: `thor-rootless-public-seed-refresh-recovery-20260811T234742Z`;
sub-run: `R37-public-seed-refresh-recovery`.

Status: **recovery-fail**. The exact public seed and the complete app-owned
rootless fixture were valid, but the normal Steam launch stopped at the old
native `vgui2_s` loader boundary before any public manifest/update handoff.
This is a client-provenance failure, not a Vulkan, KGSL, SELinux, D-Bus,
`/dev/shm`, or Steam presentation result.

## Result

```text
seed_hash_gate                         pass
seed_forbidden_filename_scan           empty
Holo archive extraction                pass
161-package plus 2-asset closure       pass
app-UID rootless preflight              pass
fresh Termux:X11 and TCP 6077           pass
app-UID xprop handshake                 pass
normal public updater handoff           not reached
native SteamUI vgui2_s handoff          fail
client refresh                         not completed
Vulkan/KGSL                            not reached
SteamUI/webhelper/frame                not reached
classification                         recovery-fail
```

The decisive fresh launch output was:

```text
[2026-08-12 00:08:30] Startup - updater built Aug  6 2026 00:23:30
[2026-08-12 00:08:30] Startup - Steam Client launched with: '/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam' '-gamepadui' '-steamos3' '-steampal' '-steamdeck' '-no-cef-sandbox' '-skipinitialbootstrap' '-no-child-update-ui'
[2026-08-12 00:08:30] Opted in to client beta 'steamdeck_publicbeta' via beta file
[2026-08-12 00:08:30] Using update UI: xwin
proot-shm-helper: Temporary path too long
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
Error: Could not load module 'vgui2_s.so'
[2026-08-12 00:08:31] Shutdown
```

There was no `Manifest download`, `Update complete`, or post-update package
transaction. The older public seed therefore cannot be used to answer whether
the current rooted payload’s later SteamUI/Vulkan behavior is reproducible
rootlessly.

## Provenance and fixed inputs

```text
branch=feat/rootless-steamclienttermux-profile
start_head=3255679408224430d6b6ee7abd4a7def5878ca55
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
sibling=/Users/kurt/Developer/steamclienttermux
sibling_head=8d14c10195b34fe2714ba59df1680df27a852532
```

The host seed gate passed before any device staging:

```text
path=android/nova-lab/build/steam-bootstrap/steam-home.tar.gz
bytes=1756623692
sha256=1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124
tar_entries=21294
forbidden_filename_scan=empty
```

The immutable rootless inputs were:

```text
Holo system.rootfs.zst bytes=384971555
Holo system.rootfs.zst sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
Holo UI/audio closure=161 packages plus 2 Debian GTK2 assets
PRoot sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
PRoot loader sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
libtalloc.so.2.4.3 sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid-shmem.so sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
```

The app-owned R37 scopes were:

```text
/data/local/tmp/thor-rootless-public-seed-refresh-recovery-20260811T234742Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r37-public-seed-refresh-recovery/
/data/data/com.termux/files/home/.nova-rootless/
```

The preserved rooted rollback paths were verified before and after the run:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The rootless static validator passed before device work:

```text
rootless_profile_static=pass
```

## Client evidence

The older seed’s selected native files were unchanged across the launch:

```text
steamrtarm64/steam
  bytes=10044224
  sha256=cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85
steamrtarm64/steamui.so
  bytes=38532968
  sha256=972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0
steamrtarm64/vgui2_s.so
  bytes=3427240
  sha256=a3e010415d3b1cda22a9fe6ad8e5a33e558113483cbc7639ec4cae560c676dd7
steamrtarm64/steamwebhelper
  bytes=10249960
  sha256=3901a2af2b9348a4b6381162c3913d607fcf7e959996b8388fd571f4a0d1cd8f
postlaunch_hashes=identical_to_prelaunch
```

The public package metadata reported version `1785979614`; the launched
binary reported version `1785979169`. The beta marker was present, and the
launch explicitly reported `steamdeck_publicbeta`. No package or client update
transaction replaced these files.

The guest launch retained the declared R37 environment. In particular:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
DISPLAY=127.0.0.1:77
VK_DRIVER_FILES=unset
VK_ICD_FILENAMES=unset
VK_LOADER_DEBUG=unset
LD_PRELOAD=unset
MESA_LOADER_DRIVER_OVERRIDE=unset
GALLIUM_DRIVER=unset
LIBGL_ALWAYS_SOFTWARE=unset
VK_IMPLICIT_LAYER_PATH=unset
```

The exact Steam flags were the R37 normal-updater contract. Neither
`-nobootstrapperupdate` nor `-cef-disable-gpu` was added.

## Rootless and display evidence

Holo extraction and guest closure ran as app UID 10138. The final supervisor
preflight reported:

```text
nova_rootless_preflight=pass uid=10138
rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r37-public-seed-refresh-recovery/guest-rootfs-closure
proot=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r37-public-seed-refresh-recovery/input/proot/proot
free_kib=9884880
resolv_conf=nameserver 192.168.0.1
```

The app-owned display transport was fresh:

```text
termux_x11_pid=28595
display=127.0.0.1:77
listeners=0.0.0.0:6077,[::]:6077
xprop_handshake=pass
```

The Android all-device-log consent dialog was not shown, so no scroll or tap
was issued: `log_access_consent=not-shown`. Targeted ADB log capture remained
available for this diagnostic run. The screenshot was:

```text
path=/tmp/thor-rootless-public-seed-refresh-recovery-20260811T234742Z-evidence/screenshot.png
dimensions=1920x1080
bytes=40536
sha256=c38f65ec8cac9e21e099d4194c87d6e3ae0351d0974658079429e61e8d5c36d1
visible_state=black Termux:X11 canvas, Android status bar, keybar, and X cursor
steam_frame=no
```

The targeted Android log contained AVC `granted` entries for the app-owned
Steam binaries, but no denial was attributed. R37 never reached a Vulkan call,
so it provides no evidence about KGSL access or SELinux GPU policy.

## Cleanup and rollback

The exact X11 PID was terminated, Nova/Termux:X11/Termux were force-stopped,
and the temporary Termux setting was restored from its exact R37 backup:

```text
termux.properties.before_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
termux.properties.after_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
```

Only the three R37 scopes were removed. Post-cleanup checks reported:

```text
r37_device_scope=absent
r37_app_scope=absent
r37_termux_scope=absent
steam/proot/webhelper/x11_processes=absent
6077_listener=absent
rooted_rootfs=present
rooted_active_runtime=present
post_cleanup_free_kib=21819092
```

Host evidence remains at:

```text
/tmp/thor-rootless-public-seed-refresh-recovery-20260811T234742Z-evidence/
```

Key evidence hashes:

```text
rootless-supervisor.log bytes=4180 sha256=451283ac05da7563d77124909edf30221aa08e7fc050c9626894553e3c51a698
termux-x11-77.log bytes=23033 sha256=2edb62325f1af9dc47dba887e62a6dbd6f06b49481cb5df2d418eb94c42ebec2
processes-post.txt bytes=110 sha256=476a54b9ed5c8a9f9377990294bfcffa972f983349ab7696066bcd18147c2860
listeners-post.txt bytes=162 sha256=438d85c75f352089ff06387e72c0d52c05deaa0e01ff00b526e4ae11264673c9
logcat-1200.txt bytes=177817 sha256=c456eaeace9c21d16c21b64e4c586d77296381bd2fd8e597da75fbf022cff9aa
```

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported. The fresh mutable app/Termux scopes were
removed after evidence capture.

## Interpretation and next boundary

R37 does not show that rootless cannot reach the rooted native-client boundary.
It shows that the older public bootstrap seed still dies at `vgui2_s` under the
current rootless launch before it can self-update. The rooted control used a
newer public-beta client tree, so the two runs are not payload-equivalent.

The sister [SteamClientTermux](https://github.com/huntergdavis/steamclienttermux)
checkout at `8d14c10195b34fe2714ba59df1680df27a852532` reports successful native
ARM64 Steam UI on Snapdragon/Adreno, but its launcher also uses a patched PRoot,
private runtime paths, shared temporary storage, private D-Bus/Mesa contracts,
and software-rendered CEF. Those are useful later hypotheses, not evidence to
import into R38 wholesale. The upstream [Termux:X11 PRoot guidance](https://github.com/termux/termux-x11#using-with-proot-environment)
likewise requires either shared temporary storage or a matching `TMPDIR`; the
current Nova profile already has an app-owned short guest `/tmp` contract.

The single next experiment is the official stable ARM64 payload replay
predeclared in doc 507. It first requires the host-only Valve manifest/payload
gate and a fresh sanitized stable-channel tree, then changes only the public
native client payload/channel provenance while keeping this rootless Holo,
PRoot, X11, network, UID, and no-auth contract fixed. No Vulkan, D-Bus,
`/dev/shm`, Proton, Gamescope, AHardwareBuffer, or sister-repo PRoot changes
belong in that run.
