# Nova CEF child-environment split experiment — 2026-08-10

## Question

The previous hardware display / software Steam GL split kept the direct
Steam client alive, but CEF selected Mesa `softpipe` because
`steamwebhelper` inherited the client’s software overrides. This experiment
tests a narrower boundary: retain the software GL environment for the direct
Steam client and strip only the software overrides when Steam launches the
`steamwebhelper` child.

## Predeclared scope

- Device: Retroid Pocket Nova, adb serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Package: `com.xjsonderulo.steamandroid.novalab`
- Presentation: direct Termux:X11, display `:0`, stretch `1280x800` into
  the `1280x960` Android surface
- `hardware_accel=1`
- `cef_disable_gpu=0`
- `steam_force_software_gl=1`
- `steam_cef_env_split=1`
- Audio bridge: disabled
- Input: no physical or synthetic input
- Game launch: none

The opt-in `libnova-cef-env-split.so` preload filters only these variables for
an executable whose basename is exactly `steamwebhelper`:

```text
MESA_LOADER_DRIVER_OVERRIDE
GALLIUM_DRIVER
LIBGL_ALWAYS_SOFTWARE
LIBGL_ALWAYS_INDIRECT
```

It covers `execve`, `execv`, `execvp`, `execvpe`, `execveat`, `posix_spawn`,
and `posix_spawnp`. The persistent Steam tree is not modified. The preload
must log whether it removed variables from a fresh `steamwebhelper` launch.

## Acceptance

The split succeeds only if all of these are fresh and attributable to this
run:

1. The launcher records `steam_cef_env_split=1` and packages the exact
   library.
2. The direct client still records software `swrast`/`softpipe` markers and
   remains alive without a new status-139 failure.
3. The CEF report changes from the prior
   `ANGLE (Mesa, softpipe, ...)` result to a non-software renderer, preferably
   hardware Mesa/Turnip or an explicit hardware EGL/Vulkan renderer.
4. The viewable X11 Steam window and Android screenshot remain valid.
5. Stop restores the X11 preferences and exact runtime cleanup leaves no
   matching process or run-scoped temporary artifact.

A CEF report that remains `softpipe`, a library-load marker without a changed
   renderer, or a client-only display frame is a negative result. No game,
input, audio, or networking conclusion is allowed from this experiment.

The result must be recorded and pushed before beginning another device run.
This follows [34](../00-start-here/34-nova-runtime-harness-lifecycle.md) and the prior result
in [280](280-nova-hardware-software-gl-cef-gpu-result-2026-08-10.md).
