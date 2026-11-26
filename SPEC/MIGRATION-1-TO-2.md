# Migrating index v1 to v2

Index v2 is the first version with a declared `format_version` and an explicit `kind` on every entry.

1. Preserve each v1 entry's `path`, `title`, `load_when`, and `status` values.
2. Add `kind`: use `rule` for rule files and choose `core`, `skill`, `global`, or `archive` for their corresponding entry types.
3. Add the stable front matter `id` to every stable or experimental rule and copy it to its index entry.
4. Add `format_version: "1.0"` and the stable index v2 `$schema` URL.
5. Move compatibility records into `compatible` and keep the disclaimer in `compatible_disclaimer`.
6. Validate against `SPEC/schemas/index-v2.schema.json` and the conformance fixtures.

During one repository major release, a compatibility shim MAY read a v1 index and normalize it in memory to v2. The shim MUST NOT write a v2 object while labeling it v1. The shipped `SPEC/tools/compat-v1.py` normalizes the known v1 fields; remove it after the one-major migration window.
