#define _GNU_SOURCE

#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <unistd.h>

enum {
    request_magic = 0x4e425750,
    request_limit = 131072,
    fd_limit = 128,
    saved_fd_base = 2048,
    request_header_words = 5,
};

struct request {
    unsigned char *payload;
    size_t payload_size;
    int received[fd_limit];
    uint32_t original[fd_limit];
    size_t fd_count;
    size_t argument_count;
    size_t environment_count;
};

static volatile sig_atomic_t active_child = -1;
static volatile sig_atomic_t stop_requested = 0;

static void terminate_child(int signal_number)
{
    (void)signal_number;
    stop_requested = 1;
    if (active_child > 0)
        kill((pid_t)active_child, SIGKILL);
}

static int send_status(int fd, int status)
{
    uint32_t encoded = htonl((uint32_t)status);
    const unsigned char *data = (const unsigned char *)&encoded;
    size_t sent = 0;

    while (sent < sizeof(encoded)) {
        ssize_t result = send(fd, data + sent, sizeof(encoded) - sent, MSG_NOSIGNAL);
        if (result < 0) {
            if (errno == EINTR)
                continue;
            return -1;
        }
        if (result == 0)
            return -1;
        sent += (size_t)result;
    }
    return 0;
}

static int receive_request(int fd, struct request *request)
{
    struct msghdr message = {0};
    struct iovec vector = {0};
    unsigned char control[CMSG_SPACE(sizeof(int) * fd_limit)] = {0};
    unsigned char *buffer = calloc(1, request_limit);
    if (buffer == NULL)
        return -1;

    vector.iov_base = buffer;
    vector.iov_len = request_limit;
    message.msg_iov = &vector;
    message.msg_iovlen = 1;
    message.msg_control = control;
    message.msg_controllen = sizeof(control);

    ssize_t received = recvmsg(fd, &message, 0);
    if (received <= 0) {
        free(buffer);
        return received == 0 ? 1 : -1;
    }
    size_t header_size = sizeof(uint32_t) * request_header_words;
    if ((message.msg_flags & MSG_TRUNC) != 0 ||
        (size_t)received < header_size) {
        free(buffer);
        return -1;
    }

    uint32_t magic;
    uint32_t payload_size;
    uint32_t fd_count;
    uint32_t argument_count;
    uint32_t environment_count;
    memcpy(&magic, buffer, sizeof(magic));
    memcpy(&payload_size, buffer + sizeof(magic), sizeof(payload_size));
    memcpy(&fd_count, buffer + sizeof(magic) * 2, sizeof(fd_count));
    memcpy(&argument_count, buffer + sizeof(magic) * 3, sizeof(argument_count));
    memcpy(&environment_count, buffer + sizeof(magic) * 4,
           sizeof(environment_count));
    magic = ntohl(magic);
    payload_size = ntohl(payload_size);
    fd_count = ntohl(fd_count);
    argument_count = ntohl(argument_count);
    environment_count = ntohl(environment_count);

    size_t fd_table_size = (size_t)fd_count * sizeof(uint32_t);
    if (magic != request_magic || fd_count > fd_limit ||
        argument_count == 0 ||
        (size_t)received < header_size + (size_t)payload_size + fd_table_size ||
        payload_size == 0) {
        free(buffer);
        return -1;
    }

    size_t ancillary_count = 0;
    for (struct cmsghdr *header = CMSG_FIRSTHDR(&message); header != NULL;
         header = CMSG_NXTHDR(&message, header)) {
        if (header->cmsg_level != SOL_SOCKET || header->cmsg_type != SCM_RIGHTS)
            continue;
        size_t bytes = header->cmsg_len - CMSG_LEN(0);
        size_t count = bytes / sizeof(int);
        if (ancillary_count + count > fd_limit) {
            free(buffer);
            return -1;
        }
        memcpy(request->received + ancillary_count, CMSG_DATA(header),
               count * sizeof(int));
        ancillary_count += count;
    }
    if (ancillary_count != fd_count) {
        free(buffer);
        return -1;
    }

    const unsigned char *table = buffer + header_size + payload_size;
    for (size_t index = 0; index < fd_count; index++) {
        uint32_t original;
        memcpy(&original, table + index * sizeof(original), sizeof(original));
        request->original[index] = ntohl(original);
    }

    request->payload = buffer + header_size;
    request->payload_size = payload_size;
    request->fd_count = fd_count;
    request->argument_count = argument_count;
    request->environment_count = environment_count;
    return 0;
}

static void close_received_fds(struct request *request)
{
    for (size_t index = 0; index < request->fd_count; index++) {
        if (request->received[index] >= 0)
            close(request->received[index]);
        request->received[index] = -1;
    }
}

static int build_argv(unsigned char *payload, size_t payload_size,
                      size_t argument_count, size_t environment_count,
                      char ***result, unsigned char **environment)
{
    unsigned char *cursor = payload;
    unsigned char *end = payload + payload_size;
    if (argument_count == 0)
        return -1;

    char **argv = calloc(argument_count + 1, sizeof(*argv));
    if (argv == NULL)
        return -1;

    for (size_t index = 0; index < argument_count; index++) {
        if (cursor >= end)
            goto invalid;
        unsigned char *terminator = memchr(cursor, '\0', (size_t)(end - cursor));
        if (terminator == NULL)
            goto invalid;
        argv[index] = (char *)cursor;
        cursor = terminator + 1;
    }
    for (size_t index = 0; index < environment_count; index++) {
        if (cursor >= end)
            goto invalid;
        unsigned char *terminator = memchr(cursor, '\0', (size_t)(end - cursor));
        if (terminator == NULL)
            goto invalid;
        if (memchr(cursor, '=', (size_t)(terminator - cursor)) == NULL)
            goto invalid;
        cursor = terminator + 1;
    }
    if (cursor != end)
        goto invalid;

    argv[argument_count] = NULL;
    *result = argv;
    cursor = payload;
    for (size_t index = 0; index < argument_count; index++) {
        unsigned char *terminator = memchr(cursor, '\0', (size_t)(end - cursor));
        cursor = terminator + 1;
    }
    *environment = cursor;
    return 0;

invalid:
    free(argv);
    return -1;
}

static int run_request(struct request *request)
{
    char **argv = NULL;
    unsigned char *environment = NULL;
    if (build_argv(request->payload, request->payload_size,
                   request->argument_count, request->environment_count,
                   &argv, &environment) != 0)
        return 125;

    pid_t child = fork();
    if (child < 0) {
        free(argv);
        return 125;
    }
    if (child == 0) {
        prctl(PR_SET_PDEATHSIG, SIGKILL);

        if (clearenv() != 0)
            _exit(125);
        unsigned char *environment_cursor = environment;
        for (size_t index = 0; index < request->environment_count; index++) {
            char *entry = (char *)environment_cursor;
            char *equals = strchr(entry, '=');
            if (equals == NULL || equals == entry) {
                dprintf(STDERR_FILENO, "root_bwrap_proxy_invalid_environment\\n");
                _exit(125);
            }
            *equals = '\0';
            int environment_status = setenv(entry, equals + 1, 1);
            *equals = '=';
            if (environment_status != 0) {
                dprintf(STDERR_FILENO, "root_bwrap_proxy_setenv_failed key=%s\\n", entry);
                _exit(125);
            }
            environment_cursor = (unsigned char *)equals +
                strlen(equals + 1) + 2;
        }

        int saved[fd_limit];
        for (size_t index = 0; index < request->fd_count; index++) {
            saved[index] = fcntl(request->received[index], F_DUPFD, saved_fd_base + (int)index);
            if (saved[index] < 0) {
                dprintf(STDERR_FILENO, "root_bwrap_proxy_dup_failed fd=%d errno=%d\\n",
                        request->received[index], errno);
                _exit(125);
            }
        }
        for (size_t index = 0; index < request->fd_count; index++) {
            if (request->original[index] > 1048576U ||
                dup2(saved[index], (int)request->original[index]) < 0) {
                dprintf(STDERR_FILENO, "root_bwrap_proxy_restore_failed original=%u errno=%d\\n",
                        request->original[index], errno);
                _exit(125);
            }
            int flags = fcntl((int)request->original[index], F_GETFD);
            if (flags >= 0)
                fcntl((int)request->original[index], F_SETFD, flags & ~FD_CLOEXEC);
        }
        for (size_t index = 0; index < request->fd_count; index++) {
            close(saved[index]);
            int is_target = 0;
            for (size_t target = 0; target < request->fd_count; target++) {
                if (request->received[index] ==
                    (int)request->original[target]) {
                    is_target = 1;
                    break;
                }
            }
            if (!is_target)
                close(request->received[index]);
        }
        execv(argv[0], argv);
        dprintf(STDERR_FILENO, "root_bwrap_proxy_exec_failed path=%s errno=%d\\n",
                argv[0], errno);
        _exit(127);
    }

    active_child = child;
    close_received_fds(request);
    int status = 125;
    if (waitpid(child, &status, 0) < 0)
        status = 125;
    active_child = -1;
    free(argv);
    if (WIFEXITED(status))
        return WEXITSTATUS(status);
    if (WIFSIGNALED(status))
        return 128 + WTERMSIG(status);
    return 125;
}

int main(int argc, char **argv)
{
    if (argc != 3) {
        fprintf(stderr, "usage: %s ROOT SOCKET\n", argv[0]);
        return 2;
    }
    if (chroot(argv[1]) != 0 || chdir("/") != 0) {
        perror("root_bwrap_proxy_chroot");
        return 1;
    }

    struct sockaddr_un address = {0};
    address.sun_family = AF_UNIX;
    if (strlen(argv[2]) >= sizeof(address.sun_path)) {
        fprintf(stderr, "root_bwrap_proxy_socket_too_long\n");
        return 1;
    }
    strcpy(address.sun_path, argv[2]);
    unlink(address.sun_path);

    int server = socket(AF_UNIX, SOCK_STREAM, 0);
    if (server < 0) {
        perror("root_bwrap_proxy_socket");
        return 1;
    }
    if (bind(server, (struct sockaddr *)&address, sizeof(address)) != 0 ||
        chmod(address.sun_path, 0666) != 0 || listen(server, 4) != 0) {
        perror("root_bwrap_proxy_bind");
        close(server);
        return 1;
    }

    struct sigaction action = {0};
    action.sa_handler = terminate_child;
    sigemptyset(&action.sa_mask);
    sigaction(SIGTERM, &action, NULL);
    sigaction(SIGINT, &action, NULL);

    printf("root_bwrap_proxy_ready socket=%s\n", address.sun_path);
    fflush(stdout);
    for (;;) {
        int client = accept(server, NULL, NULL);
        if (client < 0) {
            if (errno == EINTR && !stop_requested)
                continue;
            break;
        }
        struct request request = {0};
        for (size_t index = 0; index < fd_limit; index++)
            request.received[index] = -1;
        int receive_status = receive_request(client, &request);
        if (receive_status != 0)
            dprintf(STDERR_FILENO, "root_bwrap_proxy_receive_failed status=%d\\n",
                    receive_status);
        int result = receive_status == 0 ? run_request(&request) : 125;
        close_received_fds(&request);
        if (request.payload != NULL)
            free(request.payload - sizeof(uint32_t) * request_header_words);
        send_status(client, result);
        close(client);
        if (stop_requested)
            break;
    }
    close(server);
    unlink(address.sun_path);
    return 0;
}
