#define _GNU_SOURCE

#include <dlfcn.h>
#include <endian.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

/* Keep this shim independent of the ALSA development headers. The opaque
 * handle and enum ABI used by libasound are stable integer/pointer types, and
 * the disposable Holo rootfs contains the runtime library but not asoundlib.h. */
typedef struct _snd_pcm snd_pcm_t;
typedef long snd_pcm_sframes_t;
typedef unsigned long snd_pcm_uframes_t;
typedef int snd_pcm_stream_t;
typedef int snd_pcm_format_t;
typedef int snd_pcm_access_t;

enum {
    NOVA_SND_PCM_STREAM_PLAYBACK = 0,
    NOVA_SND_PCM_FORMAT_S16_LE = 2,
    NOVA_AUDIO_HEADER_BYTES = 16,
    NOVA_AUDIO_SAMPLE_RATE = 48000,
    NOVA_AUDIO_CHANNELS = 2,
    NOVA_AUDIO_FORMAT_S16_LE = 1
};

typedef int (*snd_pcm_open_fn)(snd_pcm_t **, const char *, snd_pcm_stream_t, int);
typedef int (*snd_pcm_set_params_fn)(snd_pcm_t *, snd_pcm_format_t,
                                     snd_pcm_access_t, unsigned int, unsigned int,
                                     int, unsigned int);
typedef snd_pcm_sframes_t (*snd_pcm_writei_fn)(snd_pcm_t *, const void *,
                                               snd_pcm_uframes_t);
typedef int (*snd_pcm_close_fn)(snd_pcm_t *);

struct nova_pcm_state {
    snd_pcm_t *handle;
    snd_pcm_stream_t stream;
    snd_pcm_format_t format;
    unsigned int channels;
    unsigned int rate;
    int socket_fd;
    int header_sent;
    struct nova_pcm_state *next;
};

static pthread_mutex_t state_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t bridge_log_mutex = PTHREAD_MUTEX_INITIALIZER;
static struct nova_pcm_state *states;
static int bridge_log_fd = -2;

static snd_pcm_open_fn real_snd_pcm_open;
static snd_pcm_set_params_fn real_snd_pcm_set_params;
static snd_pcm_writei_fn real_snd_pcm_writei;
static snd_pcm_close_fn real_snd_pcm_close;

static int bridge_enabled(void)
{
    const char *value = getenv("NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE");
    return value != NULL && value[0] == '1' && value[1] == '\0';
}

static unsigned int bridge_port(void)
{
    const char *value = getenv("NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE_PORT");
    char *end = NULL;
    unsigned long port;

    if (value == NULL || value[0] == '\0') {
        return 29100;
    }
    errno = 0;
    port = strtoul(value, &end, 10);
    if (errno != 0 || end == value || *end != '\0' || port < 1024 || port > 65535) {
        return 29100;
    }
    return (unsigned int)port;
}

static void bridge_log(const char *event, long value)
{
    char line[256];
    int length = snprintf(line, sizeof(line),
                          "nova_alsa_audiotrack_bridge event=%s value=%ld errno=%d\n",
                          event, value, errno);
    if (length > 0) {
        if (length >= (int)sizeof(line)) {
            length = (int)sizeof(line) - 1;
        }
        (void)write(STDERR_FILENO, line, (size_t)length);
        pthread_mutex_lock(&bridge_log_mutex);
        if (bridge_log_fd == -2) {
            const char *path = getenv("NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE_LOG");
            if (path != NULL && path[0] != '\0') {
                bridge_log_fd = open(path, O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC,
                                     0644);
            } else {
                bridge_log_fd = -1;
            }
        }
        if (bridge_log_fd >= 0) {
            (void)write(bridge_log_fd, line, (size_t)length);
        }
        pthread_mutex_unlock(&bridge_log_mutex);
    }
}

static void resolve_functions(void)
{
    if (real_snd_pcm_open == NULL) {
        real_snd_pcm_open = (snd_pcm_open_fn)dlsym(RTLD_NEXT, "snd_pcm_open");
    }
    if (real_snd_pcm_set_params == NULL) {
        real_snd_pcm_set_params =
            (snd_pcm_set_params_fn)dlsym(RTLD_NEXT, "snd_pcm_set_params");
    }
    if (real_snd_pcm_writei == NULL) {
        real_snd_pcm_writei =
            (snd_pcm_writei_fn)dlsym(RTLD_NEXT, "snd_pcm_writei");
    }
    if (real_snd_pcm_close == NULL) {
        real_snd_pcm_close = (snd_pcm_close_fn)dlsym(RTLD_NEXT, "snd_pcm_close");
    }
}

static struct nova_pcm_state *find_state_locked(snd_pcm_t *handle)
{
    struct nova_pcm_state *state;
    for (state = states; state != NULL; state = state->next) {
        if (state->handle == handle) {
            return state;
        }
    }
    return NULL;
}

static int send_all(int fd, const void *payload, size_t length, size_t *sent_out)
{
    const unsigned char *bytes = (const unsigned char *)payload;
    size_t sent = 0;

    if (sent_out != NULL) {
        *sent_out = 0;
    }
    while (sent < length) {
        ssize_t result = send(fd, bytes + sent, length - sent, MSG_NOSIGNAL);
        if (result < 0 && errno == EINTR) {
            continue;
        }
        if (result <= 0) {
            if (sent_out != NULL) {
                *sent_out = sent;
            }
            return -1;
        }
        sent += (size_t)result;
    }
    if (sent_out != NULL) {
        *sent_out = sent;
    }
    return 0;
}

static int connect_audio_endpoint(struct nova_pcm_state *state)
{
    struct sockaddr_in address;
    unsigned int port = bridge_port();
    int fd;
    struct timeval timeout = {.tv_sec = 1, .tv_usec = 0};

    fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) {
        return -1;
    }
    (void)setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_port = htons((uint16_t)port);
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (connect(fd, (const struct sockaddr *)&address, sizeof(address)) < 0) {
        int error_number = errno;
        close(fd);
        errno = error_number;
        return -1;
    }
    state->socket_fd = fd;
    state->header_sent = 0;
    bridge_log("connected", (long)port);
    return 0;
}

static int send_header(struct nova_pcm_state *state)
{
    unsigned char header[NOVA_AUDIO_HEADER_BYTES] = {
        'N', 'O', 'V', 'A', 'P', 'C', 'M', '1'
    };
    uint32_t rate = htole32(state->rate == 0 ? NOVA_AUDIO_SAMPLE_RATE : state->rate);
    uint16_t channels = htole16((uint16_t)(state->channels == 0
                                               ? NOVA_AUDIO_CHANNELS
                                               : state->channels));
    uint16_t format = htole16(NOVA_AUDIO_FORMAT_S16_LE);

    memcpy(header + 8, &rate, sizeof(rate));
    memcpy(header + 12, &channels, sizeof(channels));
    memcpy(header + 14, &format, sizeof(format));
    if (send_all(state->socket_fd, header, sizeof(header), NULL) < 0) {
        return -1;
    }
    state->header_sent = 1;
    bridge_log("header_sent", (long)state->rate);
    return 0;
}

static void close_bridge_socket(struct nova_pcm_state *state)
{
    if (state->socket_fd >= 0) {
        close(state->socket_fd);
        state->socket_fd = -1;
    }
    state->header_sent = 0;
}

int snd_pcm_open(snd_pcm_t **handle, const char *name,
                 snd_pcm_stream_t stream, int mode)
{
    struct nova_pcm_state *state;
    int result;

    resolve_functions();
    if (real_snd_pcm_open == NULL) {
        errno = ENOSYS;
        return -1;
    }
    result = real_snd_pcm_open(handle, name, stream, mode);
    if (result < 0 || !bridge_enabled() || stream != NOVA_SND_PCM_STREAM_PLAYBACK) {
        return result;
    }
    state = calloc(1, sizeof(*state));
    if (state == NULL) {
        return result;
    }
    state->handle = *handle;
    state->stream = stream;
    state->format = NOVA_SND_PCM_FORMAT_S16_LE;
    state->channels = NOVA_AUDIO_CHANNELS;
    state->rate = NOVA_AUDIO_SAMPLE_RATE;
    state->socket_fd = -1;
    pthread_mutex_lock(&state_mutex);
    state->next = states;
    states = state;
    pthread_mutex_unlock(&state_mutex);
    bridge_log("pcm_open", 0);
    return result;
}

int snd_pcm_set_params(snd_pcm_t *handle, snd_pcm_format_t format,
                       snd_pcm_access_t access, unsigned int channels,
                       unsigned int rate, int soft_resample, unsigned int latency)
{
    struct nova_pcm_state *state;
    int result;

    resolve_functions();
    if (real_snd_pcm_set_params == NULL) {
        errno = ENOSYS;
        return -1;
    }
    result = real_snd_pcm_set_params(handle, format, access, channels, rate,
                                     soft_resample, latency);
    if (result < 0 || !bridge_enabled()) {
        return result;
    }
    pthread_mutex_lock(&state_mutex);
    state = find_state_locked(handle);
    if (state != NULL) {
        state->format = format;
        state->channels = channels;
        state->rate = rate;
    }
    pthread_mutex_unlock(&state_mutex);
    return result;
}

snd_pcm_sframes_t snd_pcm_writei(snd_pcm_t *handle, const void *buffer,
                                 snd_pcm_uframes_t frames)
{
    struct nova_pcm_state *state;
    snd_pcm_sframes_t result;
    size_t bytes;
    size_t sent_bytes = 0;

    resolve_functions();
    if (real_snd_pcm_writei == NULL) {
        errno = ENOSYS;
        return -1;
    }
    if (!bridge_enabled()) {
        return real_snd_pcm_writei(handle, buffer, frames);
    }
    pthread_mutex_lock(&state_mutex);
    state = find_state_locked(handle);
    if (state != NULL && (state->format != NOVA_SND_PCM_FORMAT_S16_LE ||
                          state->channels != NOVA_AUDIO_CHANNELS ||
                          state->rate != NOVA_AUDIO_SAMPLE_RATE)) {
        state = NULL;
    }
    pthread_mutex_unlock(&state_mutex);
    if (state == NULL) {
        return real_snd_pcm_writei(handle, buffer, frames);
    }
    if (state->socket_fd < 0 && connect_audio_endpoint(state) < 0) {
        bridge_log("connect_failed_fallback", -1);
        return real_snd_pcm_writei(handle, buffer, frames);
    }
    if (!state->header_sent && send_header(state) < 0) {
        bridge_log("header_failed", -1);
        close_bridge_socket(state);
        return -EPIPE;
    }
    if (frames > (SIZE_MAX / (NOVA_AUDIO_CHANNELS * sizeof(int16_t)))) {
        close_bridge_socket(state);
        errno = EOVERFLOW;
        return -EOVERFLOW;
    }
    bytes = (size_t)frames * NOVA_AUDIO_CHANNELS * sizeof(int16_t);
    bridge_log("pcm_frames_attempted", (long)frames);
    if (send_all(state->socket_fd, buffer, bytes, &sent_bytes) < 0) {
        bridge_log("pcm_send_failed_bytes", (long)sent_bytes);
        close_bridge_socket(state);
        return -EPIPE;
    }
    result = (snd_pcm_sframes_t)frames;
    bridge_log("pcm_frames_sent", (long)result);
    return result;
}

int snd_pcm_close(snd_pcm_t *handle)
{
    struct nova_pcm_state *state;
    struct nova_pcm_state **cursor;
    int result;

    resolve_functions();
    if (real_snd_pcm_close == NULL) {
        errno = ENOSYS;
        return -1;
    }
    pthread_mutex_lock(&state_mutex);
    cursor = &states;
    state = NULL;
    while (*cursor != NULL) {
        if ((*cursor)->handle == handle) {
            state = *cursor;
            *cursor = state->next;
            break;
        }
        cursor = &(*cursor)->next;
    }
    pthread_mutex_unlock(&state_mutex);
    if (state != NULL) {
        close_bridge_socket(state);
        bridge_log("pcm_close", 0);
        free(state);
    }
    result = real_snd_pcm_close(handle);
    return result;
}
