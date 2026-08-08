#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include <errno.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct window_capture {
    Window window;
    const char *path;
};

static int x11_capture_error_code;

static int
capture_x11_error(Display *display, XErrorEvent *event)
{
    (void)display;
    x11_capture_error_code = event->error_code;
    return 0;
}

static void
print_usage(const char *program)
{
    fprintf(stderr,
            "usage: %s [--tree] [--root-ppm PATH] "
            "[--window-ppm WINDOW_ID PATH]...\n",
            program);
}

static int
parse_window_id(const char *value, Window *window)
{
    char *end = NULL;
    errno = 0;
    unsigned long long parsed = strtoull(value, &end, 0);
    if (errno != 0 || end == value || *end != '\0' || parsed == 0 ||
        parsed > (unsigned long long)ULONG_MAX) {
        return 0;
    }
    *window = (Window)parsed;
    return 1;
}

static void
print_escaped(const char *value)
{
    if (value == NULL) {
        fputs("<none>", stdout);
        return;
    }
    for (const unsigned char *cursor = (const unsigned char *)value;
         *cursor != '\0'; ++cursor) {
        if (*cursor == '\\' || *cursor == '"') {
            fputc('\\', stdout);
        }
        if (*cursor >= 0x20 && *cursor <= 0x7e) {
            fputc(*cursor, stdout);
        } else {
            fputc('?', stdout);
        }
    }
}

static const char *
map_state_name(int map_state)
{
    switch (map_state) {
    case IsUnmapped:
        return "unmapped";
    case IsUnviewable:
        return "unviewable";
    case IsViewable:
        return "viewable";
    default:
        return "unknown";
    }
}

static void
print_window(Display *display, Window window, Window parent, unsigned int depth)
{
    XWindowAttributes attributes;
    if (!XGetWindowAttributes(display, window, &attributes)) {
        fprintf(stderr, "nova_x11_window_attributes=failed id=0x%lx\n",
                (unsigned long)window);
        return;
    }

    Window child = None;
    int root_x = 0;
    int root_y = 0;
    if (!XTranslateCoordinates(display, window,
                               RootWindow(display, DefaultScreen(display)),
                               0, 0, &root_x, &root_y, &child)) {
        root_x = attributes.x;
        root_y = attributes.y;
    }

    char *name = NULL;
    XFetchName(display, window, &name);
    XClassHint class_hint = {0};
    if (!XGetClassHint(display, window, &class_hint)) {
        class_hint.res_name = NULL;
        class_hint.res_class = NULL;
    }

    printf("nova_x11_window id=0x%lx parent=0x%lx depth=%u map_state=%s "
           "x=%d y=%d width=%d height=%d border=%d name=\"",
           (unsigned long)window, (unsigned long)parent, depth,
           map_state_name(attributes.map_state), root_x, root_y,
           attributes.width, attributes.height, attributes.border_width);
    print_escaped(name);
    fputs("\" res_name=\"", stdout);
    print_escaped(class_hint.res_name);
    fputs("\" res_class=\"", stdout);
    print_escaped(class_hint.res_class);
    fputs("\"\n", stdout);

    if (name != NULL) {
        XFree(name);
    }
    if (class_hint.res_name != NULL) {
        XFree(class_hint.res_name);
    }
    if (class_hint.res_class != NULL) {
        XFree(class_hint.res_class);
    }

    Window root = None;
    Window returned_parent = None;
    Window *children = NULL;
    unsigned int child_count = 0;
    if (!XQueryTree(display, window, &root, &returned_parent, &children,
                    &child_count)) {
        fprintf(stderr, "nova_x11_query_tree=failed id=0x%lx\n",
                (unsigned long)window);
        return;
    }
    for (unsigned int index = 0; index < child_count; ++index) {
        print_window(display, children[index], window, depth + 1);
    }
    if (children != NULL) {
        XFree(children);
    }
}

static unsigned char
scale_component(unsigned long pixel, unsigned long mask)
{
    if (mask == 0) {
        return 0;
    }
    unsigned int shift = 0;
    while (shift < sizeof(mask) * CHAR_BIT &&
           ((mask >> shift) & 1UL) == 0UL) {
        ++shift;
    }
    if (shift == sizeof(mask) * CHAR_BIT) {
        return 0;
    }
    unsigned long maximum = mask >> shift;
    unsigned long value = (pixel & mask) >> shift;
    if (maximum == 0) {
        return 0;
    }
    uint64_t scaled = ((uint64_t)value * 255U + maximum / 2U) / maximum;
    return (unsigned char)(scaled > 255U ? 255U : scaled);
}

static int
write_ppm(Display *display, Window window, const char *path)
{
    XWindowAttributes attributes;
    if (!XGetWindowAttributes(display, window, &attributes)) {
        fprintf(stderr, "nova_x11_capture=failed id=0x%lx reason=attributes\n",
                (unsigned long)window);
        return 0;
    }
    if (attributes.width <= 0 || attributes.height <= 0 ||
        attributes.visual == NULL) {
        fprintf(stderr,
                "nova_x11_capture=failed id=0x%lx reason=geometry_or_visual\n",
                (unsigned long)window);
        return 0;
    }

    x11_capture_error_code = 0;
    XErrorHandler previous_error_handler =
        XSetErrorHandler(capture_x11_error);
    XImage *image = XGetImage(display, window, 0, 0,
                              (unsigned int)attributes.width,
                              (unsigned int)attributes.height,
                              AllPlanes, ZPixmap);
    XSync(display, False);
    XSetErrorHandler(previous_error_handler);
    if (image == NULL || x11_capture_error_code != 0) {
        fprintf(stderr,
                "nova_x11_capture=failed id=0x%lx reason=xgetimage "
                "error_code=%d depth=%d visual=0x%lx\n",
                (unsigned long)window, x11_capture_error_code,
                attributes.depth,
                attributes.visual != NULL
                    ? (unsigned long)XVisualIDFromVisual(attributes.visual)
                    : 0UL);
        if (image != NULL) {
            XDestroyImage(image);
        }
        return 0;
    }

    if ((size_t)attributes.width > SIZE_MAX / 3U) {
        fprintf(stderr, "nova_x11_capture=failed id=0x%lx reason=overflow\n",
                (unsigned long)window);
        XDestroyImage(image);
        return 0;
    }
    size_t row_size = (size_t)attributes.width * 3U;
    unsigned char *row = malloc(row_size);
    if (row == NULL) {
        fprintf(stderr, "nova_x11_capture=failed id=0x%lx reason=malloc\n",
                (unsigned long)window);
        XDestroyImage(image);
        return 0;
    }

    FILE *output = fopen(path, "wb");
    if (output == NULL) {
        fprintf(stderr, "nova_x11_capture=failed id=0x%lx path=%s errno=%d\n",
                (unsigned long)window, path, errno);
        free(row);
        XDestroyImage(image);
        return 0;
    }

    const Visual *visual = attributes.visual;
    int success = fprintf(output, "P6\n%d %d\n255\n", attributes.width,
                          attributes.height) >= 0;
    for (int y = 0; success && y < attributes.height; ++y) {
        for (int x = 0; x < attributes.width; ++x) {
            unsigned long pixel = XGetPixel(image, x, y);
            row[(size_t)x * 3U] =
                scale_component(pixel, visual->red_mask);
            row[(size_t)x * 3U + 1U] =
                scale_component(pixel, visual->green_mask);
            row[(size_t)x * 3U + 2U] =
                scale_component(pixel, visual->blue_mask);
        }
        success = fwrite(row, 1, row_size, output) == row_size;
    }
    if (fclose(output) != 0) {
        success = 0;
    }
    free(row);
    XDestroyImage(image);
    if (!success) {
        fprintf(stderr, "nova_x11_capture=failed id=0x%lx path=%s reason=write\n",
                (unsigned long)window, path);
        return 0;
    }
    printf("nova_x11_capture=pass id=0x%lx path=%s width=%d height=%d\n",
           (unsigned long)window, path, attributes.width, attributes.height);
    return 1;
}

int
main(int argc, char **argv)
{
    int print_tree = 0;
    const char *root_path = NULL;
    struct window_capture captures[32];
    size_t capture_count = 0;

    for (int index = 1; index < argc; ++index) {
        if (strcmp(argv[index], "--tree") == 0) {
            print_tree = 1;
        } else if (strcmp(argv[index], "--root-ppm") == 0 &&
                   index + 1 < argc) {
            root_path = argv[++index];
        } else if (strcmp(argv[index], "--window-ppm") == 0 &&
                   index + 2 < argc && capture_count <
                   sizeof(captures) / sizeof(captures[0])) {
            Window window;
            if (!parse_window_id(argv[index + 1], &window)) {
                fprintf(stderr, "invalid X11 window id: %s\n", argv[index + 1]);
                return 2;
            }
            captures[capture_count++] = (struct window_capture){
                .window = window,
                .path = argv[index + 2],
            };
            index += 2;
        } else if (strcmp(argv[index], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        } else {
            print_usage(argv[0]);
            return 2;
        }
    }

    if (!print_tree && root_path == NULL && capture_count == 0) {
        print_usage(argv[0]);
        return 2;
    }

    Display *display = XOpenDisplay(NULL);
    if (display == NULL) {
        fprintf(stderr, "nova_x11_display=failed errno=%d\n", errno);
        return 1;
    }
    int screen = DefaultScreen(display);
    Window root = RootWindow(display, screen);
    printf("nova_x11_display=pass display=%s screen=%d root=0x%lx\n",
           DisplayString(display), screen, (unsigned long)root);

    int success = 1;
    if (print_tree) {
        print_window(display, root, None, 0);
        printf("nova_x11_tree=pass root=0x%lx\n", (unsigned long)root);
    }
    if (root_path != NULL && !write_ppm(display, root, root_path)) {
        success = 0;
    }
    for (size_t index = 0; index < capture_count; ++index) {
        if (!write_ppm(display, captures[index].window,
                       captures[index].path)) {
            success = 0;
        }
    }
    XCloseDisplay(display);
    return success ? 0 : 1;
}
