package com.xjsonderulo.steamandroid.novalab;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** Owns the rootless Termux:X11 bridge without sharing the rooted lifecycle. */
public final class RootlessLauncherService extends Service {
    public static final String ACTION_START =
            "com.xjsonderulo.steamandroid.novalab.ROOTLESS_START";
    public static final String ACTION_STOP =
            "com.xjsonderulo.steamandroid.novalab.ROOTLESS_STOP";
    public static final String EXTRA_DISPLAY = "rootless_display";

    private static final String TAG = "NovaRootless";
    private static final String CHANNEL_ID = "nova-rootless-session";
    private static final int NOTIFICATION_ID = 27;
    private static final String X11_PACKAGE = "com.termux.x11";
    private static final String RUN_COMMAND_PERMISSION =
            "com.termux.permission.RUN_COMMAND";
    private static final int DEFAULT_DISPLAY = 77;
    private static final int CONNECT_ATTEMPTS = 80;

    private static volatile String status = "Rootless transport is stopped";
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Object lock = new Object();
    private boolean running;
    private int display = DEFAULT_DISPLAY;

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
            stopRootlessTransport();
            return START_NOT_STICKY;
        }
        if (intent == null || !ACTION_START.equals(intent.getAction())) {
            return START_NOT_STICKY;
        }
        synchronized (lock) {
            if (running) {
                setStatus("Rootless transport is already running");
                return START_NOT_STICKY;
            }
            display = intent.getIntExtra(EXTRA_DISPLAY, DEFAULT_DISPLAY);
            running = true;
            startForeground(NOTIFICATION_ID, buildNotification("Starting rootless X11"));
            executor.execute(new Runnable() {
                @Override
                public void run() {
                    startRootlessTransport();
                }
            });
        }
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        synchronized (lock) {
            running = false;
        }
        executor.shutdownNow();
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void startRootlessTransport() {
        if (!isPackageInstalled(RootlessTermuxBridge.TERMUX_PACKAGE)
                || !isPackageInstalled(X11_PACKAGE)) {
            fail("Rootless transport needs Termux and Termux:X11 installed");
            return;
        }
        if (checkSelfPermission(RUN_COMMAND_PERMISSION)
                != PackageManager.PERMISSION_GRANTED) {
            fail("Grant Termux RUN_COMMAND permission in Android settings");
            return;
        }
        final String script;
        try {
            script = readAsset("nova-rootless-termux-x11.sh");
        } catch (IOException error) {
            fail("Missing rootless Termux helper: " + error.getMessage());
            return;
        }

        try {
            RootlessTermuxBridge.sendX11Command(this, script, "start", display);
        } catch (RuntimeException error) {
            fail("Termux RUN_COMMAND rejected rootless start: " + error.getMessage());
            return;
        }

        setStatus("Rootless X11 requested on :" + display);
        int port = 6000 + display;
        for (int attempt = 0; attempt < CONNECT_ATTEMPTS; attempt++) {
            if (isLoopbackPortOpen(port)) {
                setStatus("Rootless X11 ready on 127.0.0.1:" + port);
                return;
            }
            try {
                Thread.sleep(250L);
            } catch (InterruptedException interrupted) {
                Thread.currentThread().interrupt();
                return;
            }
        }
        fail("Rootless X11 did not open 127.0.0.1:" + port
                + " (check Termux RUN_COMMAND and allow-external-apps)");
    }

    private void stopRootlessTransport() {
        final String script;
        try {
            script = readAsset("nova-rootless-termux-x11.sh");
        } catch (IOException error) {
            setStatus("Rootless helper unavailable while stopping");
            stopSelf();
            return;
        }
        try {
            if (isPackageInstalled(RootlessTermuxBridge.TERMUX_PACKAGE)
                    && checkSelfPermission(RUN_COMMAND_PERMISSION)
                    == PackageManager.PERMISSION_GRANTED) {
                RootlessTermuxBridge.sendX11Command(this, script, "stop", display);
            }
            setStatus("Rootless X11 stop requested");
        } catch (RuntimeException error) {
            setStatus("Rootless X11 stop failed: " + error.getMessage());
        } finally {
            synchronized (lock) {
                running = false;
            }
            stopForeground(STOP_FOREGROUND_REMOVE);
            stopSelf();
        }
    }

    private void fail(String message) {
        setStatus("Rootless transport unavailable: " + message);
        synchronized (lock) {
            running = false;
        }
        stopForeground(STOP_FOREGROUND_REMOVE);
        stopSelf();
    }

    private boolean isLoopbackPortOpen(int port) {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("127.0.0.1", port), 250);
            return true;
        } catch (IOException ignored) {
            return false;
        }
    }

    private String readAsset(String name) throws IOException {
        StringBuilder value = new StringBuilder();
        try (InputStream input = getAssets().open(name);
                BufferedReader reader = new BufferedReader(new InputStreamReader(
                        input, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                value.append(line).append('\n');
            }
        }
        return value.toString();
    }

    private boolean isPackageInstalled(String packageName) {
        try {
            getPackageManager().getPackageInfo(packageName, 0);
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private Notification buildNotification(String text) {
        Intent openIntent = new Intent(this, LauncherActivity.class);
        PendingIntent openPendingIntent = PendingIntent.getActivity(
                this, 28, openIntent, PendingIntent.FLAG_UPDATE_CURRENT
                        | PendingIntent.FLAG_IMMUTABLE);
        Intent stopIntent = new Intent(this, RootlessLauncherService.class);
        stopIntent.setAction(ACTION_STOP);
        PendingIntent stopPendingIntent = PendingIntent.getService(
                this, 29, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT
                        | PendingIntent.FLAG_IMMUTABLE);
        return new Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Nova rootless Steam")
                .setContentText(text)
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentIntent(openPendingIntent)
                .setOngoing(true)
                .addAction(new Notification.Action.Builder(
                        android.R.drawable.ic_media_pause, "Stop", stopPendingIntent).build())
                .build();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID, "Nova rootless Steam", NotificationManager.IMPORTANCE_LOW);
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }
}
