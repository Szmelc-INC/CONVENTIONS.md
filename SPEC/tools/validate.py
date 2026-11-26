#!/usr/bin/env python3
"""Validate Format 1.0 JSON fixtures and indexed collections."""
from __future__ import annotations

import json
import pathlib
import argparse
import sys

try:
    from jsonschema import Draft202012Validator, FormatChecker
    from referencing import Registry, Resource
except ImportError as exc:
    raise SystemExit("Install jsonschema 4.x to run the Format 1.0 validator") from exc

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCHEMAS = ROOT / "SPEC" / "schemas"
NAMES = {"front-matter": "front-matter.schema.json", "index-v2": "index-v2.schema.json",
         "profile": "profile.schema.json", "compat-registry": "compat-registry.schema.json"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--index", action="append", type=pathlib.Path, default=[])
    parser.add_argument("--root", action="append", type=pathlib.Path, default=[])
    args = parser.parse_args()
    schemas = {key: json.loads((SCHEMAS / filename).read_text()) for key, filename in NAMES.items()}
    registry = Registry()
    for schema in schemas.values():
        Draft202012Validator.check_schema(schema)
        registry = registry.with_resource(schema["$id"], Resource.from_contents(schema))
    validators = {key: Draft202012Validator(schema, registry=registry, format_checker=FormatChecker())
                  for key, schema in schemas.items()}
    failures = []
    for expected, directory in ((True, "valid"), (False, "invalid")):
        for path in sorted((ROOT / "SPEC" / "tests" / directory).glob("*.json")):
            fixture = json.loads(path.read_text())
            name = fixture["schema"]
            errors = list(validators[name].iter_errors(fixture["value"]))
            passed = not errors
            if passed != expected:
                details = "; ".join(error.message for error in errors[:3]) or "unexpectedly valid"
                failures.append(f"{path.relative_to(ROOT)}: {details}")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("Format 1.0 reference validator: all fixtures passed")
    roots = args.root or [pathlib.Path.cwd()] * len(args.index)
    if len(roots) != len(args.index):
        parser.error("provide one --root for each --index, or omit all roots")
    for path, root in zip(args.index, roots):
        data = json.loads(path.read_text(encoding="utf-8"))
        errors = list(validators["index-v2"].iter_errors(data))
        if errors:
            print(f"{path}: " + "; ".join(error.message for error in errors[:3]), file=sys.stderr)
            return 1
        root = root.resolve()
        seen_ids: set[str] = set()
        seen_paths: set[str] = set()
        compatibility_ids = {record["id"] for record in data["compatible"]}
        if len(compatibility_ids) != len(data["compatible"]):
            print(f"{path}: duplicate compatibility record id", file=sys.stderr)
            return 1
        for entry in data["entries"]:
            rel = pathlib.PurePosixPath(entry["path"])
            if rel.is_absolute() or any(part in {"", ".", ".."} for part in rel.parts) or "\\" in entry["path"]:
                print(f"{path}: unsafe collection path {entry['path']!r}", file=sys.stderr)
                return 1
            if entry["path"] in seen_paths:
                print(f"{path}: duplicate entry path {entry['path']!r}", file=sys.stderr)
                return 1
            seen_paths.add(entry["path"])
            target = (root / pathlib.Path(*rel.parts)).resolve()
            if root not in target.parents or not target.is_file():
                print(f"{path}: missing or escaped entry path {entry['path']!r}", file=sys.stderr)
                return 1
            if entry["kind"] == "rule":
                if entry["id"] in seen_ids:
                    print(f"{path}: duplicate rule id {entry['id']!r}", file=sys.stderr)
                    return 1
                seen_ids.add(entry["id"])
            for compat_id in entry.get("compat", []):
                if compat_id not in compatibility_ids:
                    print(f"{path}: unknown compatibility id {compat_id!r}", file=sys.stderr)
                    return 1
        for record in data["compatible"]:
            for spec in record["spec"]:
                target = (root / spec).resolve()
                if root not in target.parents or not target.is_file():
                    print(f"{path}: missing or escaped compatibility path {spec!r}", file=sys.stderr)
                    return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
