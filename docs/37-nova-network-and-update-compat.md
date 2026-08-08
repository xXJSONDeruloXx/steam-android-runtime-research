# Nova network and SteamOS update boundary

The Android host network is reachable from the Nova runtime. The live device
probe recorded:

- `wlan0=192.168.0.23/24` with the device on the active Wi-Fi route;
- ICMP success to `1.1.1.1` and `api.steampowered.com`; and
- a rootfs `curl` HTTPS request to
  `https://api.steampowered.com/ISteamWebAPIUtil/GetServerInfo/v0001/`
  returning HTTP 200 with `/etc/resolv.conf` set to `192.168.0.1`.

Steam nevertheless stopped at “Unable to download the required update (2)”.
The current client log identifies the missing boundary precisely:

```text
SteamClient: ... /usr/bin/steamos-polkit-helpers/steamos-update
Updater apply error: 2: null
```

That SteamOS host updater is not present in the Holo rootfs. The deploy path
now installs `device/nova-steamos-update-compat.sh` at that exact path. It is a
research-only no-op that returns success and records its arguments in
`/tmp/nova-steamos-update-compat.log`; it does not download or apply SteamOS
updates. Transport reachability and Steam content/login progress remain
separate acceptance checks.

The next fresh session must verify that the shim invocation is logged and that
the UI advances past the network/update page to the login screen. If it does
not, inspect the new updater invocation and Steam UI logs before changing the
network API compatibility patch.
