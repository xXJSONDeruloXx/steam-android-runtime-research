package com.xjsonderulo.steamandroid.novalab;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;

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
        // bash -s assigns the first argument after the option list to $0. The
        // helper expects its action at $1, so provide an explicit script name.
        intent.putExtra(EXTRA_ARGUMENTS, new String[]{
                "-s", "nova-rootless-termux-x11", action,
                Integer.toString(display)
        });
        intent.putExtra(EXTRA_STDIN, script);
        intent.putExtra(EXTRA_WORKDIR, "/data/data/com.termux/files/home");
        intent.putExtra(EXTRA_BACKGROUND, true);
        intent.putExtra(EXTRA_LABEL, "Nova rootless Termux:X11");
        intent.putExtra(EXTRA_DESCRIPTION,
                "Starts or stops Nova's experimental rootless X11 transport.");
        context.startService(intent);
    }
}
