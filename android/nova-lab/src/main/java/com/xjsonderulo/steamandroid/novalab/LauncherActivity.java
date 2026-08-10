package com.xjsonderulo.steamandroid.novalab;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

/** One-click product launcher; MainActivity remains the diagnostic lab. */
public final class LauncherActivity extends Activity {
    private static final String TERMUX_X11_PACKAGE = "com.termux.x11";
    private static final String DEFAULT_ROOTFS = "/data/local/tmp/nova-holo-rootfs";
    private static final String LAUNCHER_DIR = "launcher";
    private static final String EXTRA_RUN_STEAM_SESSION = "run_steam_session";
    private static final String EXTRA_RUN_AUDIO_BRIDGE_STEAM =
            "run_audio_bridge_steam";
    private static final String EXTRA_HARDWARE_ACCEL =
            LauncherService.EXTRA_HARDWARE_ACCEL;
    private static final String EXTRA_CEF_DISABLE_GPU =
            LauncherService.EXTRA_CEF_DISABLE_GPU;
    private static final String EXTRA_STEAM_UI_MODE =
            LauncherService.EXTRA_STEAM_UI_MODE;
    private static final String EXTRA_STEAM_DISABLE_PRELOAD =
            LauncherService.EXTRA_STEAM_DISABLE_PRELOAD;
    private static final String EXTRA_STEAM_DISABLE_SYSTEM_DBUS =
            LauncherService.EXTRA_STEAM_DISABLE_SYSTEM_DBUS;
    private static final String EXTRA_STEAM_HOLO_MESA_FIRST =
            LauncherService.EXTRA_STEAM_HOLO_MESA_FIRST;
    private static final int REQUEST_POST_NOTIFICATIONS = 42;
    private static final String[] REQUIRED_ASSETS = {
            "nova-one-click-root-launcher.sh",
            "nova-x11-private-namespace.sh",
            "nova-termux-x11-cleanup.sh",
            "nova-termux-x11-steam-client.sh",
            "nova-uinput-gamepad-relay-launcher.sh",
            "nova-runtime-cleanup.sh",
            "nova-steam-network-api-compat.sh",
            "nova-steamos-update-compat.sh"
    };
    private static final String[] OPTIONAL_ASSETS = {
            "nova-mount-private",
            "nova-uinput-gamepad-relay",
            "libsysv-sem-shim.so",
            "libffmpeg-avutil-compat.so",
            "libsdl3-compat.so",
            "libposix-sync-trace.so",
            "libnova-alsa-audiotrack-bridge.so"
    };

    private final Handler handler = new Handler(Looper.getMainLooper());
    private TextView statusView;
    private boolean startPendingNotificationPermission;
    private final Runnable statusRefresh = new Runnable() {
        @Override
        public void run() {
            if (statusView != null) {
                statusView.setText(LauncherService.getStatus());
            }
            handler.postDelayed(this, 500);
        }
    };

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setPadding(dp(28), dp(24), dp(28), dp(24));
        page.setBackgroundColor(Color.rgb(12, 16, 20));

        TextView title = new TextView(this);
        title.setText("Nova Steam");
        title.setTextColor(Color.WHITE);
        title.setTextSize(30);
        page.addView(title, new LinearLayout.LayoutParams(-1, -2));

        TextView subtitle = new TextView(this);
        subtitle.setText("Rooted ARM64 Steam session · 1280×960 target");
        subtitle.setTextColor(Color.LTGRAY);
        subtitle.setTextSize(14);
        page.addView(subtitle, new LinearLayout.LayoutParams(-1, -2));

        TextView dependencyView = statusText(installationSummary());
        page.addView(dependencyView, new LinearLayout.LayoutParams(-1, -2));

        statusView = statusText(LauncherService.getStatus());
        statusView.setPadding(0, dp(22), 0, dp(22));
        page.addView(statusView, new LinearLayout.LayoutParams(-1, -2));

        Button start = new Button(this);
        start.setText("Start Steam");
        start.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startSteamSession();
            }
        });
        page.addView(start, new LinearLayout.LayoutParams(-1, -2));

        Button stop = new Button(this);
        stop.setText("Stop Nova session");
        stop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                stopSteamSession();
            }
        });
        page.addView(stop, new LinearLayout.LayoutParams(-1, -2));

        Button lab = new Button(this);
        lab.setText("Open diagnostics lab");
        lab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startActivity(new Intent(LauncherActivity.this, MainActivity.class));
            }
        });
        page.addView(lab, new LinearLayout.LayoutParams(-1, -2));

        TextView note = new TextView(this);
        note.setText("One-time setup: install Termux:X11 and prepare the Holo rootfs.\n"
                + "Steam data stays on the device; this APK owns launch and cleanup.");
        note.setTextColor(Color.GRAY);
        note.setTextSize(12);
        note.setPadding(0, dp(24), 0, 0);
        page.addView(note, new LinearLayout.LayoutParams(-1, -2));

        setContentView(page);
        enterImmersiveMode();
        handler.post(statusRefresh);
        if (getIntent().getBooleanExtra("run_audio_bridge_stop", false)) {
            stopAudioBridgeOnly();
        } else if (getIntent().getBooleanExtra("run_audio_bridge_only", false)) {
            startAudioBridgeOnly();
        } else if (getIntent().getBooleanExtra(EXTRA_RUN_STEAM_SESSION, false)
                || getIntent().getBooleanExtra(EXTRA_RUN_AUDIO_BRIDGE_STEAM, false)) {
            startSteamSession();
        }
    }

    @Override
    protected void onDestroy() {
        handler.removeCallbacks(statusRefresh);
        super.onDestroy();
    }

    private void startSteamSession() {
        if (Build.VERSION.SDK_INT >= 33
                && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
            startPendingNotificationPermission = true;
            LauncherService.setStatus("Allow notifications once to keep Stop available");
            requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},
                    REQUEST_POST_NOTIFICATIONS);
            return;
        }
        startSteamSessionAfterPermission();
    }

    private void startSteamSessionAfterPermission() {
        if (!isPackageInstalled(TERMUX_X11_PACKAGE)) {
            LauncherService.setStatus("Cannot start: Termux:X11 is not installed");
            return;
        }
        final File assetDirectory;
        try {
            assetDirectory = prepareLauncherAssets();
        } catch (IOException error) {
            LauncherService.setStatus("Cannot prepare launcher: " + error.getMessage());
            return;
        }

        ApplicationInfo x11Info;
        try {
            x11Info = getPackageManager().getApplicationInfo(TERMUX_X11_PACKAGE, 0);
        } catch (Exception error) {
            LauncherService.setStatus("Cannot locate Termux:X11 APK");
            return;
        }

        Intent service = new Intent(this, LauncherService.class);
        service.setAction(LauncherService.ACTION_START);
        service.putExtra(LauncherService.EXTRA_ROOTFS, DEFAULT_ROOTFS);
        service.putExtra(LauncherService.EXTRA_ASSET_DIRECTORY,
                assetDirectory.getAbsolutePath());
        service.putExtra(LauncherService.EXTRA_TERMUX_APK, x11Info.sourceDir);
        if (getIntent().getBooleanExtra(EXTRA_RUN_AUDIO_BRIDGE_STEAM, false)) {
            service.putExtra(LauncherService.EXTRA_AUDIO_BRIDGE, true);
            service.putExtra(LauncherService.EXTRA_AUDIO_BRIDGE_PORT,
                    AudioPcmBridge.DEFAULT_PORT);
        }
        boolean hardwareAccel = getIntent().getBooleanExtra(EXTRA_HARDWARE_ACCEL, false);
        boolean cefDisableGpu = getIntent().hasExtra(EXTRA_CEF_DISABLE_GPU)
                ? getIntent().getBooleanExtra(EXTRA_CEF_DISABLE_GPU, false) : !hardwareAccel;
        String steamUiMode = "minimal".equals(getIntent().getStringExtra(EXTRA_STEAM_UI_MODE))
                ? "minimal" : "gamepadui";
        boolean steamDisablePreload = getIntent().getBooleanExtra(EXTRA_STEAM_DISABLE_PRELOAD, false);
        boolean steamDisableSystemDbus = getIntent().getBooleanExtra(
                EXTRA_STEAM_DISABLE_SYSTEM_DBUS, false);
        boolean steamHoloMesaFirst = getIntent().getBooleanExtra(
                EXTRA_STEAM_HOLO_MESA_FIRST, false);
        service.putExtra(LauncherService.EXTRA_HARDWARE_ACCEL, hardwareAccel);
        service.putExtra(LauncherService.EXTRA_CEF_DISABLE_GPU, cefDisableGpu);
        service.putExtra(LauncherService.EXTRA_STEAM_UI_MODE, steamUiMode);
        service.putExtra(LauncherService.EXTRA_STEAM_DISABLE_PRELOAD, steamDisablePreload);
        service.putExtra(LauncherService.EXTRA_STEAM_DISABLE_SYSTEM_DBUS, steamDisableSystemDbus);
        service.putExtra(LauncherService.EXTRA_STEAM_HOLO_MESA_FIRST, steamHoloMesaFirst);
        if (Build.VERSION.SDK_INT >= 26) {
            startForegroundService(service);
        } else {
            startService(service);
        }

        // The root-side launcher also opens this Activity after the X socket is
        // ready. This fallback covers devices that restrict am from su.
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                openTermuxX11();
            }
        }, 1400);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions,
            int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != REQUEST_POST_NOTIFICATIONS) {
            return;
        }
        boolean startAfterPermission = startPendingNotificationPermission;
        startPendingNotificationPermission = false;
        if (grantResults.length > 0
                && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            if (startAfterPermission) {
                startSteamSessionAfterPermission();
            }
        } else {
            LauncherService.setStatus(
                    "Notifications are required for reliable session Stop; Steam not started");
        }
    }

    private void stopSteamSession() {
        Intent service = new Intent(this, LauncherService.class);
        service.setAction(LauncherService.ACTION_STOP);
        startService(service);
    }

    private void startAudioBridgeOnly() {
        Intent service = new Intent(this, LauncherService.class);
        service.setAction(LauncherService.ACTION_AUDIO_ONLY);
        service.putExtra(LauncherService.EXTRA_AUDIO_BRIDGE_PORT,
                AudioPcmBridge.DEFAULT_PORT);
        if (Build.VERSION.SDK_INT >= 26) {
            startForegroundService(service);
        } else {
            startService(service);
        }
    }

    private void stopAudioBridgeOnly() {
        Intent service = new Intent(this, LauncherService.class);
        service.setAction(LauncherService.ACTION_STOP);
        startService(service);
    }

    private void openTermuxX11() {
        Intent intent = new Intent();
        intent.setComponent(new ComponentName(
                TERMUX_X11_PACKAGE, TERMUX_X11_PACKAGE + ".MainActivity"));
        try {
            startActivity(intent);
        } catch (ActivityNotFoundException error) {
            LauncherService.setStatus("Termux:X11 Activity is unavailable");
        }
    }

    private File prepareLauncherAssets() throws IOException {
        File directory = new File(getFilesDir(), LAUNCHER_DIR);
        if (!directory.exists() && !directory.mkdirs()) {
            throw new IOException("cannot create app launcher directory");
        }
        for (String name : REQUIRED_ASSETS) {
            copyAsset(name, new File(directory, name), true);
        }
        for (String name : OPTIONAL_ASSETS) {
            copyAsset(name, new File(directory, name), false);
        }
        return directory;
    }

    private void copyAsset(String name, File target, boolean required) throws IOException {
        try (InputStream input = getAssets().open(name);
             FileOutputStream output = new FileOutputStream(target)) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = input.read(buffer)) >= 0) {
                if (read > 0) {
                    output.write(buffer, 0, read);
                }
            }
        } catch (IOException error) {
            if (required) {
                throw error;
            }
            if (target.exists() && !target.delete()) {
                throw error;
            }
        }
        if (target.exists()) {
            target.setExecutable(true, false);
        }
    }

    private String installationSummary() {
        String notification = "Notifications: "
                + (notificationPermissionGranted() ? "enabled" : "required before start");
        return "Termux:X11: "
                + (isPackageInstalled(TERMUX_X11_PACKAGE) ? "installed" : "missing")
                + "\nRootfs: " + DEFAULT_ROOTFS
                + "\n" + notification;
    }

    private boolean notificationPermissionGranted() {
        return Build.VERSION.SDK_INT < 33
                || checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED;
    }

    private boolean isPackageInstalled(String packageName) {
        try {
            getPackageManager().getPackageInfo(packageName, 0);
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private TextView statusText(String text) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextColor(Color.LTGRAY);
        view.setTextSize(14);
        return view;
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private void enterImmersiveMode() {
        Window window = getWindow();
        if (Build.VERSION.SDK_INT >= 30) {
            WindowInsetsController controller = window.getInsetsController();
            if (controller != null) {
                controller.hide(WindowInsets.Type.statusBars()
                        | WindowInsets.Type.navigationBars());
                controller.setSystemBarsBehavior(
                        WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            window.getDecorView().setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
        }
    }
}
