# Nova bounded-session overlay guard experiment — 2026-08-09

Status: predeclared; device result pending.

## Causal hypothesis

The A-button run in [doc 84](84-nova-oobe-a-button-result-2026-08-09.md)
changed Steam's visible OOBE page correctly, then stopped the AHB peer at
frame 84 while the final Android capture showed the `com.rp.settings` `Use USB
for` chooser. The bounded controller harness dismissed that chooser before
the event and after its delay, but did not guard against reappearance during
the rest of the AHB probe.

The hypothesis is that a continuously running exact-focus guard will prevent
the chooser from stopping the Android Activity and will let the same
marker-correlated A-button run complete its 240-frame target.

## One-variable implementation

`deploy-native-steam-controller-ui-input-smoke-test.sh` now enables the
existing exact-scope `com.rp.settings` dismissal loop for bounded controller
sessions by default. `NOVA_CONTROLLER_UI_OVERLAY_GUARD=0` is an explicit
diagnostic opt-out. Manual sessions keep the same guard, with one shared
implementation and one teardown path.

Everything else remains fixed from doc 83:

- no-trigger libei-enabled Gamescope artifact;
- current test-bench APK;
- fullscreen native Steam/Xwayland at 1280x960;
- Android `KEYCODE_BUTTON_A` 96 -> `BTN_SOUTH` 304;
- AHB frame identity and downstream marker enabled;
- 240-frame target, strict provenance, and explicit cleanup verification.

## Acceptance gates

The experiment passes only if the guard remains active without a residual
process, the A-button panel transition remains strict-pass, the AHB app report
reaches 240 frames and 239 releases, the final screenshot marker correlates to
its producer frame/checksum, and post-stop process/file/property verification
passes. A screen transition without those lifecycle and frame gates remains a
partial result.
