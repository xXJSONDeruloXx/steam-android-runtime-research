#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdio.h>
#include <string.h>
#include <linux/futex.h>
#include <sys/ipc.h>
#include <sys/eventfd.h>
#include <sys/mman.h>
#include <sys/sem.h>
#include <sys/syscall.h>
#include <time.h>
#include <unistd.h>

static int failures;

static void report_result(const char *name, int result, int error_number) {
    if (result == 0) {
        printf("%s=pass\n", name);
        return;
    }
    printf("%s=fail errno=%d error=%s\n", name, error_number, strerror(error_number));
    failures++;
}

static void *thread_body(void *unused) {
    (void)unused;
    return NULL;
}

int main(void) {
    printf("posix_sync_probe=1\n");
    printf("pid=%ld\n", (long)getpid());

    sem_t unnamed;
    errno = 0;
    int result = sem_init(&unnamed, 0, 0);
    int error_number = errno;
    report_result("sem_init", result, error_number);
    if (result == 0) {
        errno = 0;
        result = sem_trywait(&unnamed);
        report_result("sem_trywait_empty", result == -1 && errno == EAGAIN ? 0 : -1, errno);
        report_result("sem_post", sem_post(&unnamed), errno);
        report_result("sem_wait", sem_wait(&unnamed), errno);
        report_result("sem_destroy", sem_destroy(&unnamed), errno);
    }

    const char *sem_name = "/nova-lab-posix-sync";
    sem_unlink(sem_name);
    errno = 0;
    sem_t *named = sem_open(sem_name, O_CREAT | O_EXCL, 0600, 0);
    error_number = errno;
    if (named == SEM_FAILED) {
        report_result("sem_open", -1, error_number);
    } else {
        report_result("sem_open", 0, 0);
        report_result("sem_close", sem_close(named), errno);
        report_result("sem_unlink", sem_unlink(sem_name), errno);
    }

    // Steam's tier0 implementation uses System V semaphores for named
    // cross-process events, not POSIX named semaphores. Keep this contract
    // explicit because a POSIX-only probe can pass while semget is unavailable.
    errno = 0;
    int sysv_semaphore = semget(IPC_PRIVATE, 1, 0600);
    error_number = errno;
    if (sysv_semaphore < 0) {
        report_result("sysv_semget", -1, error_number);
    } else {
        report_result("sysv_semget", 0, 0);
        union semun {
            int val;
            struct semid_ds *buf;
            unsigned short *array;
        } argument;
        argument.val = 1;
        report_result("sysv_semctl_setval", semctl(sysv_semaphore, 0, SETVAL, argument), errno);
        struct sembuf operation = {.sem_num = 0, .sem_op = -1, .sem_flg = 0};
        report_result("sysv_semop_down", semop(sysv_semaphore, &operation, 1), errno);
        operation.sem_op = 1;
        report_result("sysv_semop_up", semop(sysv_semaphore, &operation, 1), errno);
        report_result("sysv_semctl_rmid", semctl(sysv_semaphore, 0, IPC_RMID), errno);
    }

    pthread_mutexattr_t mutex_attributes;
    errno = 0;
    result = pthread_mutexattr_init(&mutex_attributes);
    report_result("pthread_mutexattr_init", result, errno);
    if (result == 0) {
        errno = 0;
        result = pthread_mutexattr_settype(&mutex_attributes, PTHREAD_MUTEX_RECURSIVE);
        report_result("pthread_mutexattr_settype_recursive", result, errno);
        errno = 0;
        result = pthread_mutexattr_setprotocol(&mutex_attributes, PTHREAD_PRIO_INHERIT);
        report_result("pthread_mutexattr_setprotocol_inherit", result, errno);
        errno = 0;
        result = pthread_mutexattr_setpshared(&mutex_attributes, PTHREAD_PROCESS_SHARED);
        report_result("pthread_mutexattr_setpshared", result, errno);
#ifdef PTHREAD_MUTEX_ROBUST
        errno = 0;
        result = pthread_mutexattr_setrobust(&mutex_attributes, PTHREAD_MUTEX_ROBUST);
        report_result("pthread_mutexattr_setrobust", result, errno);
#endif
        pthread_mutexattr_destroy(&mutex_attributes);
    }

    pthread_mutex_t mutex;
    errno = 0;
    result = pthread_mutex_init(&mutex, NULL);
    report_result("pthread_mutex_init", result, errno);
    if (result == 0) {
        report_result("pthread_mutex_lock", pthread_mutex_lock(&mutex), errno);
        report_result("pthread_mutex_unlock", pthread_mutex_unlock(&mutex), errno);
        report_result("pthread_mutex_destroy", pthread_mutex_destroy(&mutex), errno);
    }

    pthread_condattr_t condition_attributes;
    errno = 0;
    result = pthread_condattr_init(&condition_attributes);
    report_result("pthread_condattr_init", result, errno);
    if (result == 0) {
        errno = 0;
        result = pthread_condattr_setclock(&condition_attributes, CLOCK_MONOTONIC);
        report_result("pthread_condattr_setclock_monotonic", result, errno);
        errno = 0;
        result = pthread_condattr_setpshared(&condition_attributes, PTHREAD_PROCESS_SHARED);
        report_result("pthread_condattr_setpshared", result, errno);
        pthread_condattr_destroy(&condition_attributes);
    }

    pthread_cond_t condition;
    errno = 0;
    result = pthread_cond_init(&condition, NULL);
    report_result("pthread_cond_init", result, errno);
    if (result == 0) {
        pthread_mutex_t wait_mutex = PTHREAD_MUTEX_INITIALIZER;
        report_result("pthread_mutex_lock_for_cond", pthread_mutex_lock(&wait_mutex), errno);
        struct timespec timeout;
        clock_gettime(CLOCK_MONOTONIC, &timeout);
        timeout.tv_nsec += 1000000;
        if (timeout.tv_nsec >= 1000000000L) {
            timeout.tv_sec++;
            timeout.tv_nsec -= 1000000000L;
        }
        result = pthread_cond_timedwait(&condition, &wait_mutex, &timeout);
        report_result("pthread_cond_timedwait_timeout", result == ETIMEDOUT ? 0 : -1, result);
        report_result("pthread_mutex_unlock_for_cond", pthread_mutex_unlock(&wait_mutex), errno);
        report_result("pthread_mutex_destroy_for_cond", pthread_mutex_destroy(&wait_mutex), errno);
        report_result("pthread_cond_destroy", pthread_cond_destroy(&condition), errno);
    }

    pthread_t thread;
    errno = 0;
    result = pthread_create(&thread, NULL, thread_body, NULL);
    report_result("pthread_create", result, errno);
    if (result == 0) {
        report_result("pthread_join", pthread_join(thread, NULL), errno);
    }

    errno = 0;
    int event_fd = eventfd(0, EFD_CLOEXEC);
    error_number = errno;
    if (event_fd < 0) {
        report_result("eventfd", -1, error_number);
    } else {
        report_result("eventfd", 0, 0);
        close(event_fd);
    }

    int pipe_fds[2];
    errno = 0;
    result = pipe2(pipe_fds, O_CLOEXEC | O_NONBLOCK);
    error_number = errno;
    if (result < 0) {
        report_result("pipe2", -1, error_number);
    } else {
        report_result("pipe2", 0, 0);
        close(pipe_fds[0]);
        close(pipe_fds[1]);
    }

    int futex_word = 0;
    errno = 0;
    long futex_result = syscall(SYS_futex, &futex_word, FUTEX_WAKE_PRIVATE, 1, NULL, NULL, 0);
    error_number = errno;
    report_result("futex_wake_private", futex_result < 0 ? -1 : 0, error_number);

    const char *shm_name = "/nova-lab-posix-shm";
    shm_unlink(shm_name);
    errno = 0;
    int shm_fd = shm_open(shm_name, O_CREAT | O_EXCL | O_RDWR, 0600);
    error_number = errno;
    if (shm_fd < 0) {
        report_result("shm_open", -1, error_number);
    } else {
        report_result("shm_open", 0, 0);
        report_result("ftruncate_shm", ftruncate(shm_fd, 4096), errno);
        void *mapping = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
        if (mapping == MAP_FAILED) {
            report_result("mmap_shm", -1, errno);
        } else {
            report_result("mmap_shm", 0, 0);
            munmap(mapping, 4096);
        }
        close(shm_fd);
        report_result("shm_unlink", shm_unlink(shm_name), errno);
    }

    printf("posix_sync_status=%s failures=%d\n", failures == 0 ? "pass" : "fail", failures);
    return failures == 0 ? 0 : 1;
}
