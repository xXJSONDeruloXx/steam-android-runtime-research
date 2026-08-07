#!/usr/bin/env python3

"""Resolve and download a small Holo package closure for an extracted rootfs."""

from __future__ import annotations

import argparse
import hashlib
import io
import re
import sys
import tarfile
import urllib.parse
import urllib.request
from pathlib import Path


def parse_desc(text: str) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    key: str | None = None
    for line in text.splitlines():
        if line.startswith("%") and line.endswith("%"):
            key = line[1:-1]
            result[key] = []
        elif not line:
            key = None
        elif key is not None:
            result[key].append(line)
    return result


def download(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": "nova-linux-lab/1"})
    with urllib.request.urlopen(request) as response:
        return response.read()


def read_database(url: str, repo: str) -> list[dict[str, object]]:
    archive = download(url)
    records: list[dict[str, object]] = []
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:*") as tar:
        for member in tar.getmembers():
            if not member.name.endswith("/desc"):
                continue
            extracted = tar.extractfile(member)
            if extracted is None:
                continue
            desc = parse_desc(extracted.read().decode("utf-8", errors="replace"))
            name = desc.get("NAME", [""])[0]
            if not name:
                continue
            records.append(
                {
                    "repo": repo,
                    "name": name,
                    "version": desc.get("VERSION", [""])[0],
                    "filename": desc.get("FILENAME", [""])[0],
                    "sha256": desc.get("SHA256SUM", [""])[0],
                    "depends": desc.get("DEPENDS", []),
                    "provides": desc.get("PROVIDES", []),
                }
            )
    return records


def read_local_packages(rootfs: Path) -> tuple[set[str], dict[str, list[str]]]:
    installed: set[str] = set()
    providers: dict[str, list[str]] = {}
    for desc_path in (rootfs / "var/lib/pacman/local").glob("*/desc"):
        desc = parse_desc(desc_path.read_text(errors="replace"))
        name = desc.get("NAME", [""])[0]
        if not name:
            continue
        installed.add(name)
        for provided in desc.get("PROVIDES", []):
            providers.setdefault(re.sub(r"[<>=].*$", "", provided), []).append(name)
    return installed, providers


def dependency_name(dependency: str) -> str:
    return re.split(r"[<>=]", dependency, maxsplit=1)[0]


def record_provides(record: dict[str, object], name: str) -> bool:
    if record["name"] == name:
        return True
    return any(re.sub(r"[<>=].*$", "", value) == name for value in record["provides"])


def resolve(
    records: list[dict[str, object]], rootfs: Path, requested: list[str]
) -> list[dict[str, object]]:
    installed, installed_providers = read_local_packages(rootfs)
    by_name: dict[str, dict[str, object]] = {}
    providers: dict[str, list[dict[str, object]]] = {}
    for record in records:
        by_name.setdefault(str(record["name"]), record)
        for provided in [str(record["name"]), *record["provides"]]:
            providers.setdefault(re.sub(r"[<>=].*$", "", provided), []).append(record)

    selected: dict[str, dict[str, object]] = {}
    queue = list(requested)

    def satisfied(name: str) -> bool:
        if name in installed or name in installed_providers:
            return True
        return any(record_provides(record, name) for record in selected.values())

    while queue:
        dependency = queue.pop(0)
        name = dependency_name(dependency)
        if satisfied(name):
            continue
        record = by_name.get(name)
        if record is None:
            candidates = providers.get(name, [])
            record = candidates[0] if candidates else None
        if record is None:
            raise RuntimeError(f"no Holo package satisfies {dependency}")
        selected[str(record["name"])] = record
        queue.extend(record["depends"])

    return [selected[name] for name in sorted(selected)]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--base-url",
        default="https://holo-packages.steamos.cloud/holo-core-aarch64-preview/mash-20251118.3",
    )
    parser.add_argument("--rootfs", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("packages", nargs="+", default=["vulkan-tools", "vulkan-freedreno"])
    args = parser.parse_args()

    records: list[dict[str, object]] = []
    for repo in ("core", "extra"):
        db_url = f"{args.base_url}/{repo}/os/aarch64/{repo}.db.tar.xz"
        print(f"fetching {db_url}", file=sys.stderr)
        records.extend(read_database(db_url, repo))

    closure = resolve(records, args.rootfs, args.packages)
    args.output.mkdir(parents=True, exist_ok=True)
    manifest: list[str] = []
    for record in closure:
        filename = str(record["filename"])
        url = (
            f"{args.base_url}/{record['repo']}/os/aarch64/"
            f"{urllib.parse.quote(filename, safe='')}"
        )
        destination = args.output / filename
        expected = str(record["sha256"])
        if destination.exists():
            digest = hashlib.sha256(destination.read_bytes()).hexdigest()
            if digest != expected:
                destination.unlink()
        if not destination.exists():
            print(f"downloading {filename}", file=sys.stderr)
            payload = download(url)
            digest = hashlib.sha256(payload).hexdigest()
            if digest != expected:
                raise RuntimeError(f"hash mismatch for {filename}: {digest} != {expected}")
            temporary = destination.with_suffix(destination.suffix + ".part")
            temporary.write_bytes(payload)
            temporary.replace(destination)
        manifest.append(
            f"{record['repo']}\t{record['name']}\t{record['version']}\t{expected}\t{filename}"
        )

    (args.output / "packages.manifest").write_text("\n".join(manifest) + "\n")
    print(f"resolved {len(closure)} packages")
    for line in manifest:
        print(line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
