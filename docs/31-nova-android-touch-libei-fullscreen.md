# Nova Android touch → Gamescope libei and fullscreen presentation checkpoint

Date: 2026-08-08
Device: Retroid Pocket Nova, Snapdragon `kalama`, Adreno 740, rooted Android 15 lab image
Status: touch transport and fullscreen native Steam presentation pass; hardware CEF remains open

## Why this checkpoint exists

The controller work already proved an Android key event can reach Steam through a rooted
uinput device. This experiment adds the other natural Android input path: touch events
from the app-owned presentation surface into the Gamescope session. It also tests whether
the same app can occupy the whole display while keeping the AHardwareBuffer compositor
path alive.

The implementation is intentionally split into independently observable boundaries:

```text
Android MotionEvent
  -> MainActivity.dispatchTouchEvent
  -> abstract LocalServerSocket in the app
  -> ARM64 libei helper
  -> Gamescope EIS virtual touch device
  -> Xwayland / native ARM64 Steam
  -> Android SurfaceControl AHardwareBuffer output
```

## Repository changes

- `android/nova-lab/src/main/java/com/xjsonderulo/steamandroid/novalab/MainActivity.java`
  adds an optional immersive fullscreen presentation mode and a normalized touch socket.
- `android/nova-lab/device/nova-libei-input-bridge.c` and
  `android/nova-lab/build-libei-input-bridge.sh` add the rooted ARM64 libei sender.
- `android/nova-lab/patches/gamescope-headless-libei-touch.patch` enables Gamescope's
  libei touch capability and maps touch events to `wlserver_touchdown/motion/up`.
- `android/nova-lab/device/gamescope-headless-steam-xwayland-control.sh` starts the
  helper after both the Gamescope EIS socket and Android abstract socket are available.
- `android/nova-lab/deploy-native-steam-touch-input-smoke-test.sh` is the reproducible
  live-session harness. Its default result is the transport checkpoint. Set
  `NOVA_TOUCH_REQUIRE_STEAM_SURFACE=1` to require a visible Steam frame as well.

The Android socket is abstract. `LocalServerSocket(String)` does not create a normal
filesystem socket, so the rootfs configuration uses:

```text
@/data/user/0/com.xjsonderulo.steamandroid.novalab/files/nova-touch.sock
```

## Build and run

The host-side build checks used for this checkpoint were:

```sh
android/nova-lab/build.sh
android/nova-lab/build-libei-input-bridge.sh
GAMESCOPE_SOURCE=/Users/kurt/Developer/gamescope-valve \
  NOVA_GAMESCOPE_INPUT_EMULATION=enabled \
  android/nova-lab/build-gamescope-headless.sh
```

The live transport smoke was run with a bounded 30-frame output and a 120-second
readiness window:

```sh
NOVA_AHB_FRAME_COUNT=30 \
NOVA_TOUCH_WAIT_TIMEOUT=120 \
NOVA_TOUCH_SETTLE_DELAY=30 \
NOVA_STEAM_CLIENT_TIMEOUT=45 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=60 \
  android/nova-lab/deploy-native-steam-touch-input-smoke-test.sh
```

The run passed the native Steam/AHB smoke and emitted these live markers:

```text
android_touch_socket=listening
android_touch_socket=connected
android_touch_forwarded=pass
libei_connect=pass
libei_touch_seat=pass
libei_touch_device=pass
libei_touch_device_resumed=pass
android_touch_socket_connected=pass
libei_touch_down_sent=pass
libei_touch_up_sent=pass
libei_touch_probe=pass
EIS touch event type=800 id=1
EIS touch event type=801 id=1
headless_gamescope_ahb=pass
native_steam_smoke=pass
native_steam_touch_input_transport=pass
```

The injected tap was `(x=1100, y=100)` on the 1280x960 Nova display. The helper
received normalized coordinates `x=0.85938 y=0.10417`. Gamescope no longer emits its
previous `No touch support yet` rejection.

## Fullscreen output result

The independent synthetic fullscreen test passed:

```sh
NOVA_FULLSCREEN_PRESENTATION=1 \
NOVA_AHB_FRAME_COUNT=30 \
NOVA_GAMESCOPE_AHB_SKIP_WAYLAND=0 \
  android/nova-lab/deploy-gamescope-headless-ahb-test.sh
```

Its report included `ahb_double_buffer_destination=1280x912`, 30 Wayland SHM frames,
and a visible edge-to-edge synthetic pattern in the pulled screenshot. This proves that
the fullscreen Android `SurfaceView`/SurfaceControl stack and display-size destination
geometry can present a live Gamescope buffer.

The final native Steam acceptance uses a longer compositor run and a 30-second settle
after the SteamUI readiness markers. The visual assertion samples the white Steam
language-panel header rather than generic bright pixels from the Android report UI:

```sh
NOVA_FULLSCREEN_PRESENTATION=1 \
NOVA_AHB_FRAME_COUNT=120 \
NOVA_TOUCH_WAIT_TIMEOUT=120 \
NOVA_TOUCH_SETTLE_DELAY=30 \
NOVA_TOUCH_AFTER_DELAY=8 \
NOVA_STEAM_CLIENT_TIMEOUT=60 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=75 \
NOVA_TOUCH_REQUIRE_STEAM_SURFACE=1 \
  android/nova-lab/deploy-native-steam-touch-input-smoke-test.sh
```

That run passed with stable fullscreen Steam screenshots:

```text
touch_before_sha256=be028464136e03d87c58e8c46169a6351103ac22a54dd35f380008365a162796
touch_after_sha256=be028464136e03d87c58e8c46169a6351103ac22a54dd35f380008365a162796
touch_screen_changed=fail
touch_steam_panel_yavg=230
touch_steam_panel_ymax=235
touch_steam_surface=pass
native_steam_touch_input_smoke=pass
```

Earlier 30-frame or shorter-settle captures were black because the native Steam surface
had not latched its first visible CEF frame yet. The longer run removes that timing race;
the fullscreen screenshot visibly contains the Steam language selector and localized
welcome text edge to edge. The normal bench presentation remains a useful control.

The live root report also records Xwayland glamor falling back to software because GBM
Wayland interfaces are unavailable. Hardware CEF rendering remains a separate unresolved
graphics gate.

## Remaining graphics boundary

The live root report still records Xwayland glamor falling back to software because GBM
Wayland interfaces are unavailable. Hardware CEF rendering remains a separate unresolved
graphics gate, and login, broader controls, game launch, audio, and lifecycle cleanup
remain open.
