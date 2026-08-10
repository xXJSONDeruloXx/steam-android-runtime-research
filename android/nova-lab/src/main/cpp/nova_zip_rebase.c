#define _FILE_OFFSET_BITS 64

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static uint16_t read_u16(const unsigned char *p)
{
    return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}

static uint32_t read_u32(const unsigned char *p)
{
    return (uint32_t)p[0] |
           ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) |
           ((uint32_t)p[3] << 24);
}

static void write_u32(unsigned char *p, uint32_t value)
{
    p[0] = (unsigned char)value;
    p[1] = (unsigned char)(value >> 8);
    p[2] = (unsigned char)(value >> 16);
    p[3] = (unsigned char)(value >> 24);
}

static int read_full(int fd, void *buffer, size_t length)
{
    unsigned char *cursor = buffer;
    while (length != 0) {
        ssize_t count = read(fd, cursor, length);
        if (count <= 0) {
            return -1;
        }
        cursor += count;
        length -= (size_t)count;
    }
    return 0;
}

static int write_full(int fd, const void *buffer, size_t length)
{
    const unsigned char *cursor = buffer;
    while (length != 0) {
        ssize_t count = write(fd, cursor, length);
        if (count <= 0) {
            return -1;
        }
        cursor += count;
        length -= (size_t)count;
    }
    return 0;
}

static int copy_range(int input, int output, uint64_t length)
{
    unsigned char buffer[64 * 1024];
    while (length != 0) {
        size_t requested = length < sizeof(buffer) ? (size_t)length : sizeof(buffer);
        if (read_full(input, buffer, requested) != 0 ||
            write_full(output, buffer, requested) != 0) {
            return -1;
        }
        length -= requested;
    }
    return 0;
}

static int find_signature(int fd, uint64_t begin, uint64_t end,
                          const unsigned char signature[4], uint64_t *result)
{
    unsigned char buffer[64 * 1024 + 3];
    uint64_t position = begin;
    size_t carry = 0;

    while (position < end) {
        uint64_t remaining = end - position;
        size_t requested = remaining < 64 * 1024 ? (size_t)remaining : 64 * 1024;
        if (lseek(fd, (off_t)position, SEEK_SET) < 0 ||
            read_full(fd, buffer + carry, requested) != 0) {
            return -1;
        }
        size_t available = carry + requested;
        for (size_t index = 0; index + 4 <= available; index++) {
            if (memcmp(buffer + index, signature, 4) == 0) {
                uint64_t found = position - carry + index;
                if (found < end) {
                    *result = found;
                    return 0;
                }
            }
        }
        if (available >= 3) {
            memcpy(buffer, buffer + available - 3, 3);
            carry = 3;
        } else {
            memmove(buffer, buffer, available);
            carry = available;
        }
        position += requested;
    }
    return -1;
}

static int has_signature_at(int fd, uint64_t position,
                            const unsigned char signature[4])
{
    unsigned char value[4];
    if (lseek(fd, (off_t)position, SEEK_SET) < 0 || read_full(fd, value, sizeof(value)) != 0) {
        return 0;
    }
    return memcmp(value, signature, sizeof(value)) == 0;
}

static void report_error(const char *message)
{
    fprintf(stderr, "nova_zip_rebase_error=%s errno=%d message=%s\n",
            message, errno, strerror(errno));
}

int main(int argc, char **argv)
{
    static const unsigned char local_signature[4] = {'P', 'K', 3, 4};
    static const unsigned char central_signature[4] = {'P', 'K', 1, 2};
    static const unsigned char end_signature[4] = {'P', 'K', 5, 6};
    const char *input_path;
    const char *output_path;
    struct stat input_stat;
    unsigned char *tail = NULL;
    unsigned char end_record[22];
    unsigned char central_header[46];
    unsigned char *central_record = NULL;
    unsigned char *comment = NULL;
    uint64_t prefix;
    uint64_t central_offset;
    uint64_t central_absolute;
    uint64_t central_size;
    uint64_t end_position;
    uint64_t tail_start;
    size_t tail_length;
    size_t end_in_tail = 0;
    uint16_t entry_count;
    int input = -1;
    int output = -1;
    int status = 1;

    if (argc != 3) {
        fprintf(stderr, "usage: %s INPUT OUTPUT\n", argv[0]);
        return 2;
    }
    input_path = argv[1];
    output_path = argv[2];
    if (strcmp(input_path, output_path) == 0) {
        fprintf(stderr, "nova_zip_rebase_error=same_path\n");
        return 2;
    }
    input = open(input_path, O_RDONLY | O_CLOEXEC);
    if (input < 0 || fstat(input, &input_stat) != 0 || input_stat.st_size < 22) {
        report_error("open_input");
        goto done;
    }

    tail_length = input_stat.st_size < 65557 ? (size_t)input_stat.st_size : 65557;
    tail_start = (uint64_t)input_stat.st_size - tail_length;
    tail = malloc(tail_length);
    if (tail == NULL || lseek(input, (off_t)tail_start, SEEK_SET) < 0 ||
        read_full(input, tail, tail_length) != 0) {
        report_error("read_end");
        goto done;
    }
    for (size_t index = tail_length - 22; ; index--) {
        if (memcmp(tail + index, end_signature, sizeof(end_signature)) == 0) {
            end_in_tail = index;
            break;
        }
        if (index == 0) {
            fprintf(stderr, "nova_zip_rebase_error=missing_end_record\n");
            goto done;
        }
    }
    end_position = tail_start + end_in_tail;
    memcpy(end_record, tail + end_in_tail, sizeof(end_record));
    entry_count = read_u16(end_record + 10);
    central_size = read_u32(end_record + 12);
    central_offset = read_u32(end_record + 16);
    if (entry_count == 0xffff || central_size > (uint64_t)input_stat.st_size ||
        central_offset > (uint64_t)input_stat.st_size) {
        fprintf(stderr, "nova_zip_rebase_error=zip64_unsupported\n");
        goto done;
    }

    if (find_signature(input, 0, (uint64_t)input_stat.st_size,
                       local_signature, &prefix) != 0 ||
        prefix > 1024 * 1024) {
        fprintf(stderr, "nova_zip_rebase_error=missing_or_large_prefix\n");
        goto done;
    }
    central_absolute = central_offset;
    if (!has_signature_at(input, central_absolute, central_signature) &&
        prefix <= (uint64_t)input_stat.st_size - central_offset) {
        central_absolute += prefix;
    }
    if (central_absolute < prefix || central_absolute + central_size > end_position ||
        !has_signature_at(input, central_absolute, central_signature)) {
        fprintf(stderr, "nova_zip_rebase_error=invalid_central_directory\n");
        goto done;
    }
    if (central_absolute - prefix > UINT32_MAX) {
        fprintf(stderr, "nova_zip_rebase_error=central_directory_too_large\n");
        goto done;
    }

    output = open(output_path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0700);
    if (output < 0) {
        report_error("open_output");
        goto done;
    }
    if (lseek(input, (off_t)prefix, SEEK_SET) < 0 ||
        copy_range(input, output, central_absolute - prefix) != 0 ||
        lseek(input, (off_t)central_absolute, SEEK_SET) < 0) {
        report_error("copy_local_data");
        goto done;
    }

    uint64_t remaining = central_size;
    while (remaining != 0) {
        if (remaining < 46 || read_full(input, central_header, sizeof(central_header)) != 0 ||
            memcmp(central_header, central_signature, sizeof(central_signature)) != 0) {
            fprintf(stderr, "nova_zip_rebase_error=invalid_central_record\n");
            goto done;
        }
        uint16_t name_length = read_u16(central_header + 28);
        uint16_t extra_length = read_u16(central_header + 30);
        uint16_t comment_length = read_u16(central_header + 32);
        size_t record_length = 46u + name_length + extra_length + comment_length;
        if (record_length > remaining || record_length < 46) {
            fprintf(stderr, "nova_zip_rebase_error=central_record_length\n");
            goto done;
        }
        central_record = realloc(central_record, record_length);
        if (central_record == NULL) {
            report_error("central_record_alloc");
            goto done;
        }
        memcpy(central_record, central_header, sizeof(central_header));
        if (read_full(input, central_record + 46, record_length - 46) != 0) {
            report_error("read_central_record");
            goto done;
        }
        uint32_t old_offset = read_u32(central_record + 42);
        if (old_offset < prefix) {
            fprintf(stderr, "nova_zip_rebase_error=local_offset_before_prefix\n");
            goto done;
        }
        write_u32(central_record + 42, old_offset - (uint32_t)prefix);
        if (write_full(output, central_record, record_length) != 0) {
            report_error("write_central_record");
            goto done;
        }
        remaining -= record_length;
    }

    if (lseek(input, (off_t)end_position, SEEK_SET) < 0 ||
        read_full(input, end_record, sizeof(end_record)) != 0) {
        report_error("read_end_record");
        goto done;
    }
    uint16_t archive_comment_length = read_u16(end_record + 20);
    comment = malloc(archive_comment_length);
    if (archive_comment_length != 0 &&
        (comment == NULL || read_full(input, comment, archive_comment_length) != 0)) {
        report_error("read_archive_comment");
        goto done;
    }
    write_u32(end_record + 16, (uint32_t)(central_absolute - prefix));
    if (write_full(output, end_record, sizeof(end_record)) != 0 ||
        (archive_comment_length != 0 && write_full(output, comment, archive_comment_length) != 0) ||
        fsync(output) != 0) {
        report_error("write_end_record");
        goto done;
    }
    if (fchmod(output, 0700) != 0) {
        report_error("chmod_output");
        goto done;
    }
    printf("nova_zip_rebase=pass prefix=%llu entries=%u\n",
           (unsigned long long)prefix, entry_count);
    status = 0;

done:
    free(comment);
    free(central_record);
    free(tail);
    if (input >= 0) {
        close(input);
    }
    if (output >= 0) {
        close(output);
    }
    if (status != 0) {
        unlink(output_path);
    }
    return status;
}
