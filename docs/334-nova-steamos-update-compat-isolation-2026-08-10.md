# Nova SteamOS updater compatibility isolation

Date: 2026-08-10
Status: isolated; host-update shim disabled by default

## Question

The Steam Gamepad UI briefly showed a SteamOS update/calculating-time page and
then a blank surface. The Nova Holo rootfs has no real SteamOS host updater, so
the launcher had been installing this research helper at the exact expected
path:

```text
/usr/bin/steamos-polkit-helpers/steamos-update
```

The helper only recorded its arguments and returned exit status 0. It did not
download or apply an update. That unconditional success was a plausible cause
of Steam taking the restart branch even though no host reboot could occur.

## Important distinction

This helper is separate from Steam client bootstrap/update behavior:

- the initial ARM64 seed bootstrap is allowed when the SteamUI tree is absent;
- after SteamUI exists, the direct profile uses
  `-nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui`;
- the OOBE path separately invokes `steamos-update --enable-duplicate-detection`
  as a SteamOS host-integration check.

The fix must not suppress the real client bootstrap that populates a fresh
seed, and it must not pretend that a host update succeeded.

## A/B evidence

Both runs used the versioned v4 runtime and direct Termux:X11 profile. The
current source no longer contains the earlier OOBE completion, stage-2, or
no-restart rewrites; this isolates the updater helper rather than hiding the
client's own route.

### Shim enabled

The earlier v4 run installed the helper and produced:

```text
nova_steamos_update_compat=pass
nova_steamos_update_args=--supports-duplicate-detection
nova_steamos_update_compat=pass
nova_steamos_update_args=--enable-duplicate-detection
SteamUI: WARNING: SetOOBEComplete
SteamUI: WARNING: Restarting PC
```

The Android surface then remained blank/dark with only the `MENU`/`BACK`
footer. The client log showed the host helper command immediately before the
OOBE completion/restart transition. This was not evidence that SteamOS had
actually updated.

### Shim disabled

The launcher was rebuilt and installed with the same runtime and all display,
network, input, and audio variables held constant. It logged:

```text
nova_launcher_steamos_update_compat=disabled
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The Android capture showed the real Steam language picker, then the English
OOBE screen after controlled input. The final capture was:

```text
android/nova-lab/build/nova-v4-no-shim-after-english.png
sha256=d6461f51d683aa5f57e6860e9341e73f39e0a659ed1b8c31b04c285ac0b42cd0
```

During this no-shim slice, `webhelper_js.txt` had not emitted the updater
command or `Restarting PC`; it remained in the language/OOBE route. That is
the cleanest available isolation of the blank restart boundary.

## Decision

`nova-steamos-update-compat.sh` remains bundled as a diagnostic artifact for
historical comparisons, but the product launcher removes the host-updater path
unless the explicit environment variable below is set:

```text
NOVA_ANDROID_LAUNCHER_STEAMOS_UPDATE_COMPAT=1
```

The normal profile therefore does not report fake SteamOS update success and
does not conceal Steam's restart handoff. The correct future repair is a
narrow lifecycle adapter based on fresh Steam logs, not another OOBE view
patch and not an unconditional success result.

The no-shim screen still has incomplete glyph coverage for several languages;
that is a separate font/package issue. The clean run also stopped with the
exact launcher cleanup helper passing and no matching Nova/Steam/Xwayland,
uinput, or libei processes and no exact X11 socket remaining.

## Follow-up

Continue the clean v4 OOBE flow far enough to classify the real host-update
call when completion is attempted. If Steam requires a host capability, expose
only the capability that is actually supported by the Android runtime; do not
return success for an operation that cannot be performed. Keep client seed
bootstrap and Proton/runtime setup as separate experiments.
