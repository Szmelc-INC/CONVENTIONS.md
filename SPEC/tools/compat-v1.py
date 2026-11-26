#!/usr/bin/env python3
"""Normalize the supported v1 index shape to Format 1.0 index v2."""
import json
import sys

old = json.load(open(sys.argv[1], encoding="utf-8"))
entries = []
for item in old.get("entries", []):
    kind = item.get("kind", "rule")
    mapped = {key: item[key] for key in ("path", "title", "load_when", "status") if key in item}
    mapped["kind"] = kind
    if kind == "rule" and "id" in item:
        mapped["id"] = item["id"]
    entries.append(mapped)
new = {
    "$schema": "https://szmelc-inc.github.io/CONVENTIONS.md/SPEC/schemas/index-v2.schema.json",
    "format_version": "1.0", "name": old.get("name", "migrated"), "repo": old.get("repo", "https://example.invalid/"),
    "entries": entries, "compatible_disclaimer": old.get("compatible_disclaimer", ""), "compatible": old.get("compatible", [])
}
json.dump(new, sys.stdout, indent=2, ensure_ascii=False)
sys.stdout.write("\n")
