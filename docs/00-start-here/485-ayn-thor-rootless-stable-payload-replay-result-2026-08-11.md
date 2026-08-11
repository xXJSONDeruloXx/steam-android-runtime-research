# AYN Thor rootless verified stable ARM64 payload replay — result — 2026-08-11

Run ID: `thor-rootless-stable-payload-replay-20260811T175138Z`;
sub-run: `Thor-rootless-stable-payload-replay`.

Status: complete as a valid fresh rootless replay. It reproduced the
`vgui2_s` loader fatal before native SteamUI, but it did **not** establish that
the Android app-UID/PRoot boundary itself is the cause. The important
discriminant is the client payload: this run used the verified public stable
endpoint payload, while the earlier successful rootless R28 run and the
rooted comparison use the different sanitized public-beta client bytes.

## Result

The run held the Thor rootless Holo/PRoot, nested client layout, rooted
SteamRT-first environment, direct TCP Termux:X11, inherited Android network,
fresh app-owned state, and both Vulkan selectors unset. It changed the native
client payload to the verified stable ARM64 endpoint result from [doc
483](483-ayn-thor-rootless-stable-arm64-seed-short-temp-result-2026-08-11.md).

The measured boundary was:

```text
cold/stable payload staging                  pass
Holo rootfs and 161-package closure          pass
rootless preflight                           pass
short app-owned temporary paths              pass
fresh Termux:X11 and TCP 6077                pass
app-UID X11 handshake                        pass
native stable client launch                  pass
native SteamUI/webhelper                    not reached
Vulkan/provider                              not reached
first relevant failure                      vgui2_s loader fatal
exact-scope cleanup                          pass
preserved rooted rollback                    pass
```

Fresh Steam output contained:

```text
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
Error: Could not load 'vgui2_s.so'
Shutdown
```

There was no fresh `CVulkanTopology`, `steamwebhelper`, `/dev/shm`, D-Bus,
WSI, or Steam-frame evidence. Those later boundaries must not be inferred from
this run.

## The payload distinction

The stable endpoint payload actually staged for this run was:

```text
manifest_url=https://client-update.steamstatic.com/steam_client_linuxarm64
manifest_version=1785799196
payload_bytes=60815678
payload_sha256=38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148
decoded_zip_bytes=337453898
decoded_zip_sha256=aed451902b2239cbf8a16e1a2004e016cea803d562849a4969b01a93c9cb4821
steamrtarm64/steam=72f48fb9c3f2c19cf64f8f7bbf4c7b7af65a73571ae0eeaab05bffd1633f4126
steamrtarm64/steamui.so=25ad66cfc78590b1745301ae7b86b70db64f5be0cd142d33134796e203fc8b76
steamrtarm64/vgui2_s.so=705f45328bb03c42509d28b748b0b499938f5e0caf2db618e8c929f0c3044186
steamrtarm64/steamwebhelper=3176d90436e49f7d34524ca2686cd324e2583806ba78841852b189fbcee0b83c
```

Those bytes are not the R28/rooted client:

```text
R28/rooted steam       6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
R28/rooted steamui.so  69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
R28/rooted vgui2_s.so  aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
```

R28 used the latter client bytes in the same broad app-UID PRoot strategy,
crossed `vgui2_s`, initialized native SteamUI/system controllers, and started
webhelper. Therefore the Thor result is best classified as a **stable-client
loader regression/boundary**, not as proof that rootless execution can never
load `vgui2_s`.

The next replay must restore the R28 client bytes while keeping this run's
rootless environment fixed. It must not add root-only preloads, D-Bus,
`/dev/shm`, Vulkan selectors, or SteamUI patches.

## Fixed rootless launch contract

The effective guest contract was:

```text
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
```

Device: AYN Thor, serial `d234a848`, Android 33, `arm64-v8a`, app UID
`10138`, outer SELinux identity `u:r:runas_app:s0:c138,c256,c512,c768`.
The pinned Holo rootfs, KGSL files, resolver, PRoot, and fresh X11 handshake
all passed their declared checks. The Android device-log consent dialog was
not shown.

The failure screenshot was retained outside the repository at:

```text
/tmp/thor-rootless-stable-payload-replay-20260811T175138Z-evidence/x11-postfailure.png
dimensions=1920x1080
sha256=49bbbd738b340cbcfe30846a27c5a54c3c4d231c38c54deefa9065c1e0094107
visible=black Termux:X11 canvas, Android status bar, extra-key row, X cursor; not a Steam frame
```

## Cleanup and authentication boundary

The exact R34 device/app/Termux scopes were removed. The fresh X11 PID and
TCP 6077 listener were gone, the temporary `allow-external-apps` edit was
restored byte-for-byte, and the preserved rooted runtime paths remained
present. Post-cleanup free space was `24538352 KiB`.

The post-run filename-only scan observed `.steam/steam.token` and
`.steam/registry.vdf` inside the disposable R34 scope. Their contents were
never opened, copied, backed up, or exported; the complete exact R34 scope was
removed during cleanup. No Steam authentication secret, session state, QR
state, cookie, or authenticated Steam home was committed.
