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

## Latest shim run

On the first fresh session with the helper installed, the device logged:

```text
nova_steamos_update_compat=pass
nova_steamos_update_args=--supports-duplicate-detection
nova_steamos_update_compat=pass
nova_steamos_update_args=--enable-duplicate-detection
SteamUI: WARNING: SetOOBEComplete
SteamUI: WARNING: Restarting PC
```

The previous updater error did not recur, but the visible Steam surface stayed
in a blank update/restart state (`MENU`, `BACK`) and did not yet expose the
login route. The session was then stopped with
`nova_runtime_cleanup=pass attempts=1` and
`native_steam_app_files_cleanup=pass`. This proves the missing-helper repair;
it does not yet prove the login gate. The next experiment is a fresh launch
against the persisted OOBE state, with the same run identity and process
cleanup discipline.

Inspection of the shipped UI bundle identified why: successful OOBE completion
sets bRequireSteamRestart, and the parent route calls
SteamClient.User.StartRestart(!1). That client restart does not return to the
login route in the Holo rootfs. The network compatibility helper now also
replaces that OOBE-only restart request with an empty completion result, which
lets Steam's existing route controller call GamepadUI.Login() without
pretending the SteamOS host was rebooted. The patch is intentionally limited to
the known OOBE callback and is verified by a fresh bundle marker.
