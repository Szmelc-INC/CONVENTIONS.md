#!/usr/bin/env python3
"""Validate Format 1.0 JSON fixtures and indexed collections."""
from __future__ import annotations

import json
import pathlib
import argparse
import copy
import math
import re
import sys

try:
    from jsonschema import Draft202012Validator, FormatChecker
    from referencing import Registry, Resource
    import yaml
except ImportError as exc:
    raise SystemExit("Install jsonschema 4.x to run the Format 1.0 validator") from exc

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCHEMAS = ROOT / "SPEC" / "schemas"
NAMES = {"front-matter": "front-matter.schema.json", "index-v2": "index-v2.schema.json",
         "profile": "profile.schema.json", "compat-registry": "compat-registry.schema.json"}


class UniqueKeyLoader(yaml.SafeLoader):
    pass


UniqueKeyLoader.yaml_implicit_resolvers = copy.deepcopy(yaml.SafeLoader.yaml_implicit_resolvers)
for first, resolvers in list(UniqueKeyLoader.yaml_implicit_resolvers.items()):
    UniqueKeyLoader.yaml_implicit_resolvers[first] = [
        item for item in resolvers if item[0] not in {
            "tag:yaml.org,2002:bool", "tag:yaml.org,2002:int", "tag:yaml.org,2002:float", "tag:yaml.org,2002:timestamp"
        }
    ]
UniqueKeyLoader.add_implicit_resolver(
    "tag:yaml.org,2002:bool", re.compile(r"^(?:true|True|TRUE|false|False|FALSE)$"), list("tTfF")
)
UniqueKeyLoader.add_implicit_resolver(
    "tag:yaml.org,2002:int",
    re.compile(r"^[-+]?(?:0|[1-9][0-9_]*|0o[0-7_]+|0x[0-9a-fA-F_]+|0b[01_]+)$"),
    list("-+0123456789")
)
UniqueKeyLoader.add_implicit_resolver(
    "tag:yaml.org,2002:float",
    re.compile(r"^(?:[-+]?(?:[0-9][0-9_]*)?\.[0-9_]+(?:[eE][-+]?[0-9]+)?|[-+]?[0-9][0-9_]*[eE][-+]?[0-9]+|[-+]?\.(?:inf|Inf|INF|nan|NaN|NAN))$"),
    list("-+0123456789.")
)


def construct_mapping(loader, node, deep=False):
    mapping = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if not isinstance(key, str):
            raise ValueError("YAML mapping keys must be strings")
        if key in mapping:
            raise ValueError(f"duplicate YAML key: {key}")
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


UniqueKeyLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping)


def check_json_values(value):
    if value is None or isinstance(value, (str, bool, int)):
        return
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError("non-finite YAML numbers are forbidden")
        return
    if isinstance(value, list):
        for item in value:
            check_json_values(item)
        return
    if isinstance(value, dict):
        for key, item in value.items():
            if not isinstance(key, str):
                raise ValueError("YAML mapping keys must be strings")
            check_json_values(item)
        return
    raise ValueError(f"non-JSON YAML value: {type(value).__name__}")


def safe_relative(value: str) -> bool:
    return bool(value) and not value.startswith("/") and all(part not in {"", ".", ".."} for part in value.split("/"))


def check_glob(value: str) -> None:
    if not safe_relative(value):
        raise ValueError(f"unsafe glob: {value}")
    i = 0
    while i < len(value):
        if value[i] == "[":
            end = value.find("]", i + 1)
            if end < 0 or end == i + 1 or (value[i + 1] == "!" and end == i + 2):
                raise ValueError(f"invalid bracket class in glob: {value}")
            i = end
        elif value[i] == "]":
            raise ValueError(f"unmatched bracket in glob: {value}")
        i += 1


ATOM = re.compile(r'(keyword|glob|task|text)\("((?:[^"\\]|\\["\\])+)"\)')
TOKEN = re.compile(r'\s*(keyword|glob|task|text)\("((?:[^"\\]|\\["\\])+)"\)|(AND|OR)')


def check_trigger(expression: str) -> None:
    if not expression.strip():
        raise ValueError("empty trigger expression")
    pos = 0
    tokens = []
    while pos < len(expression):
        match = TOKEN.match(expression, pos)
        if not match:
            if not tokens and not re.match(r"(?:keyword|glob|task|text)\s*\(", expression):
                return  # Legacy natural-language trigger.
            raise ValueError(f"invalid trigger expression: {expression}")
        if match.group(1):
            tokens.append(("atom", match.group(1), match.group(2)))
        else:
            tokens.append(("op", match.group(3)))
        pos = match.end()
    expect_atom = True
    for token in tokens:
        if expect_atom != (token[0] == "atom"):
            raise ValueError(f"invalid trigger operator sequence: {expression}")
        expect_atom = not expect_atom
        if token[0] == "atom" and token[1] == "glob":
            check_glob(token[2])
    if expect_atom:
        raise ValueError(f"trigger expression ends with an operator: {expression}")


def parse_rule(path: pathlib.Path, front_validator, root: pathlib.Path) -> dict:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    metadata = {}
    body_lines = lines
    if lines and lines[0] == "---":
        try:
            end = lines.index("---", 1)
        except ValueError as exc:
            raise ValueError("unclosed YAML front matter") from exc
        front_text = "\n".join(lines[1:end])
        for token in yaml.scan(front_text, Loader=UniqueKeyLoader):
            if isinstance(token, (yaml.tokens.AnchorToken, yaml.tokens.AliasToken, yaml.tokens.TagToken)):
                raise ValueError("YAML anchors, aliases, and explicit tags are forbidden")
            if isinstance(token, yaml.tokens.ScalarToken) and token.value == "<<":
                raise ValueError("YAML merge keys are forbidden")
        documents = list(yaml.load_all(front_text, Loader=UniqueKeyLoader))
        if len(documents) != 1 or not isinstance(documents[0], dict):
            raise ValueError("front matter must be exactly one YAML mapping")
        metadata = documents[0]
        check_json_values(metadata)
        body_lines = lines[end + 1:]
    errors = list(front_validator.iter_errors(metadata))
    if errors:
        raise ValueError("front matter schema: " + "; ".join(error.message for error in errors[:3]))
    content = [line for line in body_lines if line.strip()]
    if len(content) < 2 or not content[0].startswith("# ") or not content[0][2:].strip():
        raise ValueError("expected a non-empty first-level title")
    if not content[1].startswith("> Load when: "):
        raise ValueError("expected `> Load when:` after the title")
    trigger = content[1][len("> Load when: "):]
    check_trigger(trigger)
    for field in ("scope",):
        for glob in metadata.get(field, []):
            check_glob(glob)
    if "locales" in metadata:
        tags = set()
        for pair in metadata["locales"].split():
            tag, separator, locale_path = pair.partition("=")
            if not separator or not re.fullmatch(r"(?:[A-Za-z]{2,3}|[A-Za-z]{4}|[A-Za-z]{5,8})(?:-[A-Za-z0-9]{1,8})*", tag):
                raise ValueError(f"invalid locale pair: {pair}")
            if tag.lower() in tags:
                raise ValueError(f"duplicate locale tag: {tag}")
            tags.add(tag.lower())
            if not safe_relative(locale_path):
                raise ValueError(f"unsafe locale path: {locale_path}")
            companion = (root / locale_path).resolve()
            if root.resolve() not in companion.parents or not companion.is_file() or companion == path.resolve():
                raise ValueError(f"missing, escaped, or self-referencing locale path: {locale_path}")
    return metadata


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
        rule_dir = ROOT / "SPEC" / "tests" / directory / "rules"
        for path in sorted(rule_dir.glob("*.md")) if rule_dir.exists() else []:
            try:
                parse_rule(path, validators["front-matter"], path.parent)
                passed = True
            except (ValueError, UnicodeError, yaml.YAMLError) as exc:
                passed = False
                details = str(exc)
            if passed != expected:
                failures.append(f"{path.relative_to(ROOT)}: {details if not passed else 'unexpectedly valid'}")
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
            raw_parts = entry["path"].split("/")
            if entry["path"].startswith("/") or any(part in {"", ".", ".."} for part in raw_parts):
                print(f"{path}: non-normalized collection path {entry['path']!r}", file=sys.stderr)
                return 1
            rel = pathlib.PurePosixPath(entry["path"])
            if rel.is_absolute() or "\\" in entry["path"]:
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
                try:
                    metadata = parse_rule(target, validators["front-matter"], root)
                except (ValueError, UnicodeError, yaml.YAMLError) as exc:
                    print(f"{path}: {entry['path']}: {exc}", file=sys.stderr)
                    return 1
                if metadata.get("id") != entry.get("id"):
                    print(f"{path}: {entry['path']}: front matter id does not match index id", file=sys.stderr)
                    return 1
                rule_lines = target.read_text(encoding="utf-8").splitlines()
                trigger_line = next((line for line in rule_lines if line.startswith("> Load when: ")), "")
                if trigger_line[len("> Load when: "):] != entry["load_when"]:
                    print(f"{path}: {entry['path']}: trigger does not match index load_when", file=sys.stderr)
                    return 1
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
