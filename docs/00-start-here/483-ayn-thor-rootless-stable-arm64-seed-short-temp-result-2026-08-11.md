# AYN Thor rootless stable ARM64 seed with short PRoot temporary path — result — 2026-08-11

Run ID: thor-rootless-stable-arm64-short-temp-20260811T172139Z; sub-run:
Thor-rootless-stable-arm64-seed-short-proot-temp.

Status: complete as a valid cold-provisioned short-temporary-path and
stable-channel selection run. The exact stable manifest and ARM64 payload were
retrieved and verified, and removing the beta selector made the client report
the stable channel. The staged client bytes did not refresh to that stable
payload before launch, however: the old public-seed native files remained in
place and Steam returned the same bin/vgui2_s.dll/vgui2_s.so fatal. This run
therefore does not establish the behavior of the actual stable native payload,
and it did not reach Vulkan, native SteamUI, webhelper, or a Steam frame.

## Result and classification

The measured boundary is:

~~~text
cold rootfs extraction                         pass
161-package Holo plus 2 GTK2 assets            pass
rootless preflight                             pass
short app-owned PRoot temporary paths          pass
fresh X11 bridge and foreground lifecycle      pass
app-UID TCP X11 handshake                      pass
Android device-log consent                    not-shown
stable endpoint manifest/payload provenance     pass
stable channel selection                       pass
stable payload update transaction              not observed
native stable payload actually staged           no
old public-seed vgui2_s fatal                  fail
Vulkan/provider                                not reached
SteamUI/webhelper/visible Steam frame         not reached
~~~

The launch produced:

~~~text
[2026-08-11 17:47:01] Client beta changed from '' to 'steamdeck_stable'
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
Could not load module 'vgui2_s.so'
[2026-08-11 17:47:02] Shutdown
~~~

The short-path warning from the preceding Thor run did not recur. The
stable-channel marker was recognized, but there was no download, extraction,
Update complete, launching..., or post-update package transaction. The
pre- and post-launch native hashes were identical to the older public seed.
This is evidence that selector removal alone did not consume the verified
stable ARM64 payload in this launch profile; it is not evidence that the
stable ARM64 build itself still requests vgui2_s.dll.

The final run was re-staged from empty scopes after an early USB transport
interruption during the first input copy. That partial scope was removed by
exact path before the measured extraction, so no state, log, process, socket,
screenshot, or readiness result from the interrupted attempt was reused.

## Provenance

~~~text
branch=feat/rootless-steamclienttermux-profile
start_head=7f4ed5c0c1cd2b7ecba6071409648815a796eb4c
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
~~~

The checkout already contained three user-owned unstaged documentation edits
in 06-android-linux-gamescope-roadmap.md,
34-nova-runtime-harness-lifecycle.md, and the R31 predeclaration. They were
not changed, staged, or committed by this run.

The installed APK was verified as:

~~~text
android/nova-lab/build/nova-lab-debug.apk
size=30692978
sha256=5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08ad8e257a682
~~~

The immutable runtime inputs were rechecked on Thor:

~~~text
Holo system.rootfs.zst
  size=384971555
  sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
Holo UI/audio closure=161 packages plus 2 Debian GTK2 assets
PRoot sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
PRoot loader sha256=44ef39c1e1a18c09f6e4c4b5d8f6b8ba82d30596598bd155ec162d05c5122ff04
libvulkan_freedreno.so
  size=12364688
  sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json
  size=194
  sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
~~~

The provider files were copied into the guest at
/opt/nova-kgsl-driver/ as regular files with modes 0755 and 0644. Both
VK_ICD_FILENAMES and VK_DRIVER_FILES remained unset, as did the other
exploratory Mesa and preload variables.

## Stable endpoint and staged client

The official stable endpoint was fetched on the host:

~~~text
manifest_url=https://client-update.steamstatic.com/steam_client_linuxarm64
http_status=200
manifest_bytes=12579
manifest_sha256=a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91
stable_version=1785799196
payload=bins_linuxarm64_linuxarm64.zip.vz.11771d05f91515ca5337eeb9baf835098df71d3a_60815678
payload_bytes=60815678
payload_sha256=38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148
decoded_zip_bytes=337453898
decoded_zip_sha256=aed451902b2239cbf8a16e1a2004e016cea803d562849a4969b01a93c9cb4821
decoded_entries=55
decoded_crc32=verified
~~~

The VZ payload was decoded with the documented Valve VZ header/footer and
LZMA1 filter contract. Its selected native files are the expected stable
build:

~~~text
steamrtarm64/steam
  sha256=72f48fb9c3f2c19cf64f8f7bbf4c7b7af65a73571ae0eeaab05bffd1633f4126
steamrtarm64/steamui.so
  sha256=25ad66cfc78590b1745301ae7b86b70db64f5be0cd142d33134796e203fc8b76
steamrtarm64/vgui2_s.so
  sha256=705f45328bb03c42509d28b748b0b499938f5e0caf2db618e8c929f0c3044186
steamrtarm64/steamwebhelper
  sha256=3176d90436e49f7d34524ca2686cd324e2583806ba78841852b189fbcee0b83c
~~~

Those hashes are endpoint-payload provenance only; they were not the hashes
launched in this run.

The fresh staged client came from the previously verified, credential-free
public seed:

~~~text
archive_bytes=1756623692
archive_sha256=1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124
prelaunch_package_beta=absent
prelaunch_steamrtarm64/steam=cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85
prelaunch_steamrtarm64/steamui.so=972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0
prelaunch_steamrtarm64/vgui2_s.so=a3e010415d3b1cda22a9fe6ad8e5a33e558113483cbc7639ec4cae560c676dd7
prelaunch_steamrtarm64/steamwebhelper=3901a2af2b9348a4b6381162c3913d607fcf7e959996b8388fd571f4a0d1cd8f
postlaunch_hashes=identical_to_prelaunch
~~~

The seed still contained the public-beta installed marker and manifest, while
the channel selector file package/beta was absent. The launch's Client beta
changed line proves that Steam saw the selector transition, but the unchanged
native hashes and missing update transaction show that the official stable
payload was not applied before the native launch.

## Fixed launch contract

The guest remained on the rooted SteamRT-first environment and direct TCP
Termux:X11 profile:

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

The PRoot supervisor ran under app UID 10138 with -0, /dev and /proc
bindings, fresh files/r33/proot-tmp and files/r33/tmp, and a fresh
app-owned resolver containing only nameserver 192.168.0.1. Preflight
reported 12426372 KiB free immediately before launch.

Fresh Android network evidence showed validated Wi-Fi on wlan0,
192.168.0.8/24, gateway 192.168.0.1, and DNS 192.168.0.1.

Read-only KGSL evidence was captured separately from Vulkan behavior. Root
staging reported getenforce=Permissive, root identity
u:r:magisk:s0, and /dev/kgsl-3d0 as
crw-rw-rw- system:system u:object_r:gpu_device:s0. The app identity was
u:r:runas_app:s0:c138,c256,c512,c768 and could stat/read the node. Steam
never reached a Vulkan call, so this is not a Vulkan usability result and no
device node permissions or SELinux state were changed.

## Display and consent evidence

The APK bridge created the default Termux helper scope because the current
bridge does not propagate a custom NOVA_ROOTLESS_TERMUX_STATE:

~~~text
/data/data/com.termux/files/home/.nova-rootless/termux-x11-77.log
/data/data/com.termux/files/home/.nova-rootless/termux-x11-77.pid
~~~

The fresh X11 server was PID 27364, command
termux-x11 com.termux.x11 :77 -listen tcp -ac, with listeners on
0.0.0.0:6077 and [::]:6077. Foregrounding
com.termux.x11/.MainActivity succeeded. The app-UID TCP/display handshake
passed; xprop reported _NET_SUPPORTED: no such atom on any window, which is
a root-window state observation rather than a connection failure.

The Android device-log consent dialog was not shown in this run, so no scroll
or tap was issued. The final screenshot was a black Termux:X11 canvas with
the X cursor, status bar, and keyboard keybar—not a Steam frame:

~~~text
path=/tmp/thor-rootless-stable-arm64-short-temp-20260811T172139Z-evidence/steam-result.png
dimensions=1920x1080
size=41981
sha256=6efecdf696328c7c479b291428debb967d8aeaa678dd745676a00f24e924c9ac
~~~

The X11 log recorded a fresh surface changing from 1920x1080 to 1920x970
after the Android keybar appeared. That is the current direct Termux:X11
display baseline; this run did not test a 4:3 Nova target because Steam never
produced a frame.

## Evidence and cleanup

Fresh host evidence is retained at:

~~~text
/tmp/thor-rootless-stable-arm64-short-temp-20260811T172139Z-evidence/
~~~

Key evidence hashes:

~~~text
apk-and-device.txt       00d419e5ba0ee74089da2a3acf53998105bc55fc9a4b7d8c2d2acf8aaf87bd79
rootfs-extract.txt       e24b86eeea9a4a6345e52fd199da243664e91dcce7492d2bef35a62fbb4b42f9
client-extract.txt       0c93917961184508072874aafa1937b3e0f62b806ab339fbc8adc7ede1cc59f0
guest-closure.txt        3acecf825d90dd0fd735829c77153812dfa2045f7d63c1a9f59944b2035d4a53
preflight.txt             e62507cd51d26121b105534bf5b3587efb07abf5bfee40e44b3bc24b85375dc4
launch-command.txt        e60cda5d0a8d267b6716eae5c5f3c599d94331e7e078e83d64c755092de250f2
steam-launch.txt          077edcbd5c402ca7e43d80fdf5b4dbbecef1432c3cf4ccfd14f7c4f3683b758c
bootstrap_log.txt         e91c8445ae5be537d61bf6cb32be2798e05b0576844529dd6aad1c02f99791ad
updateui_child.txt       916ca0b6be208b571c9d668499c48ec30b8a87ea1242a8224226d21cd91e50fb
rootless-supervisor.log   8d74a49b8bb9db337166cc810e407f2c1edbb4a39261cfd73bcd2a2baf1e27d0
termux-x11-77.log         b1a54cd8baf6f15c8c1d1ed700b1bc45686ad0f1f47929a366a5cbe67e02ffe7
steam-result.png          6efecdf696328c7c479b291428debb967d8aeaa678dd745676a00f24e924c9ac
cleanup.txt               4866d07faf1ca0804c3ca13b6acd159a40bfdddc5e4766349b002c0404eb561c
~~~

The exact X11 PID was verified and terminated. Nova and Termux:X11 were
force-stopped. Termux's temporary allow-external-apps = true edit was
restored byte-for-byte:

~~~text
before_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
after_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
~~~

Only these run-specific targets were removed and verified absent:

~~~text
/data/local/tmp/thor-rootless-stable-arm64-short-temp-20260811T172139Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r33/
/data/data/com.termux/files/home/.nova-thor-stable-arm64/
/data/data/com.termux/files/home/.nova-rootless/termux-x11-77.log
/data/data/com.termux/files/home/.nova-rootless/termux-x11-77.pid
~~~

No Steam, webhelper, PRoot, or Termux:X11 process remained; no 6077 listener
remained; and post-cleanup free space was 24523220 KiB. The preserved rooted
rollback paths remained present:

~~~text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
~~~

No Steam authentication secret, session token, cookie, QR state, or
authenticated Steam home was read, copied, backed up, committed, or exported.

## Decision

The short temporary-path boundary is closed on Thor. The stable endpoint
provenance gate is also closed, but the measured selector run stopped before
the endpoint's stable native package was consumed. The next experiment is
predeclared in doc 484: stage only the verified official stable ARM64 native
payload into a fresh client tree, keeping the current rooted environment,
display, UID, network, provider-selector state, and flags fixed. Vulkan,
/dev/shm, D-Bus, Runtime 4, Proton, Gamescope/AHardwareBuffer, and SteamUI
patches remain deferred.
