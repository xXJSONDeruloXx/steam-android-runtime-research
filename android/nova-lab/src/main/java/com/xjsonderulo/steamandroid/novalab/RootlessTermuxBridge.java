package com.xjsonderulo.steamandroid.novalab;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

/** Sends only the rootless X11 helper to the user-owned Termux app. */
final class RootlessTermuxBridge {
    static final String TERMUX_PACKAGE = "com.termux";
    private static final String RUN_COMMAND_SERVICE =
            "com.termux.app.RunCommandService";
    private static final String ACTION_RUN_COMMAND = "com.termux.RUN_COMMAND";
    private static final String EXTRA_COMMAND_PATH = "com.termux.RUN_COMMAND_PATH";
    private static final String EXTRA_ARGUMENTS = "com.termux.RUN_COMMAND_ARGUMENTS";
    private static final String EXTRA_STDIN = "com.termux.RUN_COMMAND_STDIN";
    private static final String EXTRA_WORKDIR = "com.termux.RUN_COMMAND_WORKDIR";
    private static final String EXTRA_BACKGROUND = "com.termux.RUN_COMMAND_BACKGROUND";
    private static final String EXTRA_BACKGROUND_LOG_LEVEL =
            "com.termux.RUN_COMMAND_BACKGROUND_CUSTOM_LOG_LEVEL";
    private static final String EXTRA_LABEL = "com.termux.RUN_COMMAND_COMMAND_LABEL";
    private static final String EXTRA_DESCRIPTION =
            "com.termux.RUN_COMMAND_COMMAND_DESCRIPTION";

    private RootlessTermuxBridge() {
    }

    static void sendX11Command(Context context, String script, String action, int display) {
        Intent intent = new Intent(ACTION_RUN_COMMAND);
        intent.setComponent(new ComponentName(TERMUX_PACKAGE, RUN_COMMAND_SERVICE));
        intent.putExtra(EXTRA_COMMAND_PATH,
                "/data/data/com.termux/files/usr/bin/bash");
        // Termux AppShell executes the argv array directly. Use bash -c to
        // source the intent stdin; bash -s does not preserve the intended
        // positional arguments under this invocation on the target device.
        intent.putExtra(EXTRA_ARGUMENTS, new String[]{
                "-c", ". /dev/stdin", "nova-rootless-termux-x11", action,
                Integer.toString(display)
        });
        intent.putExtra(EXTRA_STDIN, script);
        intent.putExtra(EXTRA_WORKDIR, "/data/data/com.termux/files/home");
        intent.putExtra(EXTRA_BACKGROUND, true);
        // Termux v0.119 reads this extra with getIntegerExtra(); a string is
        // silently ignored and leaves the diagnostic log level at normal.
        intent.putExtra(EXTRA_BACKGROUND_LOG_LEVEL, 2);
        intent.putExtra(EXTRA_LABEL, "Nova rootless Termux:X11");
        intent.putExtra(EXTRA_DESCRIPTION,
                "Starts or stops Nova's experimental rootless X11 transport.");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent);
        } else {
            context.startService(intent);
        }
    }
}
