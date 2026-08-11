# Nova rootless R18 — beta-seed setup rejection — 2026-08-11

Run ID: `nova-rootless-r18-steam-layout-20260811T105432Z`; sub-run:
`R18-rootless-supervisor-steam-stable-layout-links`.

Status: rejected setup attempt; not a client-channel result.

## Reason for rejection

The R18 predeclaration required the copied Steam seed to have
`steam-client/package/beta` removed so that Valve's stable ARM64 manifest
would be selected. The host staging command copied the seed without applying
that one required mutation. The fresh device log therefore immediately
reported:

```text
Opted in to client beta 'steamdeck_publicbeta' via beta file.
You are in the 'steamdeck_publicbeta' client beta.
```

This was caught before treating any client behavior as evidence. The run was
stopped while the public-beta update was still downloading. No SteamUI,
`steamwebhelper`, visible-frame, or layout-link conclusion may be drawn from
this attempt.

## What did pass before rejection

The fresh R18 APK and input staging were otherwise the declared profile:

- APK SHA-256:
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08ad8e257a682`.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo archive extraction: pass.
- 161-package Holo/UI-audio closure: pass.
- App-UID supervisor preflight: pass, with fresh free-space check
  `80209280 KiB`.
- The five declared `.steam` links were created and verified in the fresh
  app-owned home.
- No Steam authentication data was read or exported.

The setup also exposed two mechanical staging issues, both fixed before the
rejected launch and independent of the channel hypothesis: the pushed PRoot
library directory had one extra nesting level, and the app-scope executable
normalization command initially named nonexistent paths. The known
`libtalloc` links and bootstrap/native executable modes were corrected before
the supervisor preflight passed.

## Cleanup

The exact mutable scopes were removed after terminating the explicit R18
process tree and the `termux-x11` server PID:

```text
/data/local/tmp/nova-rootless-r18-steam-layout-20260811T105432Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r18/
/data/data/com.termux/files/home/.nova-rootless/
```

Post-cleanup verification reported:

```text
remote_r18=absent
app_r18=absent
termux_rootless=absent
Steam/PRoot/webhelper/bsdtar/pacman matches=none
termux-x11=none
127.0.0.1:6077 listener=absent
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs=present
/data/local/tmp/nova-active-runtime=present
```

The partial host capture was retained only as setup evidence:

```text
/tmp/nova-r18-steam-stable-layout-command.log
size=1013
sha256=570d43702153eb5e48416b1ce7e33c266517a3d2ba329c9d5538c10dc7bc2d05
```

It contains the fresh preflight and launch prefix, but not a complete result;
the interrupted download output is intentionally not used as acceptance
evidence.

## Corrective action

Before the next R18 run, verify on the app-owned staged seed—not only on the
host source—that:

```text
test ! -e files/r18/steam-client/package/beta
```

Then recreate the exact R18 scopes and repeat the same stable-channel,
`.steam`-link, rootless/X11 experiment. No other variable is authorized to
change.
