#!/usr/bin/env python3

"""Bound rootless Steam logs and protect noisy CEF paths.

This runs inside the Holo guest through PRoot. It intentionally has no process
kill or authentication-data behavior; lifecycle cleanup remains the caller's
exact-scope responsibility.
"""

import argparse
import datetime
import errno
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile


MINIMUM_CAP_BYTES = 256
READ_SIZE = 64 * 1024
NOISY_LOGS = (
    Path("logs/steamwebhelper.log"),
    Path("config/htmlcache/chrome_debug.log"),
)


def integer(value, minimum=0):
    try:
        parsed = int(value, 10)
    except ValueError as error:
        raise argparse.ArgumentTypeError("must be a base-10 integer") from error
    if parsed < minimum:
        raise argparse.ArgumentTypeError(f"must be at least {minimum}")
    return parsed


def is_dev_null(path):
    try:
        return stat.S_ISLNK(path.lstat().st_mode) and os.readlink(path) == "/dev/null"
    except FileNotFoundError:
        return False


def describe(path):
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        return "missing"
    if stat.S_ISLNK(mode):
        return f"symlink to {os.readlink(path)!r}"
    if stat.S_ISREG(mode):
        return "regular file"
    return "unexpected file type"


def install_dev_null(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.parent / f".{path.name}.nova-{os.getpid()}"
    try:
        os.symlink("/dev/null", temporary)
        os.replace(temporary, path)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass
    if not is_dev_null(path):
        raise RuntimeError(f"failed to install /dev/null guard: {path}")


def preflight(args):
    client_root = Path(args.client_root)
    logs_dir = Path(args.logs_dir)
    logs_dir.mkdir(parents=True, exist_ok=True)
    available = shutil.disk_usage(logs_dir).free
    required = args.min_free_bytes + args.log_cap_bytes
    if available < required:
        raise RuntimeError(
            f"insufficient free space: {available} < {required}"
        )

    paths = [client_root / relative for relative in NOISY_LOGS]
    states = [(path, describe(path)) for path in paths]
    if args.steam_running == "yes":
        active = [path for path, state in states if state != "symlink to /dev/null"]
        if active:
            raise RuntimeError(
                "refusing to replace noisy log paths while Steam is running: "
                + ", ".join(str(path) for path in active)
            )
    for path, state in states:
        if state not in ("missing", "regular file", "symlink to /dev/null"):
            raise RuntimeError(f"refusing unexpected log path: {path} ({state})")
    for path, _state in states:
        if not is_dev_null(path):
            install_dev_null(path)


def create_log(logs_dir):
    prefix = datetime.datetime.now().strftime("steam-%Y%m%d-%H%M%S-")
    descriptor, path = tempfile.mkstemp(prefix=prefix, suffix=".log", dir=logs_dir)
    os.fchmod(descriptor, 0o600)
    os.close(descriptor)
    print(path)


def write_all(descriptor, data):
    offset = 0
    while offset < len(data):
        try:
            written = os.write(descriptor, data[offset:])
        except InterruptedError:
            continue
        if written == 0:
            raise OSError(errno.EIO, "zero-byte write")
        offset += written


def stream(args):
    log_path = Path(args.log)
    flags = os.O_WRONLY | os.O_TRUNC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        log_descriptor = os.open(log_path, flags)
    except OSError as error:
        print(f"log unavailable: {error}", file=sys.stderr)
        log_descriptor = None
    if log_descriptor is not None:
        metadata = os.fstat(log_descriptor)
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_nlink != 1:
            os.close(log_descriptor)
            raise RuntimeError("session log is not a singly-linked regular file")

    log_written = 0
    stdout_written = 0
    log_marker = (
        f"\n[nova rootless logger: log truncated at {args.log_cap_bytes} bytes]\n"
    ).encode()
    stdout_marker = (
        f"\n[nova rootless logger: stdout truncated at {args.stdout_cap_bytes} bytes]\n"
    ).encode()
    try:
        while True:
            data = os.read(0, READ_SIZE)
            if not data:
                break
            if log_descriptor is not None and log_written < args.log_cap_bytes:
                room = args.log_cap_bytes - log_written
                payload = data[:room]
                if payload:
                    write_all(log_descriptor, payload)
                    log_written += len(payload)
                if log_written == args.log_cap_bytes:
                    marker = log_marker[: max(0, args.log_cap_bytes - log_written)]
                    if marker:
                        write_all(log_descriptor, marker)
            if stdout_written < args.stdout_cap_bytes:
                room = args.stdout_cap_bytes - stdout_written
                payload = data[:room]
                if payload:
                    write_all(1, payload)
                    stdout_written += len(payload)
                if stdout_written == args.stdout_cap_bytes:
                    marker = stdout_marker[: max(0, args.stdout_cap_bytes - stdout_written)]
                    if marker:
                        write_all(1, marker)
    finally:
        if log_descriptor is not None:
            os.close(log_descriptor)


def parser():
    root = argparse.ArgumentParser()
    commands = root.add_subparsers(dest="command", required=True)
    preflight_command = commands.add_parser("preflight")
    preflight_command.add_argument("--client-root", required=True)
    preflight_command.add_argument("--logs-dir", required=True)
    preflight_command.add_argument("--min-free-bytes", required=True, type=integer)
    preflight_command.add_argument(
        "--log-cap-bytes", required=True, type=lambda value: integer(value, MINIMUM_CAP_BYTES)
    )
    preflight_command.add_argument("--steam-running", required=True, choices=("yes", "no"))
    create_command = commands.add_parser("create-log")
    create_command.add_argument("--logs-dir", required=True)
    stream_command = commands.add_parser("stream")
    stream_command.add_argument("--log", required=True)
    stream_command.add_argument("--log-cap-bytes", required=True, type=lambda value: integer(value, MINIMUM_CAP_BYTES))
    stream_command.add_argument("--stdout-cap-bytes", required=True, type=lambda value: integer(value, MINIMUM_CAP_BYTES))
    return root


def main():
    args = parser().parse_args()
    try:
        if args.command == "preflight":
            preflight(args)
        elif args.command == "create-log":
            create_log(args.logs_dir)
        elif args.command == "stream":
            stream(args)
        else:
            raise AssertionError(args.command)
    except (OSError, RuntimeError, ValueError) as error:
        print(f"nova rootless session guard: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
