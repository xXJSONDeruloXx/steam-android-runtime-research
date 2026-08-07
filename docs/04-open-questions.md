# Open Questions and Next Experiments

## Phase 1: test the attached kit

Use one known ARM64 Snapdragon/Adreno device and capture evidence rather than relying on the kit’s README claims.

1. Start Termux:X11 and PulseAudio.
2. Enter the same ARM64 Linux container used for Steam.
3. Run `steam-x11-doctor` and save:
   - `xdpyinfo`.
   - `glxinfo -B`.
   - `vulkaninfo --summary`.
   - PulseAudio status.
4. Run `steam-x11-arm64` and capture:
   - Steam stdout/stderr.
   - `steamwebhelper` process environment.
   - `STEAM_EXEC_SHIM_LOG` output.
   - A screenshot of the UI.
5. Try the native client with `-gamepadui` and `-bigpicture`.
6. Record whether login, library artwork, navigation, and controller input work.

The first result should be classified separately for:

- Steam process startup.
- `steamwebhelper` hardware rendering.
- Login UI.
- Gamepad UI.
- Controller input.

## Phase 2: put Gamescope around the working client

Before using the Android AHardwareBuffer backend, test the native ARM64 Steam client inside the Termux:X11 environment with patched gamescope.

Suggested order:

1. `xmessage` or another trivial X11 client.
2. A simple Vulkan client.
3. Normal Steam desktop mode.
4. `-gamepadui` or `-bigpicture`.

This will show whether the failure is in Steam, Gamescope WSI, Xwayland, or the Android display path.

## Phase 3: return to the native Android presentation path

Once Steam renders in the Linux/gamescope session:

- Replace Termux:X11 output with the persistent AHardwareBuffer pool.
- Gate buffer reuse on SurfaceControl release fences.
- Forward Android controller and touch events into the gamescope/Wayland session.
- Keep gamescope alive independently of short-lived test children.
- Test Steam suspend/resume and clean shutdown.

## Acceptance criteria for the actual product direction

The target should not be considered proven until all of these work on one device:

1. Android app starts and stops the Linux session.
2. Native ARM64 Steam launches inside the managed Linux userspace.
3. `steamwebhelper` uses the hardware Vulkan path rather than llvmpipe/lavapipe.
4. Steam login UI appears.
5. Gamepad UI/Big Picture appears without a desktop mouse/keyboard workflow.
6. Android controller input reaches Steam navigation and a launched game.
7. Frames reach the Android display through the intended presentation path.
8. Suspend/resume and process cleanup work without stale sessions.

## Open technical questions

- Does the ARM64 Steam client reach login under the attached kit’s normal X11 path?
- Does `-gamepadui` work, or does the client require additional Steam Deck environment/configuration?
- Does native ARM64 Steam still depend on SysV semaphore behavior missing from some Android kernels?
- Can the kit’s CEF environment shim be used unchanged inside the Holo rootfs?
- Can Gamescope’s Android backend present Steam’s actual frames continuously, not just `vkcube` frames?
- What input protocol is least invasive: Android HID injection, Wayland input, SDL, or a custom socket?
- Is root acceptable for the first release, or must the project remain in the FEX/proot research lane?
- What Steam ARM64 package/update channel is legally and technically appropriate for distribution?

## Current recommendation

Do not build a large custom Android UI yet. First obtain a screenshot and logs of native ARM64 Steam’s actual Gamepad UI using the attached kit. If that works, the remaining work is primarily compositor integration and app packaging. If it fails before UI startup, the logs will identify whether the next investment belongs in Steam runtime shims, the ARM64 package, or the container environment.
