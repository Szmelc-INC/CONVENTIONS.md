#!/usr/bin/env python3
"""Compile an index v2 into per-rule native instruction artifacts."""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import shlex


def quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def rule_meta(path: pathlib.Path) -> tuple[list[str], str]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return [], text
    try:
        end = lines.index("---", 1)
    except ValueError as exc:
        raise ValueError(f"{path}: unclosed front matter") from exc
    front = lines[1:end]
    scopes: list[str] = []
    in_scope = False
    for line in front:
        if line == "scope:":
            in_scope = True
        elif line and not line[0].isspace():
            in_scope = False
        elif in_scope:
            match = re.fullmatch(r'\s+-\s+["\']?([^"\']+)["\']?', line)
            if match:
                scopes.append(match.group(1))
    return scopes, "\n".join(lines[end + 1:]).strip() + "\n"


def scope_directory(pattern: str) -> pathlib.PurePosixPath | None:
    """Return a safe static directory prefix for a host with nested instruction files."""
    path = pathlib.PurePosixPath(pattern)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError(f"unsafe scope glob: {pattern}")
    parts = []
    for part in path.parts:
        if any(char in part for char in "*?[]{}"):
            break
        parts.append(part)
    return pathlib.PurePosixPath(*parts) if parts else None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--index", type=pathlib.Path, default=pathlib.Path("index.json"))
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path("."))
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args()
    index_path = args.index.resolve()
    root = args.root.resolve()
    index = json.loads(index_path.read_text(encoding="utf-8"))
    if index.get("format_version") != "1.0":
        raise SystemExit("compile.py requires index format_version 1.0")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    rules = []
    for entry in index.get("entries", []):
        if entry.get("kind") != "rule" or entry.get("status") not in {"stable", "experimental"}:
            continue
        rule_path = (root / entry["path"]).resolve()
        if root not in rule_path.parents or not rule_path.is_file():
            raise SystemExit(f"unsafe or missing rule path: {entry['path']}")
        source_copy = output / "sources" / entry["path"]
        source_copy.parent.mkdir(parents=True, exist_ok=True)
        source_copy.write_bytes(rule_path.read_bytes())
        scopes, body = rule_meta(rule_path)
        rule_id = entry["id"]
        if not re.fullmatch(r"[a-z0-9]+([.-][a-z0-9]+)*", rule_id):
            raise SystemExit(f"invalid rule id: {rule_id}")
        rules.append((entry, scopes, body))

    catalog = ["# Rule catalog", "", "Load the matching rule file only when its trigger or scope applies.", ""]
    for entry, _, _ in rules:
        catalog.append(f"- [{entry['title']}](sources/{entry['path']}) — {entry['load_when']} (ID: `{entry['id']}`)")
    catalog_text = "\n".join(catalog) + "\n"
    (output / "AGENTS.md").write_text(catalog_text, encoding="utf-8")
    (output / "GEMINI.md").write_text("# Rule catalog\n\nUse the indexed rule files below when their trigger applies. Scoped rules are emitted as nested `GEMINI.md` files for just-in-time discovery.\n\n" + catalog_text, encoding="utf-8")
    pack_name = re.sub(r"[^a-z0-9-]+", "-", index["name"].lower()).strip("-")
    skill_description = f"Portable rule pack {index['name']}. Select a rule from its trigger catalog and load only that rule."
    skill_text = f"---\nname: {pack_name}\ndescription: {quote(skill_description)}\n---\n\n# {index['name']} conventions pack\n\nRead `AGENTS.md` to find the matching rule. Load only the rule whose trigger matches the task.\n\n{catalog_text}"
    skill_target = output / ".agents" / "skills" / pack_name / "SKILL.md"
    skill_target.parent.mkdir(parents=True, exist_ok=True)
    skill_target.write_text(skill_text, encoding="utf-8")
    aider = ["# On-demand aider reads", "", "`aider --read` adds selected read-only files to context. It has no native trigger selector. Choose one command per task; do not configure all rules as always-on.", ""]
    aider_cmds = []
    for entry, scopes, body in rules:
        rid, trigger = entry["id"], entry["load_when"]
        source_link = f"Source: `sources/{entry['path']}` · ID: `{rid}` · Load when: {trigger}\n\n"
        common = source_link + body
        (output / "aider-read" / f"{rid}.md").parent.mkdir(parents=True, exist_ok=True)
        (output / "aider-read" / f"{rid}.md").write_text(common, encoding="utf-8")
        aider.append(f"- `{rid}` — {trigger}: `aider --read {shlex.quote('sources/' + entry['path'])}`")
        aider_cmds.append(f"aider --read {shlex.quote('sources/' + entry['path'])}")
        globs = json.dumps(scopes, ensure_ascii=False)
        cursor_front = f"description: {quote(trigger)}\n" + (f"globs: {globs}\n" if scopes else "") + "alwaysApply: false"
        cursor = f"---\n{cursor_front}\n---\n\n" + common
        target = output / ".cursor" / "rules" / f"{rid}.mdc"
        target.parent.mkdir(parents=True, exist_ok=True); target.write_text(cursor, encoding="utf-8")
        if scopes:
            copilot = f"---\napplyTo: {quote(','.join(scopes))}\n---\n\n" + common
            target = output / ".github" / "instructions" / f"{rid}.instructions.md"
            target.parent.mkdir(parents=True, exist_ok=True); target.write_text(copilot, encoding="utf-8")
        else:
            target = output / "on-demand" / "copilot" / f"{rid}.instructions.md"
            target.parent.mkdir(parents=True, exist_ok=True); target.write_text(common, encoding="utf-8")
        kiro_mode = "fileMatch" if scopes else "auto"
        kiro = (f"---\ninclusion: fileMatch\nfileMatchPattern: {quote(','.join(scopes))}\n---\n\n" if scopes
                else f"---\ninclusion: auto\nname: {rid}\ndescription: {quote(trigger)}\n---\n\n") + common
        target = output / ".kiro" / "steering" / f"{rid}.md"
        target.parent.mkdir(parents=True, exist_ok=True); target.write_text(kiro, encoding="utf-8")
        windsurf_mode = "glob" if scopes else "model_decision"
        windsurf = f"---\ntrigger: {windsurf_mode}\nglobs: {globs}\ndescription: {quote(trigger)}\n---\n\n" + common
        target = output / ".windsurf" / "rules" / f"{rid}.md"
        target.parent.mkdir(parents=True, exist_ok=True); target.write_text(windsurf, encoding="utf-8")
        if scopes:
            cline = f"---\npaths:\n" + "".join(f"  - {quote(scope)}\n" for scope in scopes) + "---\n\n" + common
            target = output / ".clinerules" / f"{rid}.md"
            target.parent.mkdir(parents=True, exist_ok=True); target.write_text(cline, encoding="utf-8")
        else:
            target = output / "on-demand" / "cline" / f"{rid}.md"
            target.parent.mkdir(parents=True, exist_ok=True); target.write_text(common, encoding="utf-8")
        cont_front = f"name: {rid}\ndescription: {quote(trigger)}\n" + (f"globs: {globs}\n" if scopes else "") + "alwaysApply: false"
        cont = f"---\n{cont_front}\n---\n\n" + common
        target = output / ".continue" / "rules" / f"{rid}.md"
        target.parent.mkdir(parents=True, exist_ok=True); target.write_text(cont, encoding="utf-8")
        for scope in scopes:
            directory = scope_directory(scope)
            if directory is None:
                continue
            nested = output / directory / "AGENTS.md"
            gemini = output / directory / "GEMINI.md"
            nested.parent.mkdir(parents=True, exist_ok=True)
            header = f"# Scoped rules for `{directory}`\n\n"
            snippet = f"## {entry['title']}\n\n{common}"
            for target in (nested, gemini):
                previous = target.read_text(encoding="utf-8") if target.exists() else header
                target.write_text(previous + snippet + "\n", encoding="utf-8")
    (output / "aider-read.md").write_text("\n".join(aider) + "\n", encoding="utf-8")
    (output / "aider-read-commands.txt").write_text("\n".join(aider_cmds) + "\n", encoding="utf-8")
    print(f"compiled {len(rules)} rules to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
