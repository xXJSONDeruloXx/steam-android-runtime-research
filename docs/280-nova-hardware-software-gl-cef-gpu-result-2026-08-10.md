# Nova hardware display / software Steam GL / CEF-GPU result — 2026-08-10

## Decision

The split kept the Steam client alive and produced a visible signed-in Steam
desktop on the hardware-backed Termux:X11 Android surface, but it did not
produce hardware-accelerated CEF rendering. CEF GPU was enabled at the Steam
profile boundary, yet `steamwebhelper` inherited the client’s software GL
environment and selected Mesa `softpipe`. This is a useful display-stability
control, not a hardware-rendering pass.

The result also exposed two lifecycle issues to fix before treating the
one-click path as end-user complete: the direct stop returned cleanup pass but
did not write `nova_launcher_stop=pass`, and the run left three exact Steam
temporary residues that required post-run removal.

## Run identity and provenance

- Run ID: `nova-hardware-software-gl-cef-gpu-20260810T101159Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Package: `com.xjsonderulo.steamandroid.novalab`
- Source commit at launch: `456cba17a512bdaa8c8c386285764a307cd44850`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `773ff7cc263d0fe9873c8a60c10fa7063c88ec6070550c676596df62e8bdd448`
- Evidence directory:
  `android/nova-lab/build/runs/nova-hardware-software-gl-cef-gpu-20260810T101159Z/`
- Gamescope: not used; presentation was direct Termux:X11

The predeclared profile was:

```text
hardware_accel=1
cef_disable_gpu=0
steam_force_software_gl=1
client_gl_mode=software
client_mesa_driver=swrast
client_gallium_driver=softpipe
client_libgl_always_software=1
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
x11_stretch=1
x11_stretch_resolution=1280x800
audio_bridge=0
game launch=none
```

The APK was launched only after a fresh process, state, and X11-socket
baseline. The launcher reported:

```text
nova_launcher_hardware_accel=1
nova_launcher_cef_disable_gpu=0
nova_launcher_steam_force_software_gl=1
nova_launcher_gamepad=pass input_allow=event9
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The fresh readiness marker was:

```text
ready=pass attempt=3 session=20260810T101329Z-19650
```

## Presentation result

Termux:X11 used the Android Adreno EGL path. The fresh server log includes
`/vendor/lib64/egl/libEGL_adreno.so`, the Qualcomm Adreno GLES driver, EGL
1.5, and a `1280x960` Android surface. The same run then negotiated the
stretched X11 buffer:

```text
tx11-request: window changed: 1280 800 builtin
LorieNative: Sent shared buffer width 1280 stride 1280 height 800
LorieNative: Received shared buffer width 1280 stride 1280 height 800
```

The fresh X11 tree passed with root `0x511`, `1280x800`, and a viewable
top-level Steam window:

```text
id=0x160003b depth=1 map_state=viewable x=0 y=0 width=1280 height=800
name="Steam" res_name="steamwebhelper" res_class="steam"
```

The selected X11 window capture was `1280x800`, SHA-256
`07bffe29604286cca4d72439e5add14762645e6069f226e958e1bf6a6007450a`.
The settled Android screenshot was `1280x960`, SHA-256
`dc55a9dd69a770f3f4bcc45759d462d9567e28a2b22b6419c5906e3d51ee4e3c`.
It shows the signed-in Steam desktop and Friends window on the Android
surface. A later screenshot, SHA-256
`b73576732e51f2bfd9268d17367dd443024628e9e9e10c1ce51f1a76ec003215`, had
returned to a mostly black main surface with the Steam bar and Friends window;
the earlier settled capture is therefore the authoritative visible-frame
evidence for this run, not a claim of stable continuous repaint.

The X11 tree SHA-256 is
`1ba8c94a193d50e8443473b71e8961d70708010bc015c964113bf235030bec3c`.

## Steam client and CEF result

The client stayed alive long enough to create the Steam/webhelper windows:

```text
client_gl_mode=software
client_mesa_driver=swrast
client_gallium_driver=softpipe
client_libgl_always_software=1
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_started=pass
```

The direct Steam client also logged the device Vulkan boundary twice:

```text
Vulkan missing requested extension 'VK_KHR_surface'.
Vulkan missing requested extension 'VK_KHR_xlib_surface'.
BInit - Unable to initialize Vulkan!
```

The fresh CEF GPU report at `2026-08-10 10:15:31` is decisive. It reported:

```text
GPU0: Google Inc. (Mesa), ANGLE (Mesa, softpipe, OpenGL 3.3 ...)
GL implementation parts: (gl=egl-angle,angle=opengl)
Display type: ANGLE_OPENGL
GL_RENDERER: ANGLE (Mesa, softpipe, OpenGL 3.3 ...)
gpu_compositing: enabled
vulkan: disabled_off
```

Thus “CEF GPU enabled” means that Chromium’s GPU/compositing path was
allowed, not that it selected the Nova GPU. The software-only variables were
exported by the Steam client wrapper for the direct GLX client and were
inherited by `steamwebhelper`. The current evidence does not support claiming
hardware CEF, hardware Steam GL, Vulkan presentation, or game rendering.

The current-session CEF artifacts are retained in the evidence directory:

```text
webhelper_gpu.txt  9ff35542a9e29f5173012de47c3254b83cf2d2a305144204b0376e0dd9e47a94
cef_log.txt        f3afaeb8d5e7c9c3fea838892a284736cb0dbc18dc0ac9c51a006d7f395f337d
steamwebhelper.log aecf481f2a779d9a159e7eb49a83a701ea48306beef952c2c714ef5640fb7f19
webhelper.txt      f4c70c106ed8246e574fab4a3e01b3116600ea4431787a93ea15b1632adc0297
```

`steamwebhelper.log` also contains a current bad-IPC renderer message, but
the process snapshot showed the Steam client and webhelper family alive during
capture. It is not treated as the primary cause of the softpipe result.

## Teardown and cleanup

The stop command restored the Termux:X11 preferences byte-for-byte:

```text
before 25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895
during 0989cb3336c9bf61b06213a01176a81c206b8b80458358be81527c5df20fef50
after  25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895
```

The restored preference metadata was `10120:10120`, mode `660`. Runtime
cleanup returned:

```text
nova_runtime_cleanup=pass ... attempts=2 ... remaining=
```

The final process audit found no matching Steam, Gamescope, Termux:X11,
libei, uinput, or Nova launcher process. The X11 socket directory had no
children, the exact external capture-helper residual was empty, and the
launcher state directory was absent after the post-capture cleanup.

However, `launcher.log-after-stop` ended after
`nova_launcher_x11_stretch_restore=pass` and
`nova_launcher_client_exit=137`; it did not contain
`nova_launcher_stop=pass`. The cleanup helper’s snapshots show that the
stop/start wrapper processes were still visible while the runtime cleanup was
walking the process tree. This makes the lifecycle result partial even though
the final process audit was clean. The stop completion marker and ancestor PID
handling need a fresh bounded regression run.

The final audit found these exact run-scoped Steam residues:

```text
/data/local/tmp/nova-holo-rootfs/tmp/.com.valvesoftware.Steam.VUXBmJ
/data/local/tmp/nova-holo-rootfs/tmp/.com.valvesoftware.Steam.gciijD
/data/local/tmp/nova-holo-rootfs/tmp/steam_chrome_shmem_uid501_spid20744
```

After confirming no matching process remained, those three paths were removed
explicitly and rechecked absent. Older dated Steam directories were retained;
no broad rootfs cleanup was performed.

## Next steps

1. Fix the stop-path completion contract and test it with a fresh launch/stop
   identity. The runtime cleanup must exclude the complete stop-command
   ancestry without excluding any Nova runtime descendant.
2. Split the environment at the `steamwebhelper` boundary. Keep the direct
   Steam client on software `swrast`/`softpipe`, but remove only the software
   GL overrides from the CEF child and preserve the explicit Freedreno ICD.
   A narrowly scoped wrapper or exec-environment filter should be tested and
   documented as a new experiment; do not modify the persistent Steam tree
   without an exact backup/restore path.
3. Once CEF’s renderer is separated, retry one small installed title. Geometry
   Wars remains a useful negative comparison: its FROG/DXVK path reached the
   device Vulkan boundary but produced no frame because the ICD lacks the
   required surface/swapchain support. This result does not justify reopening
   Gamescope-to-AHardwareBuffer yet.
4. Keep audio, physical controller mapping, touch, and end-user APK lifecycle
   as separate acceptance gates. This run intentionally made no claim about
   them.

This run follows [34](34-nova-runtime-harness-lifecycle.md), the split
predeclaration in [279](279-nova-hardware-software-gl-cef-gpu-experiment-2026-08-10.md),
and the known-good display control in
[219](219-nova-termux-x11-hardware-display-software-gl-isolation-experiment-2026-08-10.md).
