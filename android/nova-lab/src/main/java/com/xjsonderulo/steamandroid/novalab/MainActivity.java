package com.xjsonderulo.steamandroid.novalab;

import android.app.Activity;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.hardware.HardwareBuffer;
import android.hardware.input.InputManager;
import android.net.LocalServerSocket;
import android.net.LocalSocket;
import android.os.Bundle;
import android.util.Log;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public final class MainActivity extends Activity implements SurfaceHolder.Callback {
    private static final String TAG = "NovaLab";
    private static final int SURFACE_FRAMES = 120;

    static {
        System.loadLibrary("novabridge");
    }

    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private volatile boolean surfaceProbeRunning;
    private volatile Surface presentationSurface;
    private TextView surfaceStatus;
    private TextView rootStatus;
    private TextView nativeStatus;
    private TextView androidVulkanStatus;
    private TextView bridgeStatus;
    private boolean doubleBufferPresentationMode;
    private File doubleBufferReportFile;
    private boolean androidInputKeyOnly;
    private volatile boolean androidInputBridgeRunning;
    private Thread androidInputBridgeThread;
    private volatile LocalServerSocket androidInputServer;
    private volatile LocalSocket androidInputClient;
    private volatile OutputStream androidInputOutput;
    private File androidInputSocketFile;
    private File androidInputReportFile;
    private boolean androidInputKeyLogged;
    private boolean androidInputKeyDeviceLogged;
    private boolean androidInputMotionLogged;

    private static native String nativeRunHardwareBufferProbe();
    private static native String nativeRunAndroidVulkanHardwareBufferProbe();
    private static native String nativeRunDmaBufBridge(String socketPath, Surface surface);
    private static native String nativeRunDmaBufDoubleBufferBridge(String socketPath,
                                                                     Surface surface,
                                                                     int frameCount,
                                                                     int frameWidth,
                                                                     int frameHeight);

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setPadding(dp(12), dp(8), dp(12), dp(8));
        page.setBackgroundColor(Color.rgb(16, 20, 24));

        TextView title = new TextView(this);
        title.setText("Nova Linux Bridge Lab");
        title.setTextColor(Color.WHITE);
        title.setTextSize(21);
        page.addView(title, new LinearLayout.LayoutParams(-1, -2));

        TextView subtitle = new TextView(this);
        subtitle.setText("Surface + HardwareBuffer + rooted namespace/chroot smoke test");
        subtitle.setTextColor(Color.LTGRAY);
        subtitle.setTextSize(12);
        page.addView(subtitle, new LinearLayout.LayoutParams(-1, -2));

        SurfaceView surface = new SurfaceView(this);
        doubleBufferPresentationMode = getIntent().getBooleanExtra(
                "run_dmabuf_double_buffer", false);
        androidInputKeyOnly = getIntent().getBooleanExtra("android_input_key_only", false);
        surface.setZOrderOnTop(true);
        surface.getHolder().addCallback(this);
        surface.getHolder().setFormat(PixelFormat.RGBA_8888);
        surface.getHolder().setFixedSize(960, 540);
        LinearLayout.LayoutParams surfaceParams = new LinearLayout.LayoutParams(-1, 0, 1.0f);
        surfaceParams.topMargin = dp(8);
        surfaceParams.bottomMargin = dp(8);
        page.addView(surface, surfaceParams);

        surfaceStatus = statusText("Surface: waiting for SurfaceView");
        page.addView(surfaceStatus, new LinearLayout.LayoutParams(-1, -2));
        rootStatus = statusText("Root: not run");
        page.addView(rootStatus, new LinearLayout.LayoutParams(-1, -2));
        nativeStatus = statusText("Native: not run");
        page.addView(nativeStatus, new LinearLayout.LayoutParams(-1, -2));
        androidVulkanStatus = statusText("Android Vulkan: not run");
        page.addView(androidVulkanStatus, new LinearLayout.LayoutParams(-1, -2));
        bridgeStatus = statusText("Linux bridge: not run");
        page.addView(bridgeStatus, new LinearLayout.LayoutParams(-1, -2));

        LinearLayout buttons = new LinearLayout(this);
        buttons.setOrientation(LinearLayout.HORIZONTAL);
        Button rootButton = new Button(this);
        rootButton.setText("Run rooted probe");
        rootButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                runRootProbe();
            }
        });
        buttons.addView(rootButton, new LinearLayout.LayoutParams(0, -2, 1.0f));

        Button nativeButton = new Button(this);
        nativeButton.setText("Run native buffer");
        nativeButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                runNativeHardwareBufferProbe();
            }
        });
        buttons.addView(nativeButton, new LinearLayout.LayoutParams(0, -2, 1.0f));

        Button clearButton = new Button(this);
        clearButton.setText("Clear");
        clearButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                rootStatus.setText("Root: not run");
                nativeStatus.setText("Native: not run");
                androidVulkanStatus.setText("Android Vulkan: not run");
                bridgeStatus.setText("Linux bridge: not run");
            }
        });
        buttons.addView(clearButton, new LinearLayout.LayoutParams(0, -2, 1.0f));
        page.addView(buttons, new LinearLayout.LayoutParams(-1, -2));

        LinearLayout vulkanButtons = new LinearLayout(this);
        vulkanButtons.setOrientation(LinearLayout.HORIZONTAL);
        Button androidVulkanButton = new Button(this);
        androidVulkanButton.setText("Run Android Vulkan");
        androidVulkanButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                runAndroidVulkanHardwareBufferProbe();
            }
        });
        vulkanButtons.addView(androidVulkanButton,
                new LinearLayout.LayoutParams(0, -2, 1.0f));
        Button bridgeButton = new Button(this);
        bridgeButton.setText("Run Linux bridge");
        bridgeButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                runDmaBufBridge();
            }
        });
        vulkanButtons.addView(bridgeButton,
                new LinearLayout.LayoutParams(0, -2, 1.0f));
        Button doubleBufferButton = new Button(this);
        doubleBufferButton.setText("Run 2-buffer loop");
        doubleBufferButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                runDmaBufDoubleBufferBridge();
            }
        });
        vulkanButtons.addView(doubleBufferButton,
                new LinearLayout.LayoutParams(0, -2, 1.0f));
        page.addView(vulkanButtons, new LinearLayout.LayoutParams(-1, -2));

        ScrollView reportScroll = new ScrollView(this);
        TextView hint = new TextView(this);
        hint.setText("The full root report is logged with tag NovaLab and written to app files.");
        hint.setTextColor(Color.GRAY);
        hint.setTextSize(11);
        reportScroll.addView(hint);
        page.addView(reportScroll, new LinearLayout.LayoutParams(-1, dp(28)));

        setContentView(page);

        if (doubleBufferPresentationMode) {
            surfaceStatus.setText("Surface: Linux presentation mode");
            doubleBufferReportFile = new File(getFilesDir(),
                    "dmabuf-double-buffer-report.txt");
            if (doubleBufferReportFile.exists() && !doubleBufferReportFile.delete()) {
                Log.w(TAG, "double_buffer_report_delete_failed path="
                        + doubleBufferReportFile.getAbsolutePath());
            }
        }

        if (getIntent().getBooleanExtra("run_android_input_bridge", false)) {
            startAndroidInputBridge();
        }

        Log.i(TAG, "launch_flags run_dmabuf_double_buffer="
                + getIntent().getBooleanExtra("run_dmabuf_double_buffer", false)
                + " frame_count=" + getIntent().getIntExtra(
                        "dmabuf_double_buffer_frames", -1)
                + " frame_size=" + getIntent().getIntExtra(
                        "dmabuf_double_buffer_width", -1)
                + "x" + getIntent().getIntExtra(
                        "dmabuf_double_buffer_height", -1)
                + " android_input_key_only=" + androidInputKeyOnly);

        if (getIntent().getBooleanExtra("run_root", false)) {
            rootButton.postDelayed(new Runnable() {
                @Override
                public void run() {
                    runRootProbe();
                }
            }, 700);
        }
        if (getIntent().getBooleanExtra("run_native", false)) {
            nativeButton.postDelayed(new Runnable() {
                @Override
                public void run() {
                    runNativeHardwareBufferProbe();
                }
            }, 700);
        }
        if (getIntent().getBooleanExtra("run_android_vulkan", false)) {
            androidVulkanButton.postDelayed(new Runnable() {
                @Override
                public void run() {
                    runAndroidVulkanHardwareBufferProbe();
                }
            }, 900);
        }
        if (getIntent().getBooleanExtra("run_dmabuf_bridge", false)) {
            bridgeButton.postDelayed(new Runnable() {
                @Override
                public void run() {
                    runDmaBufBridge();
                }
            }, 1100);
        }
        if (getIntent().getBooleanExtra("run_dmabuf_double_buffer", false)) {
            boolean scheduled = doubleBufferButton.postDelayed(new Runnable() {
                @Override
                public void run() {
                    Log.i(TAG, "auto_double_buffer_invoked");
                    runDmaBufDoubleBufferBridge();
                }
            }, 1300);
            Log.i(TAG, "auto_double_buffer_scheduled=" + scheduled);
        }
    }

    @Override
    protected void onDestroy() {
        surfaceProbeRunning = false;
        stopAndroidInputBridge();
        worker.shutdownNow();
        super.onDestroy();
    }

    @Override
    public void surfaceCreated(final SurfaceHolder holder) {
        presentationSurface = holder.getSurface();
        if (doubleBufferPresentationMode) {
            return;
        }
        if (surfaceProbeRunning) {
            return;
        }
        surfaceProbeRunning = true;
        worker.execute(new Runnable() {
            @Override
            public void run() {
                final String result = runSurfaceProbe(holder);
                Log.i(TAG, "surface_probe " + result);
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        surfaceStatus.setText("Surface: " + result);
                    }
                });
            }
        });
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        Log.i(TAG, "surface_changed format=" + format + " size=" + width + "x" + height);
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        surfaceProbeRunning = false;
        presentationSurface = null;
        Log.i(TAG, "surface_destroyed");
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (androidInputBridgeRunning) {
            sendAndroidInputLine("K " + event.getKeyCode() + " " + event.getAction() + "\n",
                    true);
            String dispatchMarker = "android_input_key_dispatch keycode="
                    + event.getKeyCode() + " action=" + event.getAction()
                    + " source=0x" + Integer.toHexString(event.getSource());
            if (event.getKeyCode() != KeyEvent.KEYCODE_UNKNOWN) {
                Log.i(TAG, dispatchMarker);
                appendAndroidInputReport(dispatchMarker);
            }
            int controllerSources = InputDevice.SOURCE_GAMEPAD | InputDevice.SOURCE_JOYSTICK;
            if (!androidInputKeyDeviceLogged
                    && event.getDeviceId() >= 0
                    && (event.getSource() & controllerSources) != 0) {
                androidInputKeyDeviceLogged = true;
                String marker = "android_input_key_event device=" + event.getDeviceId()
                        + " keycode=" + event.getKeyCode()
                        + " source=0x" + Integer.toHexString(event.getSource());
                Log.i(TAG, marker);
                appendAndroidInputReport(marker);
            }
        }
        return super.dispatchKeyEvent(event);
    }

    @Override
    public boolean dispatchGenericMotionEvent(MotionEvent event) {
        int controllerSources = InputDevice.SOURCE_GAMEPAD | InputDevice.SOURCE_JOYSTICK;
        if (androidInputBridgeRunning
                && !androidInputKeyOnly
                && event.getAction() == MotionEvent.ACTION_MOVE
                && (event.getSource() & controllerSources) != 0) {
            int[] axes = {0, 1, 11, 14, 15, 16, 17, 18};
            for (int axis : axes) {
                String line = String.format(Locale.US, "A %d %.5f\n", axis,
                        event.getAxisValue(axis));
                sendAndroidInputLine(line, false);
            }
        }
        return super.dispatchGenericMotionEvent(event);
    }

    private void startAndroidInputBridge() {
        androidInputBridgeRunning = true;
        androidInputKeyLogged = false;
        androidInputKeyDeviceLogged = false;
        androidInputMotionLogged = false;
        androidInputSocketFile = new File(getFilesDir(), "nova-input.sock");
        androidInputReportFile = new File(getFilesDir(), "android-input-bridge-report.txt");
        if (androidInputSocketFile.exists() && !androidInputSocketFile.delete()) {
            Log.w(TAG, "android_input_socket_delete_failed path="
                    + androidInputSocketFile.getAbsolutePath());
        }
        if (androidInputReportFile.exists() && !androidInputReportFile.delete()) {
            Log.w(TAG, "android_input_report_delete_failed path="
                    + androidInputReportFile.getAbsolutePath());
        }
        logAndroidInputDevices();
        androidInputBridgeThread = new Thread(new Runnable() {
            @Override
            public void run() {
                runAndroidInputBridgeServer();
            }
        }, "nova-android-input-bridge");
        androidInputBridgeThread.start();
    }

    private void runAndroidInputBridgeServer() {
        try {
            androidInputServer = new LocalServerSocket(androidInputSocketFile.getAbsolutePath());
            Log.i(TAG, "android_input_socket=listening path="
                    + androidInputSocketFile.getAbsolutePath());
            appendAndroidInputReport("android_input_socket=listening");
            while (androidInputBridgeRunning) {
                LocalSocket client = androidInputServer.accept();
                synchronized (this) {
                    androidInputClient = client;
                    androidInputOutput = client.getOutputStream();
                }
                Log.i(TAG, "android_input_socket=connected");
                appendAndroidInputReport("android_input_socket=connected");
                while (androidInputBridgeRunning && client.isConnected()) {
                    try {
                        Thread.sleep(250L);
                    } catch (InterruptedException error) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
                closeAndroidInputClient(client);
            }
        } catch (IOException error) {
            if (androidInputBridgeRunning) {
                Log.e(TAG, "android_input_socket_failed", error);
            }
        } finally {
            LocalServerSocket server = androidInputServer;
            androidInputServer = null;
            if (server != null) {
                try {
                    server.close();
                } catch (IOException ignored) {
                }
            }
        }
    }

    private void stopAndroidInputBridge() {
        androidInputBridgeRunning = false;
        LocalServerSocket server = androidInputServer;
        if (server != null) {
            try {
                server.close();
            } catch (IOException ignored) {
            }
        }
        LocalSocket client = androidInputClient;
        if (client != null) {
            closeAndroidInputClient(client);
        }
        Thread bridgeThread = androidInputBridgeThread;
        if (bridgeThread != null) {
            bridgeThread.interrupt();
        }
        if (androidInputSocketFile != null && androidInputSocketFile.exists()) {
            androidInputSocketFile.delete();
        }
    }

    private synchronized void closeAndroidInputClient(LocalSocket client) {
        if (androidInputClient == client) {
            androidInputOutput = null;
            androidInputClient = null;
        }
        try {
            client.close();
        } catch (IOException ignored) {
        }
    }

    private synchronized void sendAndroidInputLine(String line, boolean key) {
        if (androidInputOutput == null) {
            return;
        }
        try {
            androidInputOutput.write(line.getBytes(StandardCharsets.UTF_8));
            androidInputOutput.flush();
            if (key && !androidInputKeyLogged) {
                androidInputKeyLogged = true;
                Log.i(TAG, "android_input_key_forwarded=pass");
                appendAndroidInputReport("android_input_key_forwarded=pass");
            } else if (!key && !androidInputMotionLogged) {
                androidInputMotionLogged = true;
                Log.i(TAG, "android_input_motion_forwarded=pass");
                appendAndroidInputReport("android_input_motion_forwarded=pass");
            }
        } catch (IOException error) {
            Log.w(TAG, "android_input_socket_write_failed", error);
            androidInputOutput = null;
        }
    }

    private synchronized void appendAndroidInputReport(String line) {
        if (androidInputReportFile == null) {
            return;
        }
        try {
            FileOutputStream output = new FileOutputStream(androidInputReportFile, true);
            output.write((line + "\n").getBytes(StandardCharsets.UTF_8));
            output.close();
        } catch (IOException error) {
            Log.w(TAG, "android_input_report_write_failed", error);
        }
    }

    private void logAndroidInputDevices() {
        InputManager manager = (InputManager) getSystemService(INPUT_SERVICE);
        if (manager == null) {
            Log.i(TAG, "android_input_device_manager=unavailable");
            return;
        }
        int controllerCount = 0;
        int controllerSources = InputDevice.SOURCE_GAMEPAD | InputDevice.SOURCE_JOYSTICK;
        for (int id : manager.getInputDeviceIds()) {
            InputDevice device = manager.getInputDevice(id);
            if (device == null) {
                continue;
            }
            Log.i(TAG, "android_input_device id=" + id
                    + " name=" + device.getName()
                    + " sources=0x" + Integer.toHexString(device.getSources()));
            if ((device.getSources() & controllerSources) != 0) {
                controllerCount++;
            }
        }
        String controllerMarker = "android_input_device_controller="
                + (controllerCount > 0 ? "pass" : "none")
                + " count=" + controllerCount;
        Log.i(TAG, controllerMarker);
        appendAndroidInputReport(controllerMarker);
    }

    private String runSurfaceProbe(SurfaceHolder holder) {
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        paint.setColor(Color.WHITE);
        paint.setTextSize(dp(22));
        int frames = 0;
        long start = System.nanoTime();
        for (int i = 0; i < SURFACE_FRAMES && surfaceProbeRunning; i++) {
            Canvas canvas = null;
            try {
                canvas = holder.lockCanvas();
                if (canvas != null) {
                    canvas.drawColor((i & 1) == 0 ? Color.rgb(24, 62, 74) : Color.rgb(66, 42, 78));
                    canvas.drawText("Nova Surface frame " + (i + 1) + "/" + SURFACE_FRAMES,
                            dp(22), dp(42), paint);
                    frames++;
                }
            } catch (RuntimeException e) {
                Log.e(TAG, "surface_frame_failed", e);
                break;
            } finally {
                if (canvas != null) {
                    holder.unlockCanvasAndPost(canvas);
                }
            }
            try {
                Thread.sleep(16L);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
        long elapsedMs = Math.max(1L, (System.nanoTime() - start) / 1_000_000L);

        String hardwareBuffer = "unsupported";
        long usage = HardwareBuffer.USAGE_CPU_WRITE_OFTEN
                | HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE
                | HardwareBuffer.USAGE_COMPOSER_OVERLAY;
        try {
            boolean supported = HardwareBuffer.isSupported(64, 64, HardwareBuffer.RGBA_8888, 1, usage);
            if (supported) {
                HardwareBuffer buffer = HardwareBuffer.create(64, 64, HardwareBuffer.RGBA_8888, 1, usage);
                hardwareBuffer = "created size=" + buffer.getWidth() + "x" + buffer.getHeight()
                        + " format=" + buffer.getFormat()
                        + " usage=0x" + Long.toHexString(buffer.getUsage());
                buffer.close();
            } else {
                hardwareBuffer = "not_supported usage=0x" + Long.toHexString(usage);
            }
        } catch (RuntimeException e) {
            hardwareBuffer = "create_failed " + e.getClass().getSimpleName() + ":" + e.getMessage();
        }
        surfaceProbeRunning = false;
        double fps = frames * 1000.0 / elapsedMs;
        return "frames=" + frames + "/" + SURFACE_FRAMES
                + " elapsed_ms=" + elapsedMs
                + " approx_fps=" + String.format(java.util.Locale.US, "%.1f", fps)
                + " hardware_buffer=" + hardwareBuffer;
    }

    private void runRootProbe() {
        rootStatus.setText("Root: running su probe...");
        worker.execute(new Runnable() {
            @Override
            public void run() {
                int exit = -1;
                String console = "";
                String report = "";
                try {
                    File script = installProbeAsset();
                    File reportFile = new File(getFilesDir(), "root-probe-report.txt");
                    File work = new File(getFilesDir(), "root-probe-work");
                    String command = "/system/bin/sh " + shellQuote(script.getAbsolutePath())
                            + " " + shellQuote(reportFile.getAbsolutePath())
                            + " " + shellQuote(work.getAbsolutePath());
                    Process process = new ProcessBuilder("su", "-c", command)
                            .redirectErrorStream(true)
                            .start();
                    console = readAll(process.getInputStream());
                    exit = process.waitFor();
                    report = readFile(reportFile);
                } catch (Exception e) {
                    console = e.toString();
                }
                final int resultExit = exit;
                final String result = "exit=" + resultExit + "\n"
                        + (console.length() == 0 ? "" : "su_output=" + console + "\n")
                        + report;
                Log.i(TAG, "root_probe\n" + result);
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        rootStatus.setText("Root:\n" + trimForUi(result));
                    }
                });
            }
        });
    }

    private void runNativeHardwareBufferProbe() {
        nativeStatus.setText("Native: running AHardwareBuffer handle probe...");
        worker.execute(new Runnable() {
            @Override
            public void run() {
                String result;
                try {
                    result = nativeRunHardwareBufferProbe();
                } catch (Throwable error) {
                    result = "native_exception=" + error;
                }
                final String report = result;
                Log.i(TAG, "native_hardware_buffer_probe\n" + report);
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        nativeStatus.setText("Native:\n" + trimForUi(report));
                    }
                });
            }
        });
    }

    private void runAndroidVulkanHardwareBufferProbe() {
        androidVulkanStatus.setText("Android Vulkan: running AHardwareBuffer import probe...");
        worker.execute(new Runnable() {
            @Override
            public void run() {
                String result;
                try {
                    result = nativeRunAndroidVulkanHardwareBufferProbe();
                } catch (Throwable error) {
                    result = "native_exception=" + error;
                }
                final String report = result;
                Log.i(TAG, "android_vulkan_hardware_buffer_probe\n" + report);
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        androidVulkanStatus.setText("Android Vulkan:\n" + trimForUi(report));
                    }
                });
            }
        });
    }

    private void runDmaBufBridge() {
        final String socketPath = new File(
                getFilesDir(), "nova-lab-ahb-bridge.sock").getAbsolutePath();
        bridgeStatus.setText("Linux bridge: waiting for Holo DMA-BUF importer...");
        worker.execute(new Runnable() {
            @Override
            public void run() {
                String result;
                try {
                    result = nativeRunDmaBufBridge(socketPath, presentationSurface);
                } catch (Throwable error) {
                    result = "native_exception=" + error;
                }
                final String report = result;
                Log.i(TAG, "dma_buf_bridge\n" + report);
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        bridgeStatus.setText("Linux bridge:\n" + trimForUi(report));
                    }
                });
            }
        });
    }

    private void runDmaBufDoubleBufferBridge() {
        Log.i(TAG, "double_buffer_method_entered");
        final String socketPath = new File(
                getFilesDir(), "nova-lab-ahb-double-buffer.sock").getAbsolutePath();
        final int frameCount = getIntent().getIntExtra(
                "dmabuf_double_buffer_frames", 5);
        final int frameWidth = getIntent().getIntExtra(
                "dmabuf_double_buffer_width", 64);
        final int frameHeight = getIntent().getIntExtra(
                "dmabuf_double_buffer_height", 64);
        bridgeStatus.setText("Linux 2-buffer loop: waiting for Holo importer...");
        worker.execute(new Runnable() {
            @Override
            public void run() {
                String result;
                try {
                    result = nativeRunDmaBufDoubleBufferBridge(socketPath,
                            presentationSurface, frameCount, frameWidth,
                            frameHeight);
                } catch (Throwable error) {
                    result = "native_exception=" + error;
                }
                final String report = result;
                writeDoubleBufferReport(report);
                Log.i(TAG, "dma_buf_double_buffer_bridge\n" + report);
                Log.i(TAG, "dma_buf_double_buffer_summary "
                        + extractReportLine(report, "ahb_double_buffer_frames=")
                        + " " + extractReportLine(report, "ahb_double_buffer="));
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        bridgeStatus.setText("Linux 2-buffer loop:\n" + trimForUi(report));
                    }
                });
            }
        });
    }

    private void writeDoubleBufferReport(String report) {
        if (doubleBufferReportFile == null) {
            return;
        }
        try {
            FileOutputStream output = new FileOutputStream(doubleBufferReportFile, false);
            output.write(report.getBytes(StandardCharsets.UTF_8));
            output.close();
        } catch (IOException error) {
            Log.w(TAG, "double_buffer_report_write_failed", error);
        }
    }

    private File installProbeAsset() throws IOException {
        File script = new File(getFilesDir(), "root-probe.sh");
        InputStream input = getAssets().open("root-probe.sh");
        FileOutputStream output = new FileOutputStream(script);
        byte[] buffer = new byte[4096];
        int count;
        while ((count = input.read(buffer)) != -1) {
            output.write(buffer, 0, count);
        }
        output.close();
        input.close();
        script.setReadable(true, false);
        script.setExecutable(true, false);
        return script;
    }

    private static String readFile(File file) throws IOException {
        if (!file.exists()) {
            return "report_missing=" + file.getAbsolutePath();
        }
        FileInputStream input = new FileInputStream(file);
        String result = readAll(input);
        input.close();
        return result;
    }

    private static String readAll(InputStream input) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[4096];
        int count;
        while ((count = input.read(buffer)) != -1) {
            output.write(buffer, 0, count);
        }
        return output.toString(StandardCharsets.UTF_8.name()).trim();
    }

    private static String shellQuote(String value) {
        return "'" + value.replace("'", "'\"'\"'") + "'";
    }

    private static String trimForUi(String value) {
        int max = 2600;
        if (value.length() <= max) {
            return value;
        }
        return value.substring(value.length() - max);
    }

    private static String extractReportLine(String report, String prefix) {
        int start = report.indexOf(prefix);
        if (start < 0) {
            return prefix + "missing";
        }
        int end = report.indexOf('\n', start);
        return report.substring(start, end < 0 ? report.length() : end);
    }

    private TextView statusText(String text) {
        TextView status = new TextView(this);
        status.setText(text);
        status.setTextColor(Color.LTGRAY);
        status.setTextSize(11);
        status.setTypeface(android.graphics.Typeface.MONOSPACE);
        return status;
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }
}
