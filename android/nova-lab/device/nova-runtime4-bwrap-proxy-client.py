#!/usr/bin/env python3

import array
import os
import socket
import struct
import sys


MAGIC = 0x4E425750
SOCKET_PATH = "/tmp/nova-root-bwrap.sock"


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: proxy-client REAL_BWRAP [BWRAP_ARGS...]", file=sys.stderr)
        return 2

    real_bwrap = sys.argv[1]
    bwrap_args = sys.argv[2:]
    environment = [
        f"{key}={value}" for key, value in os.environ.items()
    ]
    strings = [real_bwrap, *bwrap_args, *environment]
    payload = b"\0".join(item.encode("utf-8", "surrogateescape") for item in strings) + b"\0"

    fd_numbers = []
    for name in os.listdir("/proc/self/fd"):
        try:
            number = int(name)
        except ValueError:
            continue
        if number < 0 or number > 1024:
            continue
        try:
            os.fstat(number)
        except OSError:
            continue
        fd_numbers.append(number)
    fd_numbers = sorted(set(fd_numbers))
    if len(fd_numbers) > 128:
        print("proxy_client_error=too_many_file_descriptors", file=sys.stderr)
        return 125

    header = struct.pack(
        "!IIIII", MAGIC, len(payload), len(fd_numbers),
        len(bwrap_args) + 1, len(environment)
    )
    fd_table = b"".join(struct.pack("!I", number) for number in fd_numbers)
    message = header + payload + fd_table

    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        client.connect(SOCKET_PATH)
        rights = array.array("i", fd_numbers)
        sent = client.sendmsg([message], [(socket.SOL_SOCKET, socket.SCM_RIGHTS, rights)])
        if sent != len(message):
            print("proxy_client_error=partial_send", file=sys.stderr)
            return 125
        response = bytearray()
        while len(response) < 4:
            chunk = client.recv(4 - len(response))
            if not chunk:
                return 125
            response.extend(chunk)
    except OSError as error:
        print(f"proxy_client_error={error}", file=sys.stderr)
        return 125
    finally:
        client.close()

    return struct.unpack("!I", response)[0]


if __name__ == "__main__":
    raise SystemExit(main())
