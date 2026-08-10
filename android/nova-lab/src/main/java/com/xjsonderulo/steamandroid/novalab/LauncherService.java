package com.xjsonderulo.steamandroid.novalab;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** Keeps the root-side session alive after Termux:X11 becomes foreground. */
public final class LauncherService extends Service {
    public static final String ACTION_START = "com.xjsonderulo.steamandroid.novalab.START";
    public static final String ACTION_STOP = "com.xjsonderulo.steamandroid.novalab.STOP";
    public static final String ACTION_AUDIO_ONLY =
            "com.xjsonderulo.steamandroid.novalab.AUDIO_ONLY";
    public static final String EXTRA_ROOTFS = "rootfs";
    public static final String EXTRA_LEGACY_ROOTFS = "legacy_rootfs";
    public static final String EXTRA_ASSET_DIRECTORY = "asset_directory";
    public static final String EXTRA_TERMUX_APK = "termux_apk";
    public static final String EXTRA_AUDIO_BRIDGE = "audio_bridge";
    public static final String EXTRA_AUDIO_BRIDGE_PORT = "audio_bridge_port";
    public static final String EXTRA_HARDWARE_ACCEL = "hardware_accel";
    public static final String EXTRA_CEF_DISABLE_GPU = "cef_disable_gpu";
    public static final String EXTRA_STEAM_UI_MODE = "steam_ui_mode";
    public static final String EXTRA_STEAM_DISABLE_PRELOAD = "steam_disable_preload";
    public static final String EXTRA_STEAM_DISABLE_SYSTEM_DBUS = "steam_disable_system_dbus";
    public static final String EXTRA_STEAM_HOLO_MESA_FIRST = "steam_holo_mesa_first";
    public static final String EXTRA_STEAM_FORCE_SOFTWARE_GL = "steam_force_software_gl";
    public static final String EXTRA_STEAM_CEF_ENV_SPLIT = "steam_cef_env_split";
    private static final String TAG = "NovaLauncher";
    private static final String CHANNEL_ID = "nova-steam-session";
    private static final int NOTIFICATION_ID = 17;

    private static volatile String status = "Nova session is stopped";
    private static volatile boolean provisioningActive;
    private static volatile int provisioningProgress = -1;
    private static volatile String provisioningPhase = "Ready";
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Object processLock = new Object();
    private Process launcherProcess;
    private Process provisioningProcess;
    private String rootfs;
    private String legacyRootfs;
    private String assetDirectory;
    private String termuxApk;
    private AudioPcmBridge audioBridge;
    private boolean audioBridgeEnabled;
    private int audioBridgePort = AudioPcmBridge.DEFAULT_PORT;
    private boolean hardwareAccel;
    private boolean cefDisableGpu;
    private String steamUiMode = "gamepadui";
    private boolean steamDisablePreload;
    private boolean steamDisableSystemDbus;
    private boolean steamHoloMesaFirst;
    private boolean steamForceSoftwareGl;
    private boolean steamCefEnvSplit;
    private boolean audioOnly;
    private volatile boolean stopRequested;

    public static String getStatus() {
        return status;
    }

    public static boolean isProvisioning() {
        return provisioningActive;
    }

    public static int getProvisioningProgress() {
        return provisioningProgress;
    }

    public static String getProvisioningPhase() {
        return provisioningPhase;
    }

    public static void setStatus(String value) {
        if (value != null && value.startsWith("nova_provision_progress=")) {
            updateProvisioningProgress(value);
        } else {
            status = value;
        }
        Log.i(TAG, value);
    }

    private static void updateProvisioningProgress(String line) {
        String phase = "Preparing";
        String artifact = "";
        String[] fields = line.split(" ");
        for (String field : fields) {
            if (field.startsWith("nova_provision_progress=")) {
                try {
                    provisioningProgress = Integer.parseInt(
                            field.substring("nova_provision_progress=".length()));
                } catch (NumberFormatException ignored) {
                    provisioningProgress = -1;
                }
            } else if (field.startsWith("phase=")) {
                phase = friendlyProvisioningPhase(field.substring("phase=".length()));
            } else if (field.startsWith("artifact=")) {
                artifact = field.substring("artifact=".length());
            }
        }
        provisioningPhase = artifact.isEmpty() ? phase : phase + " · " + artifact;
        status = "Provisioning: " + provisioningPhase;
    }

    private static String friendlyProvisioningPhase(String phase) {
        if ("preflight".equals(phase)) return "Checking rooted device";
        if ("rootfs".equals(phase)) return "Downloading Holo runtime";
        if ("rootfs_extract".equals(phase)) return "Unpacking Holo runtime";
        if ("packages".equals(phase)) return "Installing X11 package closure";
        if ("package_install".equals(phase)) return "Finalizing package closure";
        if ("steam_manifest".equals(phase)) return "Verifying Steam seed manifest";
        if ("steam_seed".equals(phase)) return "Downloading Steam ARM64 seed";
        if ("steam_seed_extract".equals(phase)) return "Installing Steam client";
        if ("steamrt".equals(phase)) return "Downloading SteamRT3C";
        if ("steamrt_extract".equals(phase)) return "Unpacking SteamRT3C";
        if ("complete".equals(phase)) return "Activating verified runtime";
        return phase;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_STOP.equals(intent.getAction())) {
            stopSession();
            return START_NOT_STICKY;
        }
        if (intent == null) {
            return START_NOT_STICKY;
        }

        if (ACTION_AUDIO_ONLY.equals(intent.getAction())) {
            synchronized (processLock) {
                if (launcherProcess != null || audioBridge != null) {
                    setStatus("Nova audio bridge is already starting or running");
                    return START_NOT_STICKY;
                }
                audioOnly = true;
                audioBridgeEnabled = true;
                audioBridgePort = requestedAudioPort(intent);
                startForeground(NOTIFICATION_ID, buildNotification("Starting audio bridge"));
                if (!startAudioBridgeLocked()) {
                    audioOnly = false;
                    stopForeground(STOP_FOREGROUND_REMOVE);
                    stopSelf();
                }
            }
            return START_NOT_STICKY;
        }
        if (!ACTION_START.equals(intent.getAction())) {
            return START_NOT_STICKY;
        }

        synchronized (processLock) {
            if (launcherProcess != null || audioBridge != null) {
                setStatus("Nova session is already starting or running");
                return START_NOT_STICKY;
            }
            rootfs = intent.getStringExtra(EXTRA_ROOTFS);
            legacyRootfs = intent.getStringExtra(EXTRA_LEGACY_ROOTFS);
            assetDirectory = intent.getStringExtra(EXTRA_ASSET_DIRECTORY);
            termuxApk = intent.getStringExtra(EXTRA_TERMUX_APK);
            stopRequested = false;
            audioOnly = false;
            audioBridgeEnabled = intent.getBooleanExtra(EXTRA_AUDIO_BRIDGE, false);
            audioBridgePort = requestedAudioPort(intent);
            hardwareAccel = intent.getBooleanExtra(EXTRA_HARDWARE_ACCEL, false);
            cefDisableGpu = intent.hasExtra(EXTRA_CEF_DISABLE_GPU)
                    ? intent.getBooleanExtra(EXTRA_CEF_DISABLE_GPU, false) : !hardwareAccel;
            steamUiMode = requestedSteamUiMode(intent);
            steamDisablePreload = intent.getBooleanExtra(EXTRA_STEAM_DISABLE_PRELOAD, false);
            steamDisableSystemDbus = intent.getBooleanExtra(EXTRA_STEAM_DISABLE_SYSTEM_DBUS, false);
            steamHoloMesaFirst = intent.getBooleanExtra(EXTRA_STEAM_HOLO_MESA_FIRST, false);
            steamForceSoftwareGl = intent.getBooleanExtra(EXTRA_STEAM_FORCE_SOFTWARE_GL, false);
            steamCefEnvSplit = intent.getBooleanExtra(EXTRA_STEAM_CEF_ENV_SPLIT, false);
            startForeground(NOTIFICATION_ID, buildNotification("Starting Steam"));
            executor.execute(new Runnable() {
                @Override
                public void run() {
                    runProvisionAndLauncher();
                }
            });
        }
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        stopRequested = true;
        Process process;
        Process provisioning;
        synchronized (processLock) {
            process = launcherProcess;
            launcherProcess = null;
            provisioning = provisioningProcess;
            provisioningProcess = null;
        }
        if (process != null) {
            process.destroy();
        }
        if (provisioning != null) {
            provisioning.destroy();
        }
        stopAudioBridge();
        executor.shutdownNow();
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void runLauncher() {
        File script = new File(assetDirectory, "nova-one-click-root-launcher.sh");
        String command = "NOVA_ANDROID_LAUNCHER_HARDWARE_ACCEL="
                + shellQuote(hardwareAccel ? "1" : "0")
                + " NOVA_ANDROID_LAUNCHER_CEF_DISABLE_GPU="
                + shellQuote(cefDisableGpu ? "1" : "0")
                + " NOVA_ANDROID_LAUNCHER_STEAM_UI_MODE="
                + shellQuote(steamUiMode)
                + " NOVA_ANDROID_LAUNCHER_STEAM_DISABLE_PRELOAD="
                + shellQuote(steamDisablePreload ? "1" : "0")
                + " NOVA_ANDROID_LAUNCHER_STEAM_DISABLE_SYSTEM_DBUS="
                + shellQuote(steamDisableSystemDbus ? "1" : "0")
                + " NOVA_ANDROID_LAUNCHER_STEAM_HOLO_MESA_FIRST="
                + shellQuote(steamHoloMesaFirst ? "1" : "0")
                + " NOVA_ANDROID_LAUNCHER_STEAM_FORCE_SOFTWARE_GL="
                + shellQuote(steamForceSoftwareGl ? "1" : "0")
                + " NOVA_ANDROID_LAUNCHER_STEAM_CEF_ENV_SPLIT="
                + shellQuote(steamCefEnvSplit ? "1" : "0")
                + " NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE="
                + shellQuote(audioBridgeEnabled ? "1" : "0")
                + " NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE_PORT="
                + shellQuote(Integer.toString(audioBridgePort))
                + " /system/bin/sh " + shellQuote(script.getAbsolutePath())
                + " start " + shellQuote(rootfs)
                + " " + shellQuote(sessionStateDirectory())
                + " " + shellQuote(termuxApk)
                + " " + shellQuote(assetDirectory);
        setStatus("Starting rooted Steam session");
        try {
            // Keep the app-launched root process in Magisk's mount-master
            // namespace. The Termux:X11 base APK lives under /data/app and
            // app_process must see that same package mount as the foreground
            // Activity; plain su -c can place this child in an isolated view.
            Process process = new ProcessBuilder("su", "-mm", "0", "-c", command)
                    .redirectErrorStream(true)
                    .start();
            synchronized (processLock) {
                launcherProcess = process;
            }
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    setStatus(line);
                }
            }
            int exitCode = process.waitFor();
            setStatus("Nova launcher exited with status " + exitCode);
        } catch (IOException error) {
            setStatus("Root launch failed: " + error.getMessage());
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            setStatus("Root launch interrupted");
        } finally {
            synchronized (processLock) {
                launcherProcess = null;
            }
            stopAudioBridge();
        }
    }

    private void runProvisionAndLauncher() {
        int provisionStatus = runProvisioner();
        if (stopRequested) {
            setStatus("Nova provisioning stopped");
            return;
        }
        if (provisionStatus != 0) {
            setStatus("Nova provisioning failed; attempting preserved rollback");
        } else {
            setStatus("Nova runtime provisioned; starting Steam");
        }
        synchronized (processLock) {
            if (!startAudioBridgeLocked()) {
                stopForeground(STOP_FOREGROUND_REMOVE);
                stopSelf();
                return;
            }
        }
        runLauncher();
    }

    private int runProvisioner() {
        File script = new File(assetDirectory, "nova-provision-runtime.sh");
        String command = "/system/bin/sh " + shellQuote(script.getAbsolutePath())
                + " provision " + shellQuote(legacyRootfs == null
                ? "/data/local/tmp/nova-holo-rootfs" : legacyRootfs)
                + " " + shellQuote(termuxApk)
                + " " + shellQuote(assetDirectory);
        provisioningActive = true;
        provisioningProgress = 0;
        provisioningPhase = "Checking rooted device";
        setStatus("Provisioning versioned Nova runtime");
        try {
            Process process = new ProcessBuilder("su", "-mm", "0", "-c", command)
                    .redirectErrorStream(true)
                    .start();
            synchronized (processLock) {
                provisioningProcess = process;
            }
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    setStatus(line);
                }
            }
            int exitCode = process.waitFor();
            setStatus("Nova provisioner exited with status " + exitCode);
            return exitCode;
        } catch (IOException error) {
            setStatus("Nova provisioning root launch failed: " + error.getMessage());
            return 1;
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            setStatus("Nova provisioning interrupted");
            return 1;
        } finally {
            provisioningActive = false;
            synchronized (processLock) {
                provisioningProcess = null;
            }
        }
    }

    private void stopSession() {
        stopRequested = true;
        final String currentRootfs = rootfs == null
                ? "/data/local/tmp/nova-active-runtime" : rootfs;
        final String currentAssets = assetDirectory == null
                ? new File(getFilesDir(), "launcher").getAbsolutePath() : assetDirectory;
        final String currentTermuxApk = termuxApk == null ? "" : termuxApk;
        Process process;
        Process provisioning;
        boolean audioOnlyRun;
        synchronized (processLock) {
            process = launcherProcess;
            launcherProcess = null;
            provisioning = provisioningProcess;
            provisioningProcess = null;
            audioOnlyRun = audioOnly;
            audioOnly = false;
        }
        if (process != null) {
            process.destroy();
        }
        if (provisioning != null) {
            provisioning.destroy();
        }
        stopAudioBridge();
        if (audioOnlyRun) {
            setStatus("Nova audio bridge stopped");
            stopForeground(STOP_FOREGROUND_REMOVE);
            stopSelf();
            return;
        }
        setStatus("Stopping Nova session");
        executor.execute(new Runnable() {
            @Override
            public void run() {
                File script = new File(currentAssets, "nova-one-click-root-launcher.sh");
                String command = "/system/bin/sh " + shellQuote(script.getAbsolutePath())
                        + " stop " + shellQuote(currentRootfs)
                        + " " + shellQuote(sessionStateDirectory())
                        + " " + shellQuote(currentTermuxApk)
                        + " " + shellQuote(currentAssets);
                try {
                    Process stop = new ProcessBuilder("su", "-mm", "0", "-c", command)
                            .redirectErrorStream(true)
                            .start();
                    try (BufferedReader reader = new BufferedReader(
                            new InputStreamReader(stop.getInputStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            setStatus(line);
                        }
                    }
                    int exitCode = stop.waitFor();
                    setStatus(exitCode == 0
                            ? "Nova session stopped" : "Nova stop exited with status " + exitCode);
                } catch (Exception error) {
                    setStatus("Root stop failed: " + error.getMessage());
                } finally {
                    stopForeground(STOP_FOREGROUND_REMOVE);
                    stopSelf();
                }
            }
        });
    }

    private String sessionStateDirectory() {
        return "/data/local/tmp/nova-android-launcher";
    }

    private boolean startAudioBridgeLocked() {
        if (!audioBridgeEnabled) {
            return true;
        }
        AudioPcmBridge bridge = new AudioPcmBridge(audioBridgePort);
        if (!bridge.start()) {
            setStatus("Nova audio bridge failed: " + bridge.getStatus());
            return false;
        }
        audioBridge = bridge;
        setStatus("Nova audio bridge ready port=" + audioBridgePort);
        return true;
    }

    private void stopAudioBridge() {
        AudioPcmBridge bridge;
        synchronized (processLock) {
            bridge = audioBridge;
            audioBridge = null;
            audioBridgeEnabled = false;
        }
        if (bridge != null) {
            bridge.stop();
        }
    }

    private int requestedAudioPort(Intent intent) {
        int requested = intent.getIntExtra(
                EXTRA_AUDIO_BRIDGE_PORT, AudioPcmBridge.DEFAULT_PORT);
        if (requested < 1024 || requested > 65535) {
            return AudioPcmBridge.DEFAULT_PORT;
        }
        return requested;
    }

    private String requestedSteamUiMode(Intent intent) {
        return "minimal".equals(intent.getStringExtra(EXTRA_STEAM_UI_MODE))
                ? "minimal" : "gamepadui";
    }

    private Notification buildNotification(String text) {
        Intent openIntent = new Intent(this, LauncherActivity.class);
        PendingIntent openPendingIntent = PendingIntent.getActivity(
                this, 18, openIntent, pendingIntentFlags());

        Intent stopIntent = new Intent(this, LauncherService.class);
        stopIntent.setAction(ACTION_STOP);
        PendingIntent stopPendingIntent = PendingIntent.getService(
                this, 19, stopIntent, pendingIntentFlags());

        return new Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Nova Steam")
                .setContentText(text)
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentIntent(openPendingIntent)
                .setOngoing(true)
                .addAction(new Notification.Action.Builder(
                        android.R.drawable.ic_media_pause, "Stop", stopPendingIntent).build())
                .build();
    }

    private int pendingIntentFlags() {
        return PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID, "Nova Steam session", NotificationManager.IMPORTANCE_LOW);
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    private static String shellQuote(String value) {
        return "'" + value.replace("'", "'\\''") + "'";
    }
}
