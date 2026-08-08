# Nova Bionic Mesa glamor sidecar experiment

Status: reproducible build experiment; not yet a replacement for the current
Holo/glibc Xwayland process.

## Why this artifact exists

The current Xwayland checkpoint reaches Gamescope and Android AHardwareBuffer
output, but Xwayland reports:

```text
Xwayland glamor: GBM Wayland interfaces not available
Failed to initialize glamor, falling back to sw
```

The existing Nova Mesa build only contains the glibc KGSL Turnip Vulkan driver;
its build intentionally disables EGL, GBM, OpenGL, and Gallium. A separate Bionic
driver DSO cannot simply be copied into that glibc process, so this branch builds
the complete matching Android/Bionic Mesa sidecar instead of publishing an
incompatible loose `*.so`.

## Build

The build uses the official Mesa 25.2.7 tag, Android NDK API 34, and the Meson
Android cross-build path:

```sh
ANDROID_NDK_ROOT=/path/to/android-ndk \
  android/nova-lab/build-mesa-bionic-glamor.sh
```

The script enables:

- EGL, GBM, GLES 2/3, and the Mesa loader;
- Freedreno Gallium DRI (`msm_dri.so` and `kgsl_dri.so`);
- Zink, so the Bionic GL path can also be tested over Turnip;
- a matching Bionic `libvulkan_freedreno.so` built for KGSL.

The output is:

```text
android/nova-lab/build/mesa-bionic-glamor/nova-mesa-bionic-glamor-arm64.tar.gz
```

The archive installs below `/opt/nova-mesa-bionic` and includes the Bionic
`libdrm` fallback used by the DRI/GBM build when the target does not already
provide one. It should be unpacked into a disposable private runtime only.

The tested local build produced an ARM64 ELF archive with SHA-256:

```text
a8c41f40f11c9e4695238fa92e022a6cade30ba53d2b15e400c008876a671e13
```

Its DSOs use Android/Bionic-style dependencies such as `libc.so`, not glibc's
`libc.so.6`. Mesa's Gallium DRI target remains DRM-facing in this Mesa release;
the `kgsl` selection applies to the matching Turnip Vulkan library. A runtime
test therefore still needs both the Android/Bionic process boundary and access
to the Nova's `msm_drm` render node.

## What this does and does not prove

The artifact proves that the upstream Mesa components can be built as a coherent
Android/Bionic ARM64 stack for this GPU family. It does not prove that the
current Holo/glibc Xwayland can load them: the dynamic-loader ABI boundary is
intentional. To turn this into a glamor test, the next component must be a
Bionic-linked Xwayland (or another Bionic X11 client/server arrangement) that
uses this sidecar, with its own matching Wayland/X11/pixman dependencies.

The first runtime checks should be `readelf -d`/loader checks, then a bounded
Xwayland or EGL/GBM probe. Only after that should it be compared with the
existing software-glamor path. No Android vendor partitions or global Mesa
libraries should be replaced by this artifact.
