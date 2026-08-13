# Nova 8-Bit Bayonetta root-proxy retry — prefix ownership boundary — 2026-08-13

## Run

This was the first authentic Steam-client launch after the official Runtime 4
root `bwrap` proxy passed its isolated smoke. App ID `567090` remained mapped
to `proton_11_arm64_official`; Steam ran as UID 501 and forwarded the launch
through its own IPC path. GameNative was not involved.

- Device: Nova serial `d234a848`.
- Rootfs: `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs`.
- Run-scoped Proton log: `/tmp/nova-proton-log-8bb-root-proxy-20260813T` inside
  the rootfs.
- Captured Proton log: 3,106 bytes, SHA-256
  `67b9b146fdc043bfc7cb85f6ca3996db9656df2e61a7abe51edce39aff6757f6`.
- A post-forward screen remained the authentic 8-Bit Bayonetta Steam library
  page, not a game frame; capture `t12` SHA-256
  `38de77c1f3751614feba6acbfea9c70d19f74b424a6eef203732a67dc2bbb9d6`.

## Evidence

Steam created the expected Proton log and command:

```text
SteamGameId: 567090
Command: ['/opt/nova-steam/home/.local/share/Steam/steamapps/common/8BitB/8BB.exe']
pressure-vessel: 0.20260805.0
steamrt4: 4.0.20260805.254769
```

The failure was:

```text
wineserver: .../steamapps/compatdata/567090/pfx is not owned by you
wine: '.../steamapps/compatdata/567090/pfx' is not owned by you
```

No `8BB.exe`, Wine, FEX, Proton, Pressure Vessel, or `winedevice` process
remained after the short attempt. The root proxy itself stayed alive because
the Steam client session was intentionally left running.

## Interpretation and fix

The root proxy successfully crossed the namespace boundary, but executing the
whole `bwrap` request as root changed the UID inside the container. The prefix
was owned by UID 501, so Wine correctly refused it. Chowning the prefix would
have hidden the identity error and would not preserve Steam's normal ownership
contract.

The next patch keeps root for `bwrap` mount/namespace setup, then inserts
`/usr/bin/setpriv --reuid=501 --regid=20 --groups=1005 --` immediately after
the bwrap command separator. The UID/GID/audio values are exported by the
Steam client wrapper and forwarded with the exact request environment. The
isolated Runtime 4 smoke will be repeated before another game attempt.
