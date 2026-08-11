# Nova rootless PulseAudio TCP contract — 2026-08-10

Status: helper implemented and statically validated; device audio remains
unproven.

## Contract

`android/nova-lab/rootless/nova-rootless-pulseaudio-tcp.sh` ports the narrow
SteamClientTermux audio boundary without coupling it to X11:

- checks for Termux `pactl` and `pulseaudio` before claiming anything;
- uses a project-private runtime directory under the rootless state;
- reuses a healthy `tcp:127.0.0.1:4713` server when present;
- otherwise starts a private local PulseAudio server and loads only
  `module-native-protocol-tcp` on loopback with anonymous local authentication;
- verifies the TCP endpoint again before returning `pass`;
- refuses a symlinked runtime directory and fails closed on missing binaries,
  startup, module, or endpoint errors.

The rootless PRoot supervisor already accepts
`NOVA_ROOTLESS_PULSE_SERVER` and passes it into the guest. The profile now
records the optional Termux package and canonical endpoint. The helper is not
automatically required for the display path: Steam can still be tested with
X11 while audio remains a separately classified capability.

## Current boundary

The prior device inventory showed that the installed Termux base did not yet
contain `pulseaudio` or `pactl`, so no device audio pass is claimed. Installing
the package and running this helper is the next audio experiment after the
Nova USB/ADB transport is restored. The rooted AudioTrack bridge and its
signed-in Steam session remain untouched.

Static validation remains:

```text
rootless_profile_static=pass
```
