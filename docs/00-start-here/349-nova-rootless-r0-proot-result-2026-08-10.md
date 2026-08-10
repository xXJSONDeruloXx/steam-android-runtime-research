# Nova rootless R0 PRoot boundary result — 2026-08-10

Status: R0 pass. The Nova app UID can run the Holo ARM64 userspace through
official Termux PRoot without Magisk, `su`, `chroot`, or a privileged mount.
This is only a process/rootfs result; it does not yet prove X11 attachment,
native Steam UI, login, Proton, or games.

## Run identity

- Device: Retroid Pocket Nova, serial `675a2365`
- Run: `rootless-r0-loader-20260810T`
- Branch: `feat/rootless-steamclienttermux-profile`
- Source baseline: `fa95126` (`docs: predeclare rootless SteamClientTermux profile`)
- App UID: `u0_a128` / UID `10128`, package `com.xjsonderulo.steamandroid.novalab`
- Guest rootfs: `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs`
- Rootless staging: `/data/local/tmp/nova-rootless-r0`

The signed-in rooted Steam session remained running throughout. The rootless
probe used no rooted Steam home, Steam token, QR state, or authentication data.
The disposable rootless staging tree and app-private probe overlay are removed
after this result; the rooted runtime and active marker are not touched.

## External artifact provenance

The PRoot package was downloaded to the ignored host build directory from the
official Termux main ARM64 repository and verified against its package index:

| Artifact | Version | SHA-256 |
| --- | --- | --- |
| `proot_5.1.107.89_aarch64.deb` | 5.1.107.89 | `ec9fe38c50cfd49dd31fe360ffbcc3124a945dc1ea16293a8a769303dd724f46` |
| `libandroid-shmem_0.7_aarch64.deb` | 0.7 | `0da3a24d558b93c92bcf8d611e0826a99ff96e396b148e6cdf33b47c47c57ff6` |
| `libtalloc_2.4.3_aarch64.deb` | 2.4.3 | `ac81ad623d74c209718b9f3acb2dd702cc8a88c431e820d212229910b4db29da` |

The packages were unpacked only for the bounded probe. No PRoot or library
binary is committed to the repository.

## Probe sequence

The first direct PRoot invocation failed closed because the binary expected
the Termux library name `libtalloc.so.2`. Installing the exact package
symlinks fixed that loader error. The next invocation exposed two Termux-only
defaults:

```text
proot warning: can't canonicalize /data/data/com.termux/files/usr/tmp/
proot error: execve("/usr/bin/id"): No such file or directory
```

The Nova invocation then supplied both paths explicitly:

```text
LD_LIBRARY_PATH=/data/local/tmp/nova-rootless-r0/lib
PROOT_LOADER=/data/local/tmp/nova-rootless-r0/proot/loader
PROOT_TMP_DIR=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r0/tmp
```

With those variables, the app-UID PRoot guest passed:

```text
uid=0(root) gid=0(root) groups=0(root),...
aarch64
true_rc=0
overlay_rc=0
overlay_file_rc=0
```

The `uid=0` result is PRoot's virtual guest identity, not Android root. The
outer process was started by `run-as` as UID `10128`. The overlay test bound
the app-private directory
`/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r0/home`
onto guest `/opt/nova-steam/home`, created a file there, and verified it from
the app UID.

The versioned rooted runtime was readable by the app UID, and its world-
writable guest `/tmp` was usable. The rooted runtime's `/opt/nova-steam/home`
and `/etc` were not writable by the app UID, so a rootless launcher must use
explicit app-owned overlays rather than modifying the rooted tree in place.

## Acceptance

| Gate | Result |
| --- | --- |
| No Magisk/`su` in rootless execution | pass |
| ARM64 PRoot binary starts | pass |
| Holo glibc guest loader and `/usr/bin/id` | pass |
| Guest `uname -m` reports `aarch64` | pass |
| Guest trivial command | pass |
| App-owned writable overlay | pass |
| Rooted runtime preserved | pass |
| Termux:X11 attachment | not tested |
| Native Steam OOBE/QR in rootless profile | not tested |
| Proton/game first frame | not tested |

## Next bounded change

Add a profile-aware rootless supervisor that consumes the verified external
PRoot artifact, stages a separate Steam home, sets `PROOT_LOADER` and
`PROOT_TMP_DIR`, and fails closed when the display transport is unavailable.
R1 must prove a changing synthetic X11 frame before launching native Steam.
The device currently has `com.termux.x11` but no `com.termux` base package, and
the Nova app UID cannot read the X11 APK for the rooted `app_process`
`CLASSPATH` trick. The next display experiment must therefore use an exported
X11 activity/socket path or a separately installed Termux user supervisor.
