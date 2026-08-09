#!/usr/bin/env python3

"""Encode a logical RGBA8 Nova AHardwareBuffer snapshot as a PNG."""

import struct
import sys
import zlib


def png_chunk(kind, payload):
    return (
        struct.pack(">I", len(payload))
        + kind
        + payload
        + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
    )


def fail(reason):
    print(f"nova_ahb_raw_decode=fail reason={reason}")
    return 1


def main():
    if len(sys.argv) != 5:
        print(
            f"usage: {sys.argv[0]} INPUT.rgba WIDTH HEIGHT OUTPUT.png",
            file=sys.stderr,
        )
        return 2

    input_path, width_text, height_text, output_path = sys.argv[1:]
    try:
        width = int(width_text, 10)
        height = int(height_text, 10)
    except ValueError:
        return fail("invalid_dimensions")
    if width <= 0 or height <= 0 or width > 4096 or height > 4096:
        return fail("dimensions_out_of_range")

    try:
        with open(input_path, "rb") as input_file:
            pixels = input_file.read()
    except OSError as error:
        return fail(f"open_{type(error).__name__}")

    expected = width * height * 4
    if len(pixels) != expected:
        return fail(f"size_{len(pixels)}_expected_{expected}")

    rows = b"".join(
        b"\x00" + pixels[row * width * 4 : (row + 1) * width * 4]
        for row in range(height)
    )
    png = b"\x89PNG\r\n\x1a\n"
    png += png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += png_chunk(b"IDAT", zlib.compress(rows, level=6))
    png += png_chunk(b"IEND", b"")

    try:
        with open(output_path, "wb") as output_file:
            output_file.write(png)
    except OSError as error:
        return fail(f"write_{type(error).__name__}")

    print("nova_ahb_raw_decode=pass")
    print(f"nova_ahb_raw_size={width}x{height}")
    print(f"nova_ahb_raw_bytes={len(pixels)}")
    print(f"nova_ahb_raw_png={output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
