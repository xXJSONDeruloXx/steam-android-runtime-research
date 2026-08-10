# Nova explicit Freedreno Vulkan probe result — 2026-08-10

## Result summary

The explicit Freedreno Vulkan path is proven independently of Steam, Proton,
and the games. `vulkaninfo --summary` returned status `0`, enumerated a
Turnip Adreno 740, and the Vulkan loader explicitly reported using
`/opt/nova-kgsl-driver/libvulkan_freedreno.so` from the requested ICD manifest.

This closes the question left open by the Geometry Wars run: the ICD is
functional and hardware-backed. The remaining game failure is therefore not
evidence that the Freedreno ICD is absent or unable to enumerate a device.

## Run identity and provenance

- Run ID: `nova-vulkan-freedreno-20260810T075707Z`
- Run directory:
  `android/nova-lab/build/runs/nova-vulkan-freedreno-20260810T075707Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Fresh session D-Bus bus:
  `/tmp/nova-steam-runtime/dbus-session-25837/bus`
- Probe: `/usr/bin/vulkaninfo --summary`
- ICD:
  `VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Driver library: `/opt/nova-kgsl-driver/libvulkan_freedreno.so`
- Presentation namespace: hardware-backed Termux:X11, 1280×960, `DISPLAY=:0`

The run was predeclared and pushed in
[`docs/30-runtime-and-games/244-nova-freedreno-vulkaninfo-probe-run-2026-08-10.md`](244-nova-freedreno-vulkaninfo-probe-run-2026-08-10.md),
commit `3c6d928`.

## Vulkan result

The fresh probe returned:

```text
Vulkan Instance Version: 1.3.296
GPU0:
    apiVersion         = 1.4.318
    deviceName         = Turnip Adreno (TM) 740
    driverID           = DRIVER_ID_MESA_TURNIP
    driverName         = turnip Mesa driver
    driverInfo         = Mesa 25.2.7
```

With `VK_LOADER_DEBUG=all`, the loader also recorded:

```text
Found ICD manifest file /opt/nova-kgsl-driver/freedreno-kgsl.icd.json
Searching for ICD drivers named /opt/nova-kgsl-driver/libvulkan_freedreno.so
Using "Turnip Adreno (TM) 740" with driver: "/opt/nova-kgsl-driver/libvulkan_freedreno.so"
```

This is a direct physical-device enumeration result, not an inference from a
configured environment variable. It proves the hardware Vulkan driver path
works in the same private namespace used by the one-click Steam session.

It does not yet prove that Proton's D3D9/wined3d path selects Vulkan instead of
OpenGL, nor that Gamescope's Steam presentation can consume the device. Those
remain separate gates.

## Cleanup

- `nova_x11_cleanup=pass`
- `nova_runtime_cleanup=pass`
- no matching Vulkan probe, Nova, Gamescope, Steam, webhelper, uinput, or
  libei process after the settled check
- exact stale Steam singleton and CEF shared-memory sockets were removed after
  confirming no associated process remained
- final rootfs sockets contain only the reusable baseline udev sockets:
  `/run/udev/control` and `/run/udev/io.systemd.Udev`

## Artifacts

- launcher log SHA-256 `4d012b6f44398a662010125627f41a3d5d27d71fc162a6ded5fae414a57fe4cd`
- exact probe command SHA-256 `7e0a5c0ff23ac259060328b6a62c67a23fb59f43113b44a58640b1c14c10e2b0`
- probe stdout SHA-256 `535b8d47c7498d5d23886a0bd19453cc1637f16ff65c3ee14cc11794a9d2238f`
- loader-debug stderr SHA-256 `74655256951b231887dd6e6b0d1a193cbc1b06127d3bf2a08fefde4ce06813ba`
- probe status SHA-256 `863039b4d8cf2f49cb91a13c05f670ac7bad991830ec14ba007a79bf643a294d`
- process poll SHA-256 `9e5adfee9e4638aa09547269b68a0a762bfb9756a35a390c291d2e9b799eb3db`
- preprobe screenshot SHA-256 `20e257c47ccd6bc8c5d0113bc8c26dff92e5dd949174b90592c8508a45202d5f`
- final process check SHA-256 `92fa7c9de184925764730e001154d0bc181cfb5e50e3bb36b05c842bc68bae0b`
- final mounts check SHA-256 `e6b9b7914d9a9f97b0790808b19e4ed5e32e9feb92608a0cfedd5bef355b603a`
- final rootfs socket inventory SHA-256 `e85c24c031da253a5b3738ff85fd567af1680c23c4a30c705aaaf35b77eb6bb3`
