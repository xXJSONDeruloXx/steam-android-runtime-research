# Nova rootless APK/Termux bridge implementation — 2026-08-10

Status: built and statically verified; device Java RUN_COMMAND replay pending.

## APK changes

The product APK now includes a separate **Start rootless X11 (experimental)**
button and `RootlessLauncherService`. It does not share the rooted
`LauncherService` process, cleanup, or authentication data. The new service:

- checks `com.termux`, `com.termux.x11`, and the user-granted
  `com.termux.permission.RUN_COMMAND` permission;
- sends `nova-rootless-termux-x11.sh` to Termux through the documented
  `RUN_COMMAND` stdin path instead of asking Termux to read Nova-private files;
- starts/stops the separate display `:77` and keeps its own foreground
  notification; and
- declares package visibility for both Termux packages and reports readiness
  only after Nova itself can connect to `127.0.0.1:6077`.

The rootless profile, supervisor, transport probe, Termux helper, and
`termux.properties` are packaged as assets. The bridge is transport-only at
this checkpoint; it does not claim that native Steam has launched.

## Host validation

```text
rootless_profile_static=pass
/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
SHA-256: 4945124fe30246447640ad6405bb43b2de76da566d7ce7f8459b36a43400cdf5
```

The APK asset listing contains all five rootless files. The build completed
with only the existing Java 8/deprecated-API warnings.

The command shape follows Termux’s official
[RUN_COMMAND Intent contract](https://github.com/termux/termux-app/wiki/RUN_COMMAND-Intent):
the script is passed to `/data/data/com.termux/files/usr/bin/bash -s`, with the
action and display as argv, and the Termux-side `allow-external-apps=true`
property remains a separate user-controlled gate.

## Next device gate

Install this APK in place without clearing Nova data, grant the dangerous
RUN_COMMAND permission for this bounded test, press the rootless transport
button (or use `run_rootless_x11=true`), and verify a fresh `:77` process and
the Java service’s `Rootless X11 ready` status. Stop it through the APK and
verify the exact `:77` process exits while the rooted `:0` Steam session stays
alive.
