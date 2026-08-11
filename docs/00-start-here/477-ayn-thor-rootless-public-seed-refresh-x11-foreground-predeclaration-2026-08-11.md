# AYN Thor rootless public-seed refresh — X11 foreground rerun predeclaration — 2026-08-11

Run identity: `thor-rootless-public-seed-refresh-x11-foreground-20260811T155135Z`;
sub-run: `Thor-rootless-public-arm64-seed-x11-foreground`.

Status: predeclared. The preceding public-seed refresh was invalidated at an
infrastructure boundary: the app-UID PRoot process reached Steam's updater,
but Termux:X11 disappeared before `XOpenDisplay`. A standalone app-UID
`xprop` handshake succeeded after the Termux:X11 activity was explicitly
brought to the foreground. This rerun changes only that X11 lifecycle
condition; it is not a Vulkan or Steam-client experiment.

## Prior-run evidence

The first refresh used the same Thor Holo/PRoot setup and the credential-free
public seed. It produced:

```text
rootless_preflight=pass uid=10138
Client version: 1785979169
CBaseLinuxUpdateUI::BaseCreateWindow: XOpenDisplay failed
src/steamexe/main.cpp (1433) : failed to initialize update status ui, or create initial window
exit=152
```

At the time of the failure, the previously launched `termux-x11` process had
exited. After explicitly launching `com.termux.x11/.MainActivity` and starting
the Nova X11 bridge again, the server stayed present and an app-UID PRoot
`xprop -root _NET_SUPPORTED` completed successfully. The prior run's evidence
is retained at:

```text
/tmp/thor-rootless-public-seed-refresh-20260811T153030Z-evidence/
```

It is not reused as readiness or screenshot evidence for this rerun.

## Fixed inputs and one lifecycle change

Keep the previous refresh probe fixed:

- AYN Thor `kalama`, serial `d234a848`, Android API 33, app UID `10138`;
- verified Holo rootfs and 161-package/GTK2 closure;
- app-UID PRoot `-0`, `/dev`, `/proc`, resolver, fresh app-owned state, and
  inherited Android network;
- nested `/opt/nova-steam/home/.local/share/Steam` layout;
- public seed bootstrap archive size `1756623692`, SHA-256
  `1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124`;
- Steam client version `1785979169` at the start;
- no authentication, QR/session data, cookies, userdata, or user config;
- no `VK_DRIVER_FILES`, `VK_ICD_FILENAMES`, Mesa overrides, `/dev/shm`,
  D-Bus, Runtime 4, Proton, Gamescope/AHardwareBuffer, or SteamUI patch; and
- normal updater flags: omit `-nobootstrapperupdate` while retaining
  `-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox
  -skipinitialbootstrap -no-child-update-ui`.

The sole lifecycle change is:

1. start the fresh Termux:X11 server on `:77` through the Nova bridge;
2. explicitly launch `com.termux.x11/.MainActivity` and verify the fresh
   server PID/listener; and
3. run an app-UID PRoot `xprop` handshake before starting Steam.

Do not use the old X11 PID, listener, state, logs, or screenshot as evidence.

Fresh rerun scopes:

```text
/data/local/tmp/thor-rootless-public-seed-refresh-x11-foreground-20260811T155135Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/thor-public-refresh-x11/
/data/data/com.termux/files/home/.nova-thor-public-refresh-x11/
```

## Evidence and classification

Capture the X11 PID/listener, app-UID `xprop` result, exact launch command,
bootstrap/update logs, post-run client hashes, SteamUI/webhelper milestones,
process state, screenshot, and cleanup/free-space evidence. Classify only the
client-refresh question:

- exact R31 client hashes after a successful public update;
- a different public client tree after update; or
- another refresh failure, with any X11/display cause kept separate from
  client, Vulkan, WSI, `/dev/shm`, and D-Bus conclusions.

After capture, terminate only the fresh PRoot/Steam and Termux:X11 processes,
remove only the three rerun scopes, and restore Thor's original Termux
`termux.properties` from the run-scoped backup. No Nova rollback-path claim
applies to this device.
