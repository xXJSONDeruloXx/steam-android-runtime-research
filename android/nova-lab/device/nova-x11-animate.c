#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static int
positive_argument(const char *value, int fallback, int maximum)
{
    char *end = NULL;
    long parsed = strtol(value, &end, 10);
    if (end == value || *end != '\0' || parsed <= 0 || parsed > maximum) {
        return fallback;
    }
    return (int)parsed;
}

int
main(int argc, char **argv)
{
    int frames = argc > 1 ? positive_argument(argv[1], 30, 2000) : 30;
    int width = argc > 2 ? positive_argument(argv[2], 960, 4096) : 960;
    int height = argc > 3 ? positive_argument(argv[3], 540, 4096) : 540;

    Display *display = XOpenDisplay(NULL);
    if (display == NULL) {
        fprintf(stderr, "nova_x11_display=failed errno=%d\n", errno);
        return 1;
    }

    int screen = DefaultScreen(display);
    Window root = RootWindow(display, screen);
    Window window = XCreateSimpleWindow(display, root, 0, 0,
                                        (unsigned int)width,
                                        (unsigned int)height, 0,
                                        BlackPixel(display, screen),
                                        WhitePixel(display, screen));
    if (window == 0) {
        fprintf(stderr, "nova_x11_window=failed\n");
        XCloseDisplay(display);
        return 1;
    }

    XSelectInput(display, window, ExposureMask | StructureNotifyMask);
    XStoreName(display, window, "Nova animated Xwayland Gamescope probe");
    XMapWindow(display, window);
    XFlush(display);

    int mapped = 0;
    for (int attempt = 0; attempt < 100 && !mapped; ++attempt) {
        while (XPending(display) > 0) {
            XEvent event;
            XNextEvent(display, &event);
            if (event.type == MapNotify && event.xmap.window == window) {
                mapped = 1;
            }
        }
        if (!mapped) {
            usleep(10000);
        }
    }
    if (!mapped) {
        fprintf(stderr, "nova_x11_map=timeout\n");
        XDestroyWindow(display, window);
        XCloseDisplay(display);
        return 1;
    }

    GC graphics = XCreateGC(display, window, 0, NULL);
    if (graphics == NULL) {
        fprintf(stderr, "nova_x11_gc=failed\n");
        XDestroyWindow(display, window);
        XCloseDisplay(display);
        return 1;
    }

    static const unsigned long colors[] = {
        0x164e63, 0x7e22ce, 0xbe123c, 0xa16207,
        0x166534, 0x1d4ed8, 0x9f1239, 0x0f766e,
    };
    size_t color_count = sizeof(colors) / sizeof(colors[0]);
    for (int frame = 0; frame < frames; ++frame) {
        XSetForeground(display, graphics, colors[frame % color_count]);
        XFillRectangle(display, window, graphics, 0, 0,
                       (unsigned int)width, (unsigned int)height);
        XSetForeground(display, graphics, WhitePixel(display, screen));
        XFillRectangle(display, window, graphics,
                       (frame * 17) % (width > 64 ? width - 64 : 1),
                       (frame * 11) % (height > 64 ? height - 64 : 1),
                       64, 64);
        XFlush(display);
        XSync(display, False);
        usleep(16000);
    }

    XFreeGC(display, graphics);
    XDestroyWindow(display, window);
    XCloseDisplay(display);
    fprintf(stderr, "nova_x11_frames=%d\n", frames);
    return 0;
}
