# AYN Thor rootless short-temporary-path public-seed result — 2026-08-11

Run ID: "thor-rootless-short-temp-public-seed-20260811T161200Z";
sub-run: "Thor-rootless-public-arm64-seed-short-proot-temp".

Status: complete as a valid cold-provisioned infrastructure/client-boundary
run. The short app-owned PRoot temporary-path contract removed the earlier
"proot-shm-helper: Temporary path too long" warning. The older public ARM64
seed still stopped at Steam's native "bin/vgui2_s.dll" handoff, so the run did
not reach Vulkan, SteamUI, webhelper, or a Steam frame. It is not an R31
provider-selector result.

## Result and classification

The Thor device had no intact r32 fixture at the start, so this followed the
updated lifecycle's cold-provisioning path. Only verified immutable inputs were
reused from the host staging fixture. The app-owned Steam tree, state, logs,
resolver, temporary directories, X11 server, socket/listener, screenshot, and
readiness baselines were fresh.

The short-path question is closed:

~~~text
rootfs archive extraction                 pass
161-package plus 2-asset closure          pass
rootless supervisor preflight             pass
fresh X11 foreground/lifecycle            pass
app-UID PRoot xprop handshake             pass
proot temporary-path warning              absent
public seed update transaction            not observed
native vgui2_s handoff                    fail
Vulkan/provider                           not reached
SteamUI/webhelper/visible Steam frame     not reached
~~~

The fresh launch output contained:

~~~text
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
Error: For more information visit https://support.steampowered.com/kb_article.php?ref=9205-OZVN-0660
Could not load module 'vgui2_s.so'
[2026-08-11 17:16:47] Shutdown
~~~

The temporary-path warning did not appear in the fresh launch, bootstrap, or
update-UI logs. This closes that independent PRoot infrastructure boundary;
the remaining vgui2_s result belongs to the older public seed and must not be
interpreted as a Vulkan, WSI, /dev/shm, D-Bus, or SteamUI result.

## Provenance

~~~text
branch=feat/rootless-steamclienttermux-profile
start_head=400fb9d487d7247cbebfcd18db3d6da1e5a43f81
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
~~~

At run start, the worktree also contained three pre-existing, user-owned
unstaged documentation edits in 06-android-linux-gamescope-roadmap.md,
34-nova-runtime-harness-lifecycle.md, and the R31 predeclaration. They were
not changed, staged, or committed by this run.

The installed APK was:

~~~text
android/nova-lab/build/nova-lab-debug.apk
size=30692978
sha256=5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08ad8e257a682
~~~

The immutable fixture inputs were verified on the device before use:

~~~text
Holo system.rootfs.zst
  size=384971555
  sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
Holo package files=161
external GTK2 Debian files=2
libgtk2.0-0_2.24.33-2+deb12u1_arm64.deb
  size=1664872
  sha256=d035cfd259b330a641a6b7310748ba2f42903b795d4923fa4fb23bacb872ac07
libgtk2.0-common_2.24.33-2+deb12u1_all.deb
  size=2659900
  sha256=f55a9800d3721b1de246e4bfaf94a63ca50efdfa49eb5fa2362ed4fa79258299
PRoot
  sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
PRoot loader
  sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
libtalloc.so.2.4.3
  sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid-shmem.so
  sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
libvulkan_freedreno.so
  size=12364688
  sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json
  size=194
  sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
~~~

The PRoot library staging retained the required libtalloc.so and
libtalloc.so.2 symlinks to libtalloc.so.2.4.3. The provider files were
staged under the guest's /opt/nova-kgsl-driver/ with the hashes above, but
both Vulkan selector variables remained unset for this public-seed run.

The client archive was the older public seed, not the exact sanitized rooted
public-beta archive required by R31:

~~~text
archive_size=1756623692
archive_sha256=1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124
steam bootstrap version=1785979169
installed manifest first record=androidarm64/,-1;1785979614;0
steamrtarm64/steam
  sha256=cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85
steamrtarm64/steamui.so
  sha256=972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0
steamrtarm64/vgui2_s.so
  sha256=a3e010415d3b1cda22a9fe6ad8e5a33e558113483cbc7639ec4cae560c676dd7
~~~

The client was extracted as the fresh nested tree visible at
/opt/nova-steam/home/.local/share/Steam. The supervisor also created the
declared fresh /home/nova/.steam/steam -> /opt/nova-steam link. The sanitized
archive's nested home/.steam links remained relative links into its own
home/.local/share/Steam; no client library was renamed or patched.

## Launch contract and display evidence

The effective fixed guest environment was the rooted parity contract:

~~~text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
DISPLAY=127.0.0.1:77
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH VK_ICD_FILENAMES VK_DRIVER_FILES
cd /opt/nova-steam/home/.local/share/Steam
exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui
~~~

The PRoot supervisor preflight and launch ran as app UID 10138; root was used
only for staging, the temporary Termux setting, evidence capture, and exact
cleanup. The launch did not use su, chroot, a mount escape, or an Android
privilege change.

Fresh network evidence showed validated Wi-Fi on wlan0, address
192.168.0.8/24, gateway 192.168.0.1, and DNS 192.168.0.1. The guest used
the fresh app-owned resolver containing only nameserver 192.168.0.1.

The X11 server was PID 6809, launched as
termux-x11 com.termux.x11 :77 -listen tcp -ac, with listeners on
0.0.0.0:6077 and [::]:6077. The app-UID xprop -root handshake passed.
The X11 log reported a fresh 1920x970 surface and enumerated an attached
Xbox Wireless Controller, but no Steam input/UI state was reached.

The Android device-log consent dialog was not shown. The current capture was
an X11 black canvas with the keybar and X cursor, not a Steam frame:

~~~text
path=/tmp/thor-rootless-short-temp-public-seed-20260811T161200Z-evidence/steam-result.png
dimensions=1920x1080
size=41410
sha256=5340e2289714ce398f0adeadef407e02829f582d95c5fcac7fed8858f38b9313
~~~

Read-only device-node evidence recorded /dev/kgsl-3d0 as
crw-rw-rw- system:system u:object_r:gpu_device:s0; the app UID could stat
and read the node. No Vulkan call was reached, so this is only a baseline and
not a GPU-usability conclusion.

## Evidence and cleanup

Fresh host evidence is retained at:

~~~text
/tmp/thor-rootless-short-temp-public-seed-20260811T161200Z-evidence/
~~~

Key evidence hashes are:

~~~text
preflight.txt             296ed1e6ac2b45aa956b4a448cfd866293edbec5558574cf84f2ad28b61352bd
rootfs-extract.txt        fe791008d86034842b558d8bc40b9471ce609144a40443942716d1b6055c58bf
guest-closure.txt         598a675f13c5bbf45322ef8c7d331e9420821ce75d2a9d10a9b7ec19d9177d5e
xprop.txt                 cafea4622153e10d67614b51ce800dbe6831ce9589b9364b87787e88f2143e32
steam-launch.txt          359d327d4cff0614889282a75fa2556b9f87a1a75af92509e913dac9f2599133
bootstrap_log.txt         e38f80a17b3f32a63fa3e70a3789bb4e8abd4865fc2ab453f3e38316f742635e
updateui_child.txt        91d5fd07d063545403f8cdf317640a454bfe130acf221d3132952610798d3194
rootless-supervisor.log   b1e03c50db927a3a1e7cde2671202639804edf78e55233f323149e5c6ce8a169
termux-x11-77.log         a634893135137106cd5a54ea92b471debe37db69195ef9e7ac9fdd6b7b7c8cda
cleanup.txt               8be775c69dbd8009b4f7b24f19b0f000a9dee50a7942cf30a55a98f6a653ac27
~~~

The exact PID 6809 was verified before termination. Nova and Termux:X11
were force-stopped, then only that PID and the exact helper files were
removed. The original Termux properties file was present before the run,
temporarily changed only to enable allow-external-apps = true, and restored
byte-for-byte:

~~~text
before_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
after_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
~~~

Only these run-specific scopes were removed:

~~~text
/data/local/tmp/thor-rootless-short-temp-public-seed-20260811T161200Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r32/
/data/data/com.termux/files/home/.nova-thor-short-temp/
/data/data/com.termux/files/home/.nova-rootless/termux-x11-77.log
/data/data/com.termux/files/home/.nova-rootless/termux-x11-77.pid
~~~

They were verified absent. No Steam, PRoot, webhelper, or Termux:X11 process
remained and no 6077 listener remained. Post-cleanup free space was
24541976 KiB. Thor happened to contain the two Nova rooted paths below;
they were outside this run's scope and were not read, copied, or modified:

~~~text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
~~~

No Steam authentication secret, session token, cookie, QR state, or
authenticated Steam home was read, copied, backed up, committed, or exported.

## Next boundary

The short temporary-path boundary is closed. The next experiment is
predeclared separately in doc 482:
test the stable ARM64 client pairing through the same short-temp, rooted-parity
environment. It must keep provider selectors unset and must not combine a
stable-client change with /dev/shm, D-Bus, Runtime 4, Proton, Gamescope,
SteamUI, or packaging changes.
