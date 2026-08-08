#define _GNU_SOURCE

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s MOUNTPOINT...\n", argv[0]);
        return 2;
    }

    for (int index = 1; index < argc; index++) {
        if (mount(NULL, argv[index], NULL, MS_PRIVATE | MS_REC, NULL) != 0) {
            fprintf(stderr, "mount_private_error path=%s errno=%d message=%s\n",
                    argv[index], errno, strerror(errno));
            return 1;
        }
        printf("mount_private=pass path=%s\n", argv[index]);
    }
    return 0;
}
