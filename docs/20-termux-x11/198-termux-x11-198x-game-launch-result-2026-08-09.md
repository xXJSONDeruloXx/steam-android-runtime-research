# Termux:X11 198X game-launch boundary result — 2026-08-09

Status: display and signed-in Steam UI remained healthy, but the first game
launch attempt failed before the Windows executable reached Proton/Wine. This
is a game-runtime result, not a regression of the QR-login or rendering path.

## Run identity and provenance

```text
run_id=termux-x11-20260809T190803Z-qr-login-interactive-0
post_login_snapshot=post-login-game-20260809T194653Z
repo_commit_at_launch=67de0e005f7bbaf3ed33764e97ac9ca5c7c180fa
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
termux_x11_apk=/tmp/nova-x11-prior-art-20260809/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_client=android/nova-lab/device/nova-termux-x11-steam-client.sh
x11_client_sha256=a5d032caeda8c34f0384201c14f9dd91fc4394beaad2cfdcaf6d80246143299c
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
steam_uid=501:20
client_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu
```

The captured artifacts are in the ignored local run directory:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T190803Z-qr-login-interactive-0/post-login-game-20260809T194653Z/
```

The Steam log set was copied before teardown. The small acceptance set is
identified by these SHA-256 values:

```text
android-screenshot.png  cece7206bc8a1a8e34979d3e899539b0ccd16a6f8f87d2077ca386023b561003
client.stdout          50edd6983b9bea0d88f63c998ba3f3accc85f527d666f4c54561a2e0e5faf160
client.stderr          8ef1f329f21c12751f45b5de2822c3cfff9f127c999c3f3c85e0cc7cea226f9b
logs/gameprocess_log.txt fff49ca51d06a685e6542d74adc4fe974264203f05a2ee4e34a6a57d9d1ae13e
logs/content_log.txt   405b90ac20617593ebb479e82e364743e37ced02e2bc8c2e7cbe7d9815ffb32f
```

## What Steam tried

Steam identified the selected title as `198X`, AppID `1086010`, with the
installed executable at:

```text
/opt/nova-steam/home/.local/share/Steam/steamapps/common/198X/198X.exe
```

The content log records the download and commit completing successfully at
19:25:42, including a fully installed state and BuildID `5995563`. The client
then made four observed launch attempts:

| Time | Compatibility selection | Result |
| --- | --- | --- |
| 19:25:51 | Proton 10.0 + SteamLinuxRuntime_sniper | wrapper tracked, child processes exited, game removed from running list |
| 19:26:00 | Proton 10.0 + SteamLinuxRuntime_sniper | same result |
| 19:41:53 | Proton Hotfix + SteamLinuxRuntime_4 | same result |
| 19:43:47 | Proton Hotfix + SteamLinuxRuntime_4 | same result |

For every attempt, `gameprocess_log.txt` shows the Steam launch wrapper exiting
with code `0`, while its tracked child processes exit with code `-1`. The
client stderr reports:

```text
pressure-vessel-unruntime: line 108: .../pressure-vessel-wrap: cannot execute binary file: Exec format error
Game Recording - game stopped [gameid=1086010]
```

The fresh Android screenshot captured after the last attempt is still the
198X detail page with the green `Play` button, not a game frame. The Steam
client remains visibly rendered, so this failure is downstream of the
display/session boundary.

## Architecture evidence

The device-side `file` and `readelf` probes show:

```text
pressure-vessel-wrap: ELF executable, 64-bit LSB x86-64
198X.exe:             MS PE32+ executable (GUI) x86-64
```

The active rootfs is running the native ARM64 Steam client. There is no
evidence in this run of an x86-64 user-mode translation layer. Therefore the
first confirmed launch blocker is the direct execution of the x86-64
`pressure-vessel-wrap`, which explains the kernel-level `Exec format error`.
The Windows game itself was not reached; Proton/Wine behavior and game
rendering are still untested.

The Steam client also printed `vkEnumeratePhysicalDevices failed` and
`BInit - Unable to initialize Vulkan!` during its software-CEF startup. That
is retained as a separate graphics follow-up; it did not prevent the signed-in
Steam UI from displaying through this direct X11 profile and is not enough to
attribute the 198X failure to game Vulkan.

## Teardown evidence

The exact stateful X11 cleanup was invoked with the run's recorded state,
private-namespace helper, and cleanup helper. Namespace removal passed and the
X11 server/socket disappeared, but the helper's final verifier returned
`nova_x11_cleanup=fail` because it still observed a client match during that
verification pass:

```text
pre_cleanup_server_pids=30592,
pre_cleanup_client_pids=18867,30698,30706,30731,31548,31555,
client_matching=1 phase=runtime
namespace_cleanup=pass
server_state=absent client_state=present server_parent_state=absent socket_state=absent
```

The rootfs runtime cleanup was then run separately and passed:

```text
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

A fresh post-cleanup process audit found no `nova-steam`, Steam, Steamwebhelper,
Gamescope, or Termux:X11 runtime process. The run state directory and `.X0-lock`
were absent; the X11 socket directory remained only as an empty directory.
The downloaded 198X content and Steam account/configuration were intentionally
left intact for the next game-launch experiment.

## Decision and next steps

Do not change the AHB/Gamescope display work in response to this result. The
next game-launch phase should first inventory the available x86-64 execution
options inside the ARM64 rootfs (Box64, FEX-Emu, QEMU-user, or an equivalent
device-compatible layer), then rerun 198X with one explicitly recorded
compatibility profile. A native ARM64 Linux game would be a useful control
because it separates the game-session lifecycle from Windows translation.

The product launcher should eventually keep this game-launch boundary visible
in its diagnostics: content download success, compatibility-runtime start,
game process lifetime, and first game frame are distinct gates.
