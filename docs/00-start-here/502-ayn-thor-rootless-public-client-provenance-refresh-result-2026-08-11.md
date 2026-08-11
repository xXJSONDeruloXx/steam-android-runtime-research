# AYN Thor rootless public-client provenance refresh — result — 2026-08-11

Run identity: `thor-rootless-public-client-provenance-refresh-20260811T223004Z`;
sub-run: `R35-public-client-provenance-refresh`.

Status: **valid `refresh-pass-different-public-client`**.

The normal public ARM64 updater completed in a fresh app-UID rootless fixture
and produced the expected native public-beta files, but the complete
sanitized archive did not match the historical R33/R34 fixture. The only
additional archive entry was the public CEF development-size marker
`.cef-dev-tools-size.vdf`. This result is a provenance boundary, not a
negative SteamUI, Vulkan, or OOBE result.

## Decision

R35 proves that the public ARM64 updater can refresh the reconstructed current
client under the Thor app UID and that it reaches the same native-client
startup boundary previously observed by the rooted comparator. It does not
recover the historical archive byte-for-byte:

```text
expected_archive_bytes=3457525760
expected_archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
post_archive_bytes=3457536000
post_archive_sha256=5264b48b73df88e4737b030cc71574ef0aca73186d80792bfdc1966f1908df35
post_archive_entries=21514
post_forbidden_filename_scan=empty
```

The post-refresh archive contained every seed entry plus exactly one new
entry:

```text
./steamrtarm64/.cef-dev-tools-size.vdf
size=71
sha256=d82fc37374e2668f6569102bd2ed13b8d21ebad019c5d1bf7fb825617d0d32a4
```

The next experiment is therefore a separately predeclared public-client
equivalence gate in [doc 503](503-ayn-thor-rootless-public-client-normalized-equivalence-predeclaration-2026-08-11.md).
It will test only whether quarantining this one updater-generated public file
recovers the historical archive fingerprint. It will not launch Steam or add
a graphics/session workaround.

## Provenance and identity

```text
branch=feat/rootless-steamclienttermux-profile
start_head=758db0f9f78152183a99ae90d20e88bfafce610e
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
root_identity=uid=0(root) gid=0(root) context=u:r:magisk:s0
getenforce=Permissive
sibling=/Users/kurt/Developer/steamclienttermux
sibling_head=8d14c10195b34fe2714ba59df1680df27a852532
```

The Nova worktree and the clean sibling checkout were unchanged at the
start. The rooted rollback paths were preserved throughout:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Fresh R35 scopes were:

```text
/data/local/tmp/thor-rootless-public-client-provenance-refresh-20260811T223004Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r35-public-client-refresh/
/data/data/com.termux/files/home/.nova-rootless/
```

No authenticated Steam home, userdata, cookies, QR/session state, machine-auth
file, or `steam.token` contents were read or copied.

## Controlled input and fixture gates

The controlled operation was: start from a fresh sanitized public ARM64 tree,
run the normal public updater, and classify the resulting sanitized tree. No
Vulkan selector, CEF flag, `/dev/shm`, D-Bus, Runtime 4, Proton, FEX,
Gamescope/AHardwareBuffer, SteamUI patch, or packaging change was added.

The pre-refresh seed matched its gate:

```text
seed_archive_bytes=3457524736
seed_archive_sha256=3b54ebe8dd92ebbe304376335d59da28ebd88b1467999d39fee1c07ec98cee9a
seed_tar_entries=21513
seed_forbidden_filename_scan=empty
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
```

The immutable runtime inputs remained the pinned values:

```text
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages plus 2 Debian GTK2 assets
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
libtalloc.so.2.4.3_sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid-shmem.so_sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
```

The provider files were staged only as immutable inputs. Both
`VK_DRIVER_FILES` and `VK_ICD_FILENAMES` remained unset, as did
`VK_LOADER_DEBUG`, `LD_PRELOAD`, the Mesa overrides, and software-rendering
variables.

## Valid launch

One earlier wrapper attempt was discarded: host quoting expanded the intended
`mkdir -p "$XDG_RUNTIME_DIR"` to `mkdir -p ""`. Its exact Steam/PRoot
processes were killed, its app scope was removed and rebuilt, and no evidence
from it is used below. The valid attempt started only after a fresh
app-UID rebuild and a passing preflight.

The effective guest command was:

```text
/bin/sh -c 'export HOME=/opt/nova-steam/home; export USER=steam; export LOGNAME=steam; export LANG=C; export LC_ALL=C; export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime; export PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin; export LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio; unset VK_DRIVER_FILES VK_ICD_FILENAMES VK_LOADER_DEBUG LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH; mkdir -p "$XDG_RUNTIME_DIR"; cd /opt/nova-steam/home/.local/share/Steam; exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui'
```

The supervisor ran with PRoot `-0`, only the declared `/dev`, `/proc`,
resolver, app-owned `/run`, HOME, Steam-client, and temporary-directory
bindings, and real outer UID 10138. Preflight reported:

```text
nova_rootless_preflight=pass uid=10138
nova_rootless_free_kib=10283408
display=127.0.0.1:77
```

Termux:X11 was fresh, PID `32664`, and listened on IPv4 and IPv6 TCP port
6077. The app-UID X11 handshake reached the server. The Android all-device
log consent dialog was not shown, so no scroll or ADB selection was sent:
`log_access_consent=not-shown`.

## Updater and client evidence

The updater reached the public-beta update endpoint and installed client
version `1786141909`:

```text
package/steam_client_steamdeck_publicbeta_linuxarm64.installed_sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
package/steam_client_steamdeck_publicbeta_linuxarm64.manifest_sha256=b81089d01988870f565fbc9f35b8de89b7f3658c4c5555bbe850ff742e3aef6f
installed_version=1786141909
```

The selected native files were unchanged and still matched the known public
beta tree. The updater and native client then produced these diagnostic lines:

```text
proot-shm-helper: Temporary path too long
CVulkanTopology: failed to get physical device count
vkEnumeratePhysicalDevices failed, unable to init and enumerate GPUs with Vulkan.
BInit - Unable to initialize Vulkan!
steam-runtime-launcher-service: Can't find session bus: Cannot spawn a message bus without a machine-id
src/steamUI/steamuisharedjscontroller.cpp (549) : Failed creating offscreen shared JS context
proot info: vpid 1: terminated with signal 4
```

The valid R35 run therefore did not produce a Steam frame or OOBE state. Its
screen remained a 1920x1080 black Termux:X11 canvas with Android bars and an X
cursor. It must not be described as a Steam screenshot or login result.

The webhelper log also recorded the expected missing shared-memory/session
prerequisites, including failure to access `/dev/shm` and inability to spawn a
private session bus without a machine-id. These are diagnostic observations,
not variables changed by R35.

## Prior-art cross-check

The clean sibling checkout remained at revision
`8d14c10195b34fe2714ba59df1680df27a852532`; the audited upstream source is
also available at [its pinned `steam-arm` launcher](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/bin/steam-arm).
It confirms that the working unrooted stack uses a compound contract: private
session D-Bus, PRoot shared temporary storage, a private Turnip ICD,
`VK_DRIVER_FILES`, Mesa/WSI variables, CEF GPU-disable, and bounded log
handling. Those are useful follow-up hypotheses, but importing them together
would destroy the current A/B, so none were added to R35.

The [Termux:X11 upstream instructions](https://github.com/termux/termux-x11#using-with-proot-environment)
specifically require PRoot `--shared-tmp`, or a `TMPDIR` that points at the
same temporary directory visible inside the target environment. R35 emitted
`proot-shm-helper: Temporary path too long`; this makes temporary-path/shared-
memory handling a concrete later hypothesis, separate from the client
provenance result. It is not predeclared as the immediate next run here.

Valve's [Steam Runtime documentation](https://github.com/ValveSoftware/steam-runtime)
also distinguishes the current SteamRT3-era native-client environment from
Runtime 4: Proton 11 and newer use Steam Runtime 4, while this R35 native
client experiment intentionally stayed on the existing SteamRT3C layout.

## Cleanup and rollback

After evidence capture:

```text
r35_device_scope=absent
r35_app_scope=absent
r35_termux_scope=absent
port_6077=absent
matching_steam_proot_webhelper_x11_processes=absent
termux_properties_restored_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
rollback_root=present
active_marker=present
post_cleanup_free_kib=21945604
```

The exact R35 device, app, and Termux scopes were removed. The temporary
`allow-external-apps = true` edit was reversed byte-for-byte. No broad process
kill or package-data clear was used.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.
