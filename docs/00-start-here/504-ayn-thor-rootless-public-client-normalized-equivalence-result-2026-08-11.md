# AYN Thor rootless updater-derived public-client equivalence — result — 2026-08-11

Run identity: `thor-rootless-public-client-generated-file-equivalence-20260811T232603Z`;
sub-run: `R36-public-client-generated-file-equivalence`.

Status: **invalid before updater launch: the required R36 seed was not
available from the preserved rooted tree**.

This closes the R36 gate without making a SteamUI, Vulkan, `/dev/shm`, D-Bus,
or OOBE claim. The rooted direct-X11 rollback paths were not changed.

## Decision

The device-side reconstruction contained the expected 21,513 sanitized tar
entries and no forbidden authentication-bearing names, and its selected native
files matched the R36 client hashes. Its complete archive fingerprint did not
match the predeclared R36 seed:

```text
expected_seed_bytes=3457524736
expected_seed_sha256=3b54ebe8dd92ebbe304376335d59da28ebd88b1467999d39fee1c07ec98cee9a
observed_seed_bytes=1755990706
observed_seed_sha256=738578bfafd6ed221999970b75ae3c08d96b463f0f4bfadfa885e0f1ac563f7c
observed_seed_tar_entries=21513
observed_forbidden_filename_scan=empty
```

The selected files were nevertheless the expected public-beta files:

```text
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
```

Matching selected files are not enough to call the full client fixture
equivalent. The preserved rooted tree currently reconstructs the older
public/bootstrap-era archive, not the exact updater-derived R35 input. The
right conclusion is therefore **R36 invalid / seed provenance blocker**, not
“rootless cannot boot Steam.”

The next experiment is predeclared in [doc
505](505-ayn-thor-rootless-public-seed-refresh-recovery-predeclaration-2026-08-11.md):
use the verified credential-free stable public seed and let the normal public
updater recover a fresh current tree, then apply the same one-file public-marker
normalization gate. No Steam launch is part of that next gate.

## Provenance and identity

```text
branch=feat/rootless-steamclienttermux-profile
start_head=8e1a760bf89b3c250d7f402430236e5e750beaba
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_identity=u:r:runas_app:s0:c138,c256,c512,c768
root_identity=uid=0(root) gid=0(root) context=u:r:magisk:s0
root_getenforce_query=permission_denied
sibling=/Users/kurt/Developer/steamclienttermux
sibling_head=8d14c10195b34fe2714ba59df1680df27a852532
```

The exact R36 device scope was:

```text
/data/local/tmp/thor-rootless-public-client-generated-file-equivalence-20260811T232603Z/
```

The app and Termux mutable scopes were not created because the seed gate failed
first:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r36-public-client-equivalence/
/data/data/com.termux/files/home/.nova-rootless/
```

The preserved paths remained present:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Input and construction evidence

The only host archive at the declared project path remains the older public
bootstrap seed:

```text
path=android/nova-lab/build/steam-bootstrap/steam-home.tar.gz
bytes=1756623692
sha256=1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124
```

To avoid substituting it silently, R36 reconstructed a fresh archive from the
preserved rooted Steam tree using Holo `bsdtar 3.8.2` and the documented
sanitization exclusions. A first UID-normalized construction stopped with a
truncated 624,230,400-byte archive; that partial file was discarded inside the
R36 scope; its partial SHA-256 was
`9728ba1c7f1171ac271ce7a3ab4f54ec5e7c102a28503b664c9a3f41da96fd4c`.
A root-side retry completed and produced the observed 1,755,990,706-byte
archive above. Neither archive was used to launch Steam.

The reconstruction was read-only with respect to the source tree. The only
temporary files were inside the exact R36 device scope. No updater, rootless
PRoot, SteamUI, webhelper, or Termux:X11 session was started, so:

```text
log_access_consent=not-run
display=not-started
port_6077=not-started
screenshot=not-captured
steam_ui_result=not-run
vulkan_result=not-run
```

## Rootless-versus-rooted interpretation

The known-good rooted Thor comparator is already recorded in [doc
486](486-ayn-thor-rooted-known-good-oobe-comparison-result-2026-08-11.md):
the same selected public-beta native files reached Steam OOBE and QR sign-in
under the rooted profile. Earlier valid rootless current-tree evidence in [doc
490](490-ayn-thor-rootless-public-beta-equivalence-replay-result-2026-08-11.md)
crossed `vgui2_s`, initialized native SteamUI, and started webhelper before
stopping at later runtime prerequisites. R36 does not overturn either result;
it only shows that the exact full-tree fixture cannot be reconstructed from the
current preserved tree without a fresh public update.

The measured rootless blindness is therefore not yet a `vgui2_s` rule. The
remaining rootless-versus-rooted contracts that still deserve isolated tests
are:

- rootless has no rooted `/dev/shm` contract; R35-era runs reported the
  Chromium shared-memory failure;
- rootless has no guest machine-id/private session-bus contract; the rooted
  comparator supplied D-Bus and SteamOS-side services;
- rootless Vulkan provider selection remains separate from client provenance;
  the Thor `VK_DRIVER_FILES` A/B must use a verified current client fixture;
- the rooted comparator also changed CEF, mount, UID/GID, input, and preload
  contracts together, so its success cannot attribute one of those alone.

The clean sister checkout remains useful prior art, not a drop-in fix. Its
audited launcher combines private D-Bus, `--shared-tmp`, private Turnip and
Mesa paths, `/proc/net` route visibility, CEF GPU disable, audio, and a patched
PRoot. Upstream Termux:X11 likewise explicitly requires PRoot
`--shared-tmp`, or a `TMPDIR` that maps to the same temporary directory. Those
are follow-up hypotheses, not variables imported into R36. See the pinned
[SteamClientTermux launcher](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/bin/steam-arm)
and [Termux:X11 PRoot guidance](https://github.com/termux/termux-x11#using-with-proot-environment).

## Cleanup and authentication boundary

After capture, exact-scope cleanup verified:

```text
r36_device_scope=absent
r36_app_scope=absent
r36_termux_scope=absent
matching_steam_proot_webhelper_x11_processes=absent
port_6077=absent
termux_properties_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
rollback_root=present
active_marker=present
post_cleanup_free_kib=21831924
```

Host evidence was retained outside the repository at
`/tmp/thor-rootless-public-client-generated-file-equivalence-20260811T232603Z-evidence/`;
it contains the device identity, seed gate, selected hashes, forbidden-name
scan, and post-cleanup record.

Termux was only started to read its existing settings file and was force-stopped
afterward; its properties were not edited. No broad process kill or package-data
clear was used.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.
