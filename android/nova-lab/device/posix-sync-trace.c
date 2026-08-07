#define _GNU_SOURCE

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/eventfd.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/socket.h>
#include <sys/syscall.h>
#include <unistd.h>

static int event_fds[32];
static size_t event_fd_count;

static void trace_result(const char *name, int result, int error_number) {
    char line[256];
    int length = snprintf(
        line,
        sizeof(line),
        "nova_sync_trace %s result=%d errno=%d error=%s\n",
        name,
        result,
        error_number,
        strerror(error_number));
    if (length > 0) {
        if (length >= (int)sizeof(line)) {
            length = (int)sizeof(line) - 1;
        }
        (void)write(STDERR_FILENO, line, (size_t)length);
    }
}

static void trace_failure(const char *name, int result, int error_number) {
    if (result != 0) {
        trace_result(name, result, error_number);
    }
}

static void trace_syscall(long number, long result, int error_number) {
    char line[256];
    int length = snprintf(
        line,
        sizeof(line),
        "nova_sync_trace syscall=%ld result=%ld errno=%d error=%s\n",
        number,
        result,
        error_number,
        strerror(error_number));
    if (length > 0) {
        if (length >= (int)sizeof(line)) {
            length = (int)sizeof(line) - 1;
        }
        (void)write(STDERR_FILENO, line, (size_t)length);
    }
}

int semget(key_t key, int count, int flags) {
    static int (*real_semget)(key_t, int, int);
    if (!real_semget) {
        real_semget = dlsym(RTLD_NEXT, "semget");
    }
    errno = 0;
    int result = real_semget(key, count, flags);
    int error_number = errno;
    trace_result("sysv_semget", result, error_number);
    errno = error_number;
    return result;
}

int semop(int semaphore_id, struct sembuf *operations, size_t count) {
    static int (*real_semop)(int, struct sembuf *, size_t);
    if (!real_semop) {
        real_semop = dlsym(RTLD_NEXT, "semop");
    }
    errno = 0;
    int result = real_semop(semaphore_id, operations, count);
    int error_number = errno;
    trace_result("sysv_semop", result, error_number);
    errno = error_number;
    return result;
}

static int is_event_fd(int file_descriptor) {
    for (size_t index = 0; index < event_fd_count; index++) {
        if (event_fds[index] == file_descriptor) {
            return 1;
        }
    }
    return 0;
}

int sem_init(sem_t *semaphore, int shared, unsigned int value) {
    static int (*real_sem_init)(sem_t *, int, unsigned int);
    if (!real_sem_init) {
        real_sem_init = dlsym(RTLD_NEXT, "sem_init");
    }
    errno = 0;
    int result = real_sem_init(semaphore, shared, value);
    int error_number = errno;
    trace_result("sem_init", result, error_number);
    errno = error_number;
    return result;
}

sem_t *sem_open(const char *name, int flags, ...) {
    static sem_t *(*real_sem_open)(const char *, int, ...);
    if (!real_sem_open) {
        real_sem_open = dlsym(RTLD_NEXT, "sem_open");
    }

    sem_t *result;
    errno = 0;
    if (flags & O_CREAT) {
        va_list arguments;
        va_start(arguments, flags);
        mode_t mode = (mode_t)va_arg(arguments, int);
        unsigned int value = va_arg(arguments, unsigned int);
        va_end(arguments);
        result = real_sem_open(name, flags, mode, value);
    } else {
        result = real_sem_open(name, flags);
    }
    int error_number = errno;
    trace_result("sem_open", result == SEM_FAILED ? -1 : 0, error_number);
    errno = error_number;
    return result;
}

int sem_close(sem_t *semaphore) {
    static int (*real_sem_close)(sem_t *);
    if (!real_sem_close) {
        real_sem_close = dlsym(RTLD_NEXT, "sem_close");
    }
    errno = 0;
    int result = real_sem_close(semaphore);
    int error_number = errno;
    trace_result("sem_close", result, error_number);
    errno = error_number;
    return result;
}

int sem_wait(sem_t *semaphore) {
    static int (*real_sem_wait)(sem_t *);
    if (!real_sem_wait) {
        real_sem_wait = dlsym(RTLD_NEXT, "sem_wait");
    }
    errno = 0;
    int result = real_sem_wait(semaphore);
    int error_number = errno;
    trace_result("sem_wait", result, error_number);
    errno = error_number;
    return result;
}

int sem_timedwait(sem_t *semaphore, const struct timespec *timeout) {
    static int (*real_sem_timedwait)(sem_t *, const struct timespec *);
    if (!real_sem_timedwait) {
        real_sem_timedwait = dlsym(RTLD_NEXT, "sem_timedwait");
    }
    errno = 0;
    int result = real_sem_timedwait(semaphore, timeout);
    int error_number = errno;
    trace_result("sem_timedwait", result, error_number);
    errno = error_number;
    return result;
}

int pthread_mutexattr_setprotocol(pthread_mutexattr_t *attributes, int protocol) {
    static int (*real_setprotocol)(pthread_mutexattr_t *, int);
    if (!real_setprotocol) {
        real_setprotocol = dlsym(RTLD_NEXT, "pthread_mutexattr_setprotocol");
    }
    errno = 0;
    int result = real_setprotocol(attributes, protocol);
    int error_number = errno;
    trace_result("pthread_mutexattr_setprotocol", result, error_number);
    errno = error_number;
    return result;
}

int pthread_mutexattr_settype(pthread_mutexattr_t *attributes, int type) {
    static int (*real_settype)(pthread_mutexattr_t *, int);
    if (!real_settype) {
        real_settype = dlsym(RTLD_NEXT, "pthread_mutexattr_settype");
    }
    errno = 0;
    int result = real_settype(attributes, type);
    int error_number = errno;
    trace_result("pthread_mutexattr_settype", result, error_number);
    errno = error_number;
    return result;
}

int pthread_mutexattr_setpshared(pthread_mutexattr_t *attributes, int shared) {
    static int (*real_setpshared)(pthread_mutexattr_t *, int);
    if (!real_setpshared) {
        real_setpshared = dlsym(RTLD_NEXT, "pthread_mutexattr_setpshared");
    }
    errno = 0;
    int result = real_setpshared(attributes, shared);
    int error_number = errno;
    trace_result("pthread_mutexattr_setpshared", result, error_number);
    errno = error_number;
    return result;
}

int pthread_mutexattr_setrobust(pthread_mutexattr_t *attributes, int robust) {
    static int (*real_setrobust)(pthread_mutexattr_t *, int);
    if (!real_setrobust) {
        real_setrobust = dlsym(RTLD_NEXT, "pthread_mutexattr_setrobust");
    }
    errno = 0;
    int result = real_setrobust(attributes, robust);
    int error_number = errno;
    trace_result("pthread_mutexattr_setrobust", result, error_number);
    errno = error_number;
    return result;
}

int pthread_condattr_setclock(pthread_condattr_t *attributes, clockid_t clock_id) {
    static int (*real_setclock)(pthread_condattr_t *, clockid_t);
    if (!real_setclock) {
        real_setclock = dlsym(RTLD_NEXT, "pthread_condattr_setclock");
    }
    errno = 0;
    int result = real_setclock(attributes, clock_id);
    int error_number = errno;
    trace_result("pthread_condattr_setclock", result, error_number);
    errno = error_number;
    return result;
}

int pthread_mutex_init(pthread_mutex_t *mutex, const pthread_mutexattr_t *attributes) {
    static int (*real_mutex_init)(pthread_mutex_t *, const pthread_mutexattr_t *);
    if (!real_mutex_init) {
        real_mutex_init = dlsym(RTLD_NEXT, "pthread_mutex_init");
    }
    errno = 0;
    int result = real_mutex_init(mutex, attributes);
    int error_number = errno;
    trace_result("pthread_mutex_init", result, error_number);
    errno = error_number;
    return result;
}

int pthread_cond_init(pthread_cond_t *condition, const pthread_condattr_t *attributes) {
    static int (*real_cond_init)(pthread_cond_t *, const pthread_condattr_t *);
    if (!real_cond_init) {
        real_cond_init = dlsym(RTLD_NEXT, "pthread_cond_init");
    }
    errno = 0;
    int result = real_cond_init(condition, attributes);
    int error_number = errno;
    trace_result("pthread_cond_init", result, error_number);
    errno = error_number;
    return result;
}

int pthread_cond_wait(pthread_cond_t *condition, pthread_mutex_t *mutex) {
    static int (*real_cond_wait)(pthread_cond_t *, pthread_mutex_t *);
    if (!real_cond_wait) {
        real_cond_wait = dlsym(RTLD_NEXT, "pthread_cond_wait");
    }
    errno = 0;
    int result = real_cond_wait(condition, mutex);
    int error_number = errno;
    trace_result("pthread_cond_wait", result, error_number);
    errno = error_number;
    return result;
}

int pthread_cond_timedwait(
    pthread_cond_t *condition,
    pthread_mutex_t *mutex,
    const struct timespec *timeout) {
    static int (*real_cond_timedwait)(pthread_cond_t *, pthread_mutex_t *, const struct timespec *);
    if (!real_cond_timedwait) {
        real_cond_timedwait = dlsym(RTLD_NEXT, "pthread_cond_timedwait");
    }
    errno = 0;
    int result = real_cond_timedwait(condition, mutex, timeout);
    int error_number = errno;
    trace_result("pthread_cond_timedwait", result, error_number);
    errno = error_number;
    return result;
}

int pthread_mutex_trylock(pthread_mutex_t *mutex) {
    static int (*real_trylock)(pthread_mutex_t *);
    if (!real_trylock) {
        real_trylock = dlsym(RTLD_NEXT, "pthread_mutex_trylock");
    }
    errno = 0;
    int result = real_trylock(mutex);
    int error_number = errno;
    trace_failure("pthread_mutex_trylock", result, error_number);
    errno = error_number;
    return result;
}

int pthread_mutex_lock(pthread_mutex_t *mutex) {
    static int (*real_lock)(pthread_mutex_t *);
    if (!real_lock) {
        real_lock = dlsym(RTLD_NEXT, "pthread_mutex_lock");
    }
    errno = 0;
    int result = real_lock(mutex);
    int error_number = errno;
    trace_failure("pthread_mutex_lock", result, error_number);
    errno = error_number;
    return result;
}

int pthread_mutex_unlock(pthread_mutex_t *mutex) {
    static int (*real_unlock)(pthread_mutex_t *);
    if (!real_unlock) {
        real_unlock = dlsym(RTLD_NEXT, "pthread_mutex_unlock");
    }
    errno = 0;
    int result = real_unlock(mutex);
    int error_number = errno;
    trace_failure("pthread_mutex_unlock", result, error_number);
    errno = error_number;
    return result;
}

int pthread_cond_signal(pthread_cond_t *condition) {
    static int (*real_signal)(pthread_cond_t *);
    if (!real_signal) {
        real_signal = dlsym(RTLD_NEXT, "pthread_cond_signal");
    }
    errno = 0;
    int result = real_signal(condition);
    int error_number = errno;
    trace_failure("pthread_cond_signal", result, error_number);
    errno = error_number;
    return result;
}

int pthread_cond_broadcast(pthread_cond_t *condition) {
    static int (*real_broadcast)(pthread_cond_t *);
    if (!real_broadcast) {
        real_broadcast = dlsym(RTLD_NEXT, "pthread_cond_broadcast");
    }
    errno = 0;
    int result = real_broadcast(condition);
    int error_number = errno;
    trace_failure("pthread_cond_broadcast", result, error_number);
    errno = error_number;
    return result;
}

int pipe2(int file_descriptors[2], int flags) {
    static int (*real_pipe2)(int[2], int);
    if (!real_pipe2) {
        real_pipe2 = dlsym(RTLD_NEXT, "pipe2");
    }
    errno = 0;
    int result = real_pipe2(file_descriptors, flags);
    int error_number = errno;
    trace_result("pipe2", result, error_number);
    errno = error_number;
    return result;
}

int eventfd(unsigned int initial_value, int flags) {
    static int (*real_eventfd)(unsigned int, int);
    if (!real_eventfd) {
        real_eventfd = dlsym(RTLD_NEXT, "eventfd");
    }
    errno = 0;
    int result = real_eventfd(initial_value, flags);
    int error_number = errno;
    trace_result("eventfd", result, error_number);
    if (result >= 0 && event_fd_count < sizeof(event_fds) / sizeof(event_fds[0])) {
        event_fds[event_fd_count++] = result;
    }
    errno = error_number;
    return result;
}

int socketpair(int domain, int type, int protocol, int file_descriptors[2]) {
    static int (*real_socketpair)(int, int, int, int[2]);
    if (!real_socketpair) {
        real_socketpair = dlsym(RTLD_NEXT, "socketpair");
    }
    errno = 0;
    int result = real_socketpair(domain, type, protocol, file_descriptors);
    int error_number = errno;
    trace_result("socketpair", result, error_number);
    errno = error_number;
    return result;
}

long syscall(long number, ...) {
    static long (*real_syscall)(long, ...);
    if (!real_syscall) {
        real_syscall = dlsym(RTLD_NEXT, "syscall");
    }

    va_list arguments;
    va_start(arguments, number);
    unsigned long values[6];
    for (size_t index = 0; index < 6; index++) {
        values[index] = va_arg(arguments, unsigned long);
    }
    va_end(arguments);

    errno = 0;
    long result = real_syscall(
        number,
        values[0],
        values[1],
        values[2],
        values[3],
        values[4],
        values[5]);
    int error_number = errno;

    int trace = 0;
#ifdef SYS_pipe2
    trace |= number == SYS_pipe2;
#endif
#ifdef SYS_eventfd2
    trace |= number == SYS_eventfd2;
#endif
#ifdef SYS_futex
    trace |= number == SYS_futex;
#endif
#ifdef SYS_futex_waitv
    trace |= number == SYS_futex_waitv;
#endif
#ifdef SYS_set_robust_list
    trace |= number == SYS_set_robust_list;
#endif
#ifdef SYS_get_robust_list
    trace |= number == SYS_get_robust_list;
#endif
#ifdef SYS_clone3
    trace |= number == SYS_clone3;
#endif
#ifdef SYS_memfd_create
    trace |= number == SYS_memfd_create;
#endif
#ifdef SYS_timerfd_create
    trace |= number == SYS_timerfd_create;
#endif
#ifdef SYS_epoll_create1
    trace |= number == SYS_epoll_create1;
#endif
    if (trace) {
        trace_syscall(number, result, error_number);
    }
    errno = error_number;
    return result;
}

int fcntl(int file_descriptor, int command, ...) {
    static int (*real_fcntl)(int, int, ...);
    if (!real_fcntl) {
        real_fcntl = dlsym(RTLD_NEXT, "fcntl");
    }
    va_list arguments;
    va_start(arguments, command);
    unsigned long argument = va_arg(arguments, unsigned long);
    va_end(arguments);
    errno = 0;
    int result = real_fcntl(file_descriptor, command, argument);
    int error_number = errno;
    if (is_event_fd(file_descriptor)) {
        trace_result("fcntl_eventfd", result, error_number);
    }
    errno = error_number;
    return result;
}

ssize_t read(int file_descriptor, void *buffer, size_t count) {
    static ssize_t (*real_read)(int, void *, size_t);
    if (!real_read) {
        real_read = dlsym(RTLD_NEXT, "read");
    }
    errno = 0;
    ssize_t result = real_read(file_descriptor, buffer, count);
    int error_number = errno;
    if (is_event_fd(file_descriptor)) {
        trace_result("read_eventfd", (int)result, error_number);
    }
    errno = error_number;
    return result;
}

ssize_t write(int file_descriptor, const void *buffer, size_t count) {
    static ssize_t (*real_write)(int, const void *, size_t);
    if (!real_write) {
        real_write = dlsym(RTLD_NEXT, "write");
    }
    errno = 0;
    ssize_t result = real_write(file_descriptor, buffer, count);
    int error_number = errno;
    if (is_event_fd(file_descriptor)) {
        trace_result("write_eventfd", (int)result, error_number);
    }
    errno = error_number;
    return result;
}

int pthread_create(
    pthread_t *thread,
    const pthread_attr_t *attributes,
    void *(*start_routine)(void *),
    void *argument) {
    static int (*real_create)(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *);
    if (!real_create) {
        real_create = dlsym(RTLD_NEXT, "pthread_create");
    }
    errno = 0;
    int result = real_create(thread, attributes, start_routine, argument);
    int error_number = errno;
    trace_result("pthread_create", result, error_number);
    errno = error_number;
    return result;
}
