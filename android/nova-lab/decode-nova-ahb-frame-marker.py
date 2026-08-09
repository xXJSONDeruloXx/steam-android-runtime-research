#!/usr/bin/env python3

"""Decode the opt-in Nova AHB frame marker from an Android PNG capture."""

import struct
import subprocess
import sys


MARKER_X = 16
MARKER_Y = 96
MARKER_CELL = 8
MARKER_COLUMNS = 12
MARKER_ROWS = 4
MARKER_BITS = MARKER_COLUMNS * MARKER_ROWS
MARKER_MAGIC = 0x4E56


def fail(reason):
    print(f"nova_frame_marker_decode=fail reason={reason}")
    return 1


def main():
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} SCREENSHOT.png", file=sys.stderr)
        return 2

    path = sys.argv[1]
    try:
        with open(path, "rb") as image_file:
            png = image_file.read()
    except OSError as error:
        return fail(f"open_{type(error).__name__}")

    if len(png) < 24 or png[:8] != b"\x89PNG\r\n\x1a\n":
        return fail("not_png")
    width, height = struct.unpack(">II", png[16:24])
    expected_marker_width = MARKER_COLUMNS * MARKER_CELL
    expected_marker_height = MARKER_ROWS * MARKER_CELL
    if width < MARKER_X + expected_marker_width or height < MARKER_Y + expected_marker_height:
        return fail("screenshot_too_small")

    decoded = subprocess.run(
        [
            "ffmpeg",
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            path,
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgba",
            "-",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if decoded.returncode != 0:
        return fail("ffmpeg")
    expected_bytes = width * height * 4
    if len(decoded.stdout) != expected_bytes:
        return fail("raw_size")

    pixels = decoded.stdout
    payload = 0
    for bit in range(MARKER_BITS):
        column = bit % MARKER_COLUMNS
        row = bit // MARKER_COLUMNS
        center_x = MARKER_X + column * MARKER_CELL + MARKER_CELL // 2
        center_y = MARKER_Y + row * MARKER_CELL + MARKER_CELL // 2
        luminance = 0
        samples = 0
        for y in range(center_y - 1, center_y + 2):
            for x in range(center_x - 1, center_x + 2):
                offset = (y * width + x) * 4
                luminance += sum(pixels[offset : offset + 3]) // 3
                samples += 1
        bit_value = 1 if luminance // samples >= 160 else 0
        payload = (payload << 1) | bit_value

    magic = (payload >> 32) & 0xFFFF
    frame = (payload >> 16) & 0xFFFF
    checksum_low16 = payload & 0xFFFF
    if magic != MARKER_MAGIC:
        return fail(f"magic_{magic:04x}")

    print("nova_frame_marker_decode=pass")
    print(f"nova_frame_marker_png_size={width}x{height}")
    print(f"nova_frame_marker_origin={MARKER_X},{MARKER_Y}")
    print(f"nova_frame_marker_cell={MARKER_CELL}")
    print(f"nova_frame_marker_frame={frame}")
    print(f"nova_frame_marker_checksum_low16={checksum_low16:04x}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
