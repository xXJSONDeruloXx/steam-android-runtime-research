package com.xjsonderulo.steamandroid.novalab;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
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
    public static final String EXTRA_ROOTFS = "rootfs";
    public static final String EXTRA_ASSET_DIRECTORY = "asset_directory";
    public static final String EXTRA_TERMUX_APK = "termux_apk";
    private static final String TAG = "NovaLauncher";
    private static final String CHANNEL_ID = "nova-steam-session";
    private static final int NOTIFICATION_ID = 17;

    private static volatile String status = "Nova session is stopped";
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Object processLock = new Object();
    private Process launcherProcess;
    private String rootfs;
    private String assetDirectory;
    private String termuxApk;

    public static String getStatus() {
        return status;
    }

    public static void setStatus(String value) {
        status = value;
        Log.i(TAG, value);
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
        if (intent == null || !ACTION_START.equals(intent.getAction())) {
            return START_NOT_STICKY;
        }

        synchronized (processLock) {
            if (launcherProcess != null) {
                setStatus("Nova session is already starting or running");
                return START_NOT_STICKY;
            }
            rootfs = intent.getStringExtra(EXTRA_ROOTFS);
            assetDirectory = intent.getStringExtra(EXTRA_ASSET_DIRECTORY);
            termuxApk = intent.getStringExtra(EXTRA_TERMUX_APK);
            startForeground(NOTIFICATION_ID, buildNotification("Starting Steam"));
            executor.execute(new Runnable() {
                @Override
                public void run() {
                    runLauncher();
                }
            });
        }
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        Process process;
        synchronized (processLock) {
            process = launcherProcess;
            launcherProcess = null;
        }
        if (process != null) {
            process.destroy();
        }
        executor.shutdownNow();
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void runLauncher() {
        File script = new File(assetDirectory, "nova-one-click-root-launcher.sh");
        String command = "/system/bin/sh " + shellQuote(script.getAbsolutePath())
                + " start " + shellQuote(rootfs)
                + " " + shellQuote(sessionStateDirectory())
                + " " + shellQuote(termuxApk)
                + " " + shellQuote(assetDirectory);
        setStatus("Starting rooted Steam session");
        try {
            Process process = new ProcessBuilder("su", "-c", command)
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
        }
    }

    private void stopSession() {
        final String currentRootfs = rootfs == null
                ? "/data/local/tmp/nova-holo-rootfs" : rootfs;
        final String currentAssets = assetDirectory == null
                ? getFilesDir().getAbsolutePath() : assetDirectory;
        final String currentTermuxApk = termuxApk == null ? "" : termuxApk;
        Process process;
        synchronized (processLock) {
            process = launcherProcess;
            launcherProcess = null;
        }
        if (process != null) {
            process.destroy();
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
                    Process stop = new ProcessBuilder("su", "-c", command)
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

    private Notification buildNotification(String text) {
        return new Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Nova Steam")
                .setContentText(text)
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setOngoing(true)
                .build();
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
