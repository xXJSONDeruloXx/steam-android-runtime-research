# Retroid Pocket Nova flashing kit

This directory records the device-specific root and boot-image flashing procedure proven on the attached
Retroid Pocket Nova. It contains scripts and instructions only; it does not contain firmware images or the
Magisk APK.

## Tested device

The procedure was completed on this exact Android build:

| Property | Value |
|---|---|
| Model | `Retroid Pocket Nova` |
| Manufacturer | `Moorechip` |
| Android | 13 / API 33 |
| Product/device | `kalama` |
| Build fingerprint | `qti/kalama/kalama:13/TKQ1.231222.001/eng.RPN.20260722.081626:user/release-keys` |
| Kernel | `5.15.123-android13-8-g697b78910a71-dirty` |
| Active slot | `_a` |
| Bootloader | Already unlocked (`ro.boot.flash.locked=0`) |
| `boot_a` / `boot_b` | 100,663,296 bytes each |
| `init_boot_a` / `init_boot_b` | 8,388,608 bytes each |
| Magisk | 30.7 |

The scripts deliberately reject a different model, product, or active slot. If the device has received a
different firmware update, re-check the partition sizes and patch a fresh image from that same build before
changing the checks.

## Important result

This Nova has both `boot` and `init_boot` partitions. An earlier Magisk-patched `boot_a` image was present,
but it did not provide persistent root. Patching the exact stock `init_boot_a.img` with Magisk and flashing
`init_boot_a` produced working `su` access after reboot.

This follows Magisk's documented image-patching flow: use `init_boot.img` when the device provides one,
then flash the patched image to the matching partition. See the [Magisk installation documentation](https://github.com/topjohnwu/Magisk/blob/master/docs/install.md).

## Safety rules

- Back up user data before modifying boot images.
- Do not run `fastboot flashing unlock` on this device. The bootloader was already unlocked; unlocking again
  is unnecessary and can wipe userdata.
- Always dump and retain both A/B `boot` and `init_boot` images before flashing.
- Patch an image taken from this device/build. Never use a patched image from another Nova or another build.
- The flash script writes only the active `init_boot_a` partition, verifies the read-back hash, and does not
  reboot automatically.
- Keep the original `init_boot_a.img` backup. It is the recovery image if the patched image causes a bootloop.

If Android no longer boots, the Retroid root-script runner is unavailable. Use the host-side
`restore-nova-init-boot.sh` helper from fastboot mode with the original `init_boot_a.img` backup.

## Normal workflow

Run these commands from this directory on the host. Set `ANDROID_SERIAL` when more than one Android device
is connected.

### 1. Stage the scripts

```sh
ANDROID_SERIAL=<adb-serial> ./stage-nova-root.sh
```

The helper checks the model, product, unlocked state, and ADB connectivity, then places the root-runner
scripts in `/sdcard/Download/`.

### 2. Back up the partitions

On the Nova, open **Handheld Settings → Advanced → Run script as Root**, select `nova-backup.sh`, and run it.

The script creates:

```text
/sdcard/Download/rp-nova-root-backup/boot_a.img
/sdcard/Download/rp-nova-root-backup/boot_b.img
/sdcard/Download/rp-nova-root-backup/init_boot_a.img
/sdcard/Download/rp-nova-root-backup/init_boot_b.img
/sdcard/Download/rp-nova-root-backup/report.txt
```

It refuses to overwrite an existing backup directory. Preserve the old directory before retrying.

### 3. Patch `init_boot_a` in Magisk

Install/open Magisk on the Nova and choose:

```text
Install → Select and Patch a File
```

Select `/sdcard/Download/rp-nova-root-backup/init_boot_a.img`. Magisk writes a file named like
`magisk_patched-*.img` to `Download`.

Stage that patched image under the fixed name expected by the flash script:

```sh
ANDROID_SERIAL=<adb-serial> ./stage-nova-root.sh \
  --patched-init-boot /path/to/magisk_patched-xxxxx.img
```

Alternatively, rename the single patched file on the device to
`/sdcard/Download/nova-init_boot_a-magisk.img`.

### 4. Flash the patched image

On the Nova, select `nova-flash-init-boot.sh` in **Run script as Root**. The inner script checks:

- the model is `Retroid Pocket Nova` and the product is `kalama`;
- the active slot is `_a`;
- the patched image is exactly 8,388,608 bytes;
- a stock `init_boot_a.img` backup exists and is not identical to the patched image;
- the target read-back SHA-256 equals the patched image SHA-256.

It writes its result to `/sdcard/Download/rp-nova-init-boot-flash-report.txt` and must report
`flash=verified` before rebooting.

### 5. Reboot and verify

```sh
adb -s <adb-serial> reboot
ANDROID_SERIAL=<adb-serial> ./verify-nova-root.sh
```

Expected verification includes `uid=0(root)`, a Magisk version, and a Magisk path such as
`/debug_ramdisk`.

## Recovery

If the Nova cannot boot Android after the flash:

1. Enter its bootloader/fastboot mode.
2. Use the original `init_boot_a.img` from the backup directory, pulled to the host.
3. Run the helper with its explicit confirmation flag:

```sh
./restore-nova-init-boot.sh \
  --stock-init-boot /path/to/init_boot_a.img \
  --yes
```

The helper requires a fastboot device reporting product `kalama`, checks for the `a` slot, flashes only
`init_boot_a`, and leaves reboot to the operator.

## Why the wrapper files exist

Retroid's **Run script as Root** feature does not invoke the selected file as one normal shell script. The
current implementation reads it line by line and sends each line to the privileged `PServerBinder` service.
Therefore, each selected `*.sh` file in this kit is a one-line wrapper that invokes a corresponding
`*-inner.sh` file with `/system/bin/sh`. Select the wrapper, never the inner script.

Files:

| File | Runs where | Purpose |
|---|---|---|
| `stage-nova-root.sh` | Host | Validate the Nova and stage scripts/images over ADB |
| `verify-nova-root.sh` | Host | Verify persistent Magisk `su` access |
| `restore-nova-init-boot.sh` | Host/fastboot | Restore stock `init_boot_a` after a boot failure |
| `device/nova-backup.sh` | Retroid root runner | One-line wrapper for the backup operation |
| `device/nova-backup-inner.sh` | Nova, as root | Dump and hash all four boot images |
| `device/nova-flash-init-boot.sh` | Retroid root runner | One-line wrapper for the flash operation |
| `device/nova-flash-init-boot-inner.sh` | Nova, as root | Safely flash and verify patched `init_boot_a` |
