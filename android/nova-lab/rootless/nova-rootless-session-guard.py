#!/usr/bin/env python3

"""Bound rootless Steam logs and protect noisy CEF paths.

This runs inside the Holo guest through PRoot. It intentionally has no process
kill or authentication-data behavior; lifecycle cleanup remains the caller's
exact-scope responsibility.
"""

import argparse
import datetime
import errno
import fcntl
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
        return f"symlink to {os.readlink(path)}"
    if stat.S_ISREG(mode):
        return "regular file"
    if stat.S_ISDIR(mode):
        return "directory"
    if stat.S_ISFIFO(mode):
        return "FIFO"
    if stat.S_ISSOCK(mode):
        return "socket"
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


def crash_mode(value):
    if value in ("", "0"):
        return "disabled"
    if value == "1":
        return "enabled"
    raise ValueError("PROOT_CRASH_LOG must be unset, 0, or 1")


def safe_diagnostic(message):
    try:
        write_all(2, (message + "\n").encode("utf-8", "replace"))
    except OSError:
        pass


class CappedSink:
    def __init__(self, descriptor, cap_bytes, label, close_descriptor=False):
        self.descriptor = descriptor
        self.cap_bytes = cap_bytes
        self.label = label
        self.close_descriptor = close_descriptor
        self.marker = (
            f"\n[nova rootless logger: {label} truncated at {cap_bytes} bytes; "
            "remaining child output drained]\n"
        ).encode()
        if len(self.marker) >= cap_bytes:
            raise ValueError(f"{label} cap is too small for its truncation marker")
        self.payload_limit = cap_bytes - len(self.marker)
        self.payload_written = 0
        self.truncated = False
        self.failed = False

    def _write(self, data):
        if self.failed or not data:
            return
        try:
            write_all(self.descriptor, data)
        except OSError as error:
            self.failed = True
            safe_diagnostic(
                f"nova rootless logger: disabling {self.label} after write error: {error}"
            )

    def feed(self, data):
        if self.failed or self.truncated or not data:
            return
        remaining = self.payload_limit - self.payload_written
        prefix = data[:remaining]
        self._write(prefix)
        if self.failed:
            return
        self.payload_written += len(prefix)
        if len(data) > len(prefix):
            self._write(self.marker)
            if not self.failed:
                self.truncated = True

    def close(self):
        if self.close_descriptor:
            try:
                os.close(self.descriptor)
            except OSError:
                pass


def open_canonical_log(path):
    flags = os.O_WRONLY | os.O_TRUNC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    descriptor = os.open(path, flags)
    if descriptor <= 2:
        replacement = fcntl.fcntl(descriptor, fcntl.F_DUPFD_CLOEXEC, 3)
        os.close(descriptor)
        descriptor = replacement
    metadata = os.fstat(descriptor)
    if not stat.S_ISREG(metadata.st_mode) or metadata.st_nlink != 1:
        os.close(descriptor)
        raise RuntimeError("session log is not a singly-linked regular file")
    return descriptor


def stream(args):
    try:
        log_descriptor = open_canonical_log(Path(args.log))
    except (OSError, RuntimeError) as error:
        log_descriptor = None
        safe_diagnostic(f"nova rootless logger: canonical log unavailable: {error}")

    sinks = [CappedSink(1, args.stdout_cap_bytes, "mirrored stdout")]
    if log_descriptor is not None:
        sinks.append(
            CappedSink(
                log_descriptor,
                args.log_cap_bytes,
                "canonical log",
                close_descriptor=True,
            )
        )
    try:
        while True:
            data = os.read(0, READ_SIZE)
            if not data:
                break
            for sink in sinks:
                sink.feed(data)
    finally:
        for sink in sinks:
            sink.close()


def parser():
    root = argparse.ArgumentParser()
    commands = root.add_subparsers(dest="command", required=True)
    crash_command = commands.add_parser("crash-mode")
    crash_command.add_argument("value")
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
        if args.command == "crash-mode":
            print(crash_mode(args.value))
        elif args.command == "preflight":
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
