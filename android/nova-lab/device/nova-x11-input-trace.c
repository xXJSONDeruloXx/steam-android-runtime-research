#define _POSIX_C_SOURCE 200809L

#include <X11/Xlib.h>
#include <X11/extensions/XInput2.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static int x11_error_code;

static int
capture_x11_error(Display *display, XErrorEvent *event)
{
    (void)display;
    x11_error_code = event->error_code;
    return 0;
}

static void
print_usage(const char *program)
{
    fprintf(stderr, "usage: %s --xi2-trace SECONDS\n", program);
}

static int
parse_seconds(const char *value, unsigned int *seconds)
{
    char *end = NULL;
    errno = 0;
    unsigned long parsed = strtoul(value, &end, 10);
    if (errno != 0 || end == value || *end != '\0' || parsed == 0 ||
        parsed > 300UL) {
        return 0;
    }
    *seconds = (unsigned int)parsed;
    return 1;
}

static long long
monotonic_milliseconds(void)
{
    struct timespec timestamp;
    if (clock_gettime(CLOCK_MONOTONIC, &timestamp) != 0) {
        return -1;
    }
    return (long long)timestamp.tv_sec * 1000LL +
           (long long)timestamp.tv_nsec / 1000000LL;
}

static const char *
event_name(int event_type)
{
    switch (event_type) {
    case XI_TouchBegin:
        return "touch_begin";
    case XI_TouchUpdate:
        return "touch_update";
    case XI_TouchEnd:
        return "touch_end";
    case XI_ButtonPress:
        return "button_press";
    case XI_ButtonRelease:
        return "button_release";
    case XI_Motion:
        return "motion";
    default:
        return "other";
    }
}

static unsigned long
trace_events(Display *display, Window root, int xi_opcode,
             unsigned int seconds)
{
    unsigned char selected_events[(XI_LASTEVENT + 7) / 8] = {0};
    XISetMask(selected_events, XI_TouchBegin);
    XISetMask(selected_events, XI_TouchUpdate);
    XISetMask(selected_events, XI_TouchEnd);
    XISetMask(selected_events, XI_ButtonPress);
    XISetMask(selected_events, XI_ButtonRelease);
    XISetMask(selected_events, XI_Motion);

    XIEventMask event_mask = {
        .deviceid = XIAllMasterDevices,
        .mask_len = (int)sizeof(selected_events),
        .mask = selected_events,
    };
    x11_error_code = 0;
    XErrorHandler previous_error_handler =
        XSetErrorHandler(capture_x11_error);
    XISelectEvents(display, root, &event_mask, 1);
    XSync(display, False);
    XSetErrorHandler(previous_error_handler);
    if (x11_error_code != 0) {
        fprintf(stderr, "nova_xi2_select=fail error_code=%d\n",
                x11_error_code);
        return 0;
    }
    printf("nova_xi2_select=pass root=0x%lx opcode=%d\n",
           (unsigned long)root, xi_opcode);
    fflush(stdout);

    const unsigned int interval_milliseconds = 50;
    const unsigned int sample_count =
        (seconds * 1000U) / interval_milliseconds;
    unsigned int observed_samples = 0;
    unsigned long observed_events = 0;
    long long start_milliseconds = monotonic_milliseconds();
    for (unsigned int index = 0; index < sample_count; ++index) {
        while (XPending(display) > 0) {
            XEvent event;
            XNextEvent(display, &event);
            if (event.type != GenericEvent ||
                event.xcookie.extension != xi_opcode ||
                !XGetEventData(display, &event.xcookie)) {
                continue;
            }
            if (event.xcookie.evtype == XI_TouchBegin ||
                event.xcookie.evtype == XI_TouchUpdate ||
                event.xcookie.evtype == XI_TouchEnd ||
                event.xcookie.evtype == XI_ButtonPress ||
                event.xcookie.evtype == XI_ButtonRelease ||
                event.xcookie.evtype == XI_Motion) {
                XIDeviceEvent *device_event =
                    (XIDeviceEvent *)event.xcookie.data;
                long long elapsed_milliseconds = monotonic_milliseconds();
                if (elapsed_milliseconds >= 0 && start_milliseconds >= 0) {
                    elapsed_milliseconds -= start_milliseconds;
                }
                printf("nova_xi2_event elapsed_ms=%lld type=%s evtype=%d "
                       "device=%d source=%d detail=%u root_x=%.3f "
                       "root_y=%.3f event_x=%.3f event_y=%.3f flags=0x%x\n",
                       elapsed_milliseconds,
                       event_name(event.xcookie.evtype),
                       event.xcookie.evtype, device_event->deviceid,
                       device_event->sourceid, device_event->detail,
                       device_event->root_x, device_event->root_y,
                       device_event->event_x, device_event->event_y,
                       device_event->flags);
                fflush(stdout);
                ++observed_events;
            }
            XFreeEventData(display, &event.xcookie);
        }
        ++observed_samples;
        struct timespec delay = {
            .tv_sec = 0,
            .tv_nsec = (long)interval_milliseconds * 1000000L,
        };
        while (nanosleep(&delay, &delay) != 0 && errno == EINTR) {
        }
    }
    printf("nova_xi2_trace=pass seconds=%u samples=%u events=%lu\n",
           seconds, observed_samples, observed_events);
    return observed_samples == sample_count;
}

int
main(int argc, char **argv)
{
    unsigned int seconds = 0;
    if (argc == 3 && strcmp(argv[1], "--xi2-trace") == 0) {
        if (!parse_seconds(argv[2], &seconds)) {
            fprintf(stderr, "invalid trace seconds: %s\n", argv[2]);
            return 2;
        }
    } else if (argc == 2 && strcmp(argv[1], "--help") == 0) {
        print_usage(argv[0]);
        return 0;
    } else {
        print_usage(argv[0]);
        return 2;
    }

    Display *display = XOpenDisplay(NULL);
    if (display == NULL) {
        fprintf(stderr, "nova_xi2_display=fail errno=%d\n", errno);
        return 1;
    }
    int event_base = 0;
    int error_base = 0;
    int xi_opcode = 0;
    if (!XQueryExtension(display, "XInputExtension", &xi_opcode,
                         &event_base, &error_base)) {
        fprintf(stderr, "nova_xi2_extension=fail reason=missing\n");
        XCloseDisplay(display);
        return 1;
    }
    int major = 2;
    int minor = 0;
    int query_status = XIQueryVersion(display, &major, &minor);
    if (query_status != Success) {
        fprintf(stderr, "nova_xi2_extension=fail reason=version status=%d\n",
                query_status);
        XCloseDisplay(display);
        return 1;
    }
    Window root = RootWindow(display, DefaultScreen(display));
    printf("nova_xi2_extension=pass opcode=%d event_base=%d version=%d.%d "
           "root=0x%lx\n",
           xi_opcode, event_base, major, minor, (unsigned long)root);
    fflush(stdout);
    int success = trace_events(display, root, xi_opcode, seconds);
    XCloseDisplay(display);
    return success ? 0 : 1;
}
