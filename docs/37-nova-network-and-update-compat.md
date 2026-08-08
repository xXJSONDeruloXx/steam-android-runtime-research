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
sets `bRequireSteamRestart`, and the parent route interprets any truthy first
argument as a request to call `SteamClient.User.StartRestart(!1)`. A prior
attempt changed the callback to pass `{}`; that was still truthy and reproduced
the blank `MENU`/`BACK` state. The compatibility helper must instead call the
completion callback with an explicit false/undefined argument (`t(void 0)`),
which selects the route's actual no-restart branch and lets it navigate to
`GamepadUI.Login()` without
pretending the SteamOS host was rebooted. The patch is intentionally limited to
the known OOBE callback and is verified by a fresh bundle marker.

## Fresh transition isolation

The fresh manual session launched at approximately `2026-08-08 20:57:39`
(host session PID `47242`, Nova Activity PID `23925`) with:

- Gamescope:
  `android/nova-lab/build/gamescope-headless-build-libei/src/gamescope`;
- Gamescope SHA-256:
  `93f4807d55e4ad95e8cbd7c1622f97c3ccd7781952aec3b08cd44ee64a449e8f`;
- source tree:
  `android/nova-lab/build/gamescope-headless-source-six`, commit
  `fb9f84ee247a1f02b1a132da60e94585db84bf61`;
- `1280x960` nested/output/fullscreen presentation, AHB output, libei input,
  Android-keyevent input mode, and `NOVA_FORCE_GPU_COMPOSITION=0`.

Touch advanced the fresh OOBE sequence through language, timezone, and the
Android-host-network row. The updater shim recorded the current invocation and
the Steam UI `UpdateStore` reported `supports_os_updates=true`, update state
`7`, and successful (`eresult=1`) client and OS apply results. No new
`Updater apply error: 2` appeared.

The visible update surface nevertheless remained on
`UPDATING: CALCULATING TIME REMAINING...`. Calling the exact completion callback
with `{}` in DevTools reproduced `MENU`/`BACK`, proving that the first patch was
still taking the restart branch. The run was stopped with
`nova_runtime_cleanup=pass attempts=2` and
`native_steam_app_files_cleanup=pass`.

The source patch is now corrected from `t(n)`/`t({})` to `t(void 0)`. This correction
must be committed and pushed before the next long device session. Login remains
unproven until a fresh run reaches the login route after this correction.

## OOBE completion ordering boundary

The first run with the false/undefined no-restart result logged:

```text
SteamUI: WARNING: No restart requested
SteamUI: WARNING: /login blocked by parental controls feature 0
```

The bundle's navigation blocker uses `!GetOOBEComplete()` as an OOBE-mode lock.
The parent OOBE callback called `SetOOBEComplete()` and immediately navigated,
so the login route could race the asynchronous settings write and be rejected
before the completion state was observable. The compatibility helper now also
changes that callback to `await nl.op.SetOOBEComplete(),t(e,r)`. This remains an
OOBE-only ordering repair; it does not disable parental controls or bypass a
real lock. A fresh run must verify both the awaited completion and the login
surface.
