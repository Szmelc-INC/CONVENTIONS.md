---
id: conventions.specs.original.format-1.0
---
# Conventions Format 1.0
> Load when: implementing, validating, or changing the Conventions Format 1.0 document contract.

## Status and language

This document defines Conventions Format 1.0, a repository-independent format for collections of Markdown instruction rules, indexes, profiles, and overlays. The format version describes this document contract. A repository's release version describes that repository's releases and is independent of the format version.

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **NOT RECOMMENDED**, **MAY**, and **OPTIONAL** in this document are to be interpreted as described in BCP 14 (RFC 2119 and RFC 8174) when, and only when, they appear in uppercase.

An implementation conforms to version 1.0 when it follows all applicable MUST and MUST NOT requirements in this document. SHOULD-level recommendations permit a documented, reasoned exception. This document does not require a particular programming language, parser library, or host agent.

## Format versioning

Every format manifest or index that declares a format version MUST use `format_version: "1.0"` for this version. A format version MUST NOT be inferred from a repository version, release tag, directory name, or schema version. A repository MAY contain rules in this format without publishing a manifest; in that case its format version is declared by its documentation or distribution metadata.

The format version follows `MAJOR.MINOR`. A major increment denotes an incompatible change to required parsing, data model, or interpretation. A minor increment denotes an additive change that a 1.0 reader can safely ignore. A correction that does not change conforming input or interpretation MAY be published without changing the format version. Readers MUST reject an unsupported major version. Readers of 1.0 MAY ignore unknown optional fields; they MUST NOT reinterpret a known field based on the repository's release version.

Rule `id` values identify rules, not releases or file locations. An ID MUST be unique within a collection, MUST remain unchanged when the rule is moved or retitled, and MUST NOT be reused after removal. The format does not prescribe a globally unique namespace across unrelated repositories.

## Rule files

A rule is a UTF-8 Markdown file with a first-level heading, a `Load when` line, and zero or one YAML front matter block. A rule file MUST begin either with `# ` or with a front matter delimiter at the start of the file. If present, the front matter MUST be the first block and MUST close before the Markdown body. After front matter, the first nonblank content line MUST be `# <title>` and the next nonblank line MUST be `> Load when: <expression>`.

The title and trigger line MUST each occupy one physical line. The title MUST be non-empty. The trigger expression MUST be non-empty. A rule MUST have a stable `id` in front matter when it is indexed as stable or experimental. A collection MUST reject duplicate IDs.

Front matter is a format convention layered over YAML; YAML itself does not define Markdown front matter. The opening and closing delimiters are lines containing exactly three ASCII hyphen-minus characters (`---`), with no surrounding whitespace. The enclosed content MUST parse as exactly one YAML mapping. It MUST use the YAML 1.2.2 core schema as restricted below. Duplicate mapping keys, aliases, anchors, explicit tags, merge keys, multiple YAML documents, and non-JSON values (including timestamps, binary values, and non-finite numbers) are invalid. Scalars MUST be interpreted as strings, booleans, null, or finite JSON numbers; implementations MUST NOT apply YAML 1.1 implicit boolean or date coercions.

The following keys are defined:

| Key | Type | Meaning |
|---|---|---|
| `id` | string | Stable rule identifier; REQUIRED for indexed stable and experimental rules. |
| `status` | string | Optional lifecycle label: `stable`, `experimental`, or `legacy`. Directory or collection policy MAY define status when omitted. |
| `scope` | array of strings | Optional repository-relative path globs to which the rule applies. |
| `tools` | array of strings | Optional host or tool identifiers for which the rule is intended. These labels do not guarantee host support. |
| `tags` | array of strings | Optional topic labels. |
| `since` | string | Optional format or collection release identifier that introduced the rule. It is informational and MUST NOT change parsing. |
| `supersedes` | array of strings | Optional IDs of rules this rule replaces. This records a relationship; it does not itself delete or disable those rules. |

An ID MUST match `[a-z0-9]+([.-][a-z0-9]+)*`. `scope`, `tools`, `tags`, and `supersedes` MUST contain only non-empty strings and MUST NOT contain duplicate values. Unknown front matter keys are extensions: a 1.0 reader MUST preserve or ignore them without assigning meaning. Producers SHOULD use a reverse-domain or repository-qualified prefix for extension keys to reduce collisions.

### Path glob syntax

All paths and patterns use `/` as the separator, regardless of the host operating system. A pattern is relative to the collection root, MUST NOT begin with `/`, and MUST NOT contain a `..` path segment. Matching is case-sensitive and is performed against a normalized relative path with `.` segments removed. Backslash is an ordinary character and MUST NOT be treated as a separator or escape.

The glob operators are `*` (zero or more characters other than `/`), `?` (exactly one character other than `/`), bracket classes such as `[abc]` and ranges such as `[a-z]` (one character other than `/`), and `**` (zero or more characters including `/`). A `**` operator has this meaning wherever it appears. A bracket class MUST be closed and non-empty; `!` as its first character negates the class. All other characters match themselves. Implementations MUST apply the same rules to `scope` patterns and `glob` trigger atoms.

### Trigger expression

The text after `> Load when:` is a trigger expression. Its purpose is to let a reader decide whether to load a rule. The expression uses the following ABNF (RFC 5234); literal names are case-sensitive, while the payload of `keyword` and `task` is case-insensitive:

```abnf
expression = ws atom *(ws ("AND" / "OR") ws atom) ws
atom       = keyword / glob / task / text
keyword    = "keyword(" quoted ")"
glob       = "glob(" quoted ")"
task       = "task(" quoted ")"
text       = "text(" quoted ")"
quoted     = DQUOTE 1*(qchar / escape) DQUOTE
qchar      = %x20-21 / %x23-5B / %x5D-7E / UTF8-OCTET
escape     = %x5C (DQUOTE / %x5C)
ws         = *(SP / HTAB)
DQUOTE     = %x22
SP         = %x20
HTAB       = %x09
UTF8-OCTET = %x80-FF
```

The ABNF is applied to UTF-8 octets. The complete trigger line MUST also be valid UTF-8; `UTF8-OCTET` does not by itself validate a multibyte sequence.

`AND` binds more tightly than `OR`; parentheses and implicit operators are not part of version 1.0. A `keyword` atom matches a whole case-insensitive token in the user's task text. A `task` atom matches a whole case-insensitive task-class token supplied by the caller (for example, `build`, `review`, or `documentation`); the format does not prescribe a universal task-class vocabulary. A `glob` atom matches a repository-relative path under the path-glob rules above and is true if it matches any path in the task context. A `text` atom is descriptive natural-language guidance evaluated by the consuming agent; it has no deterministic string-matching algorithm. An expression is a candidate to load when it evaluates true. A consumer that cannot evaluate one or more atom types MAY use the complete trigger line as a natural-language hint, but MUST NOT claim deterministic matching for those atoms.

For backward compatibility with existing collections, version 1.0 readers MAY accept a non-empty trigger line that is not a valid expression as a legacy natural-language trigger. Producers of new 1.0 rule files SHOULD use the explicit atom syntax. Legacy trigger lines are hints only and do not have deterministic matching semantics.

## Cores and maps

A core is a named collection of rules and supporting documents. A core map is a Markdown file that lists paths, short descriptions, and load triggers for the collection. Map generation and directory layout are repository choices; this format does not require a particular build script.

When a collection provides `INDEX.md`, it MUST be UTF-8 Markdown and SHOULD contain a concise instruction for reading the index, then sections for always-loaded entry points, cores, stable rules, skills, experimental material, and legacy material as applicable. Each listed path MUST be relative to the collection root and MUST identify one entry. An index MUST distinguish experimental entries from stable rules and MUST mark legacy entries as archival. Human-readable indexes MAY omit fields that are present in `index.json`.

Generated maps and indexes SHOULD carry a notice identifying them as generated and pointing to their authoritative sources. Consumers MUST treat such generated files as read-only outputs when source files are available.

## `index.json` version 2

`index.json` is a UTF-8 JSON object. A version 2 index MUST include a `$schema` string, `name`, `repo`, `entries`, `compatible_disclaimer`, and `compatible`. It MAY include `format_version`; when present, its value MUST be `"1.0"`. Collections SHOULD include this member. A collection that omits it MUST declare its format version in distribution metadata or documentation. `$schema` identifies the schema used to validate this JSON instance; it does not declare the Conventions format version. `name` is the collection's short name. `repo` is its canonical repository URI.

`entries` is an ordered array. Every entry MUST include `path`, `title`, `load_when`, `status`, and `kind`. `path` is a unique normalized relative path with `/` separators and no `.` or `..` segments. `title` and `load_when` are non-empty strings. `status` is one of `always`, `stable`, `experimental`, or `legacy`. `kind` is one of `global`, `core`, `skill`, `rule`, or `archive`. A `rule` entry MUST include its front matter `id`; other entry kinds MAY include `id` only when the collection defines its meaning. An entry MAY include `origin` (`third-party` or `original`) and `compat`, an array of compatibility-record IDs.

`compatible_disclaimer` is a string. `compatible` is an ordered array of compatibility records. Each record MUST contain `id`, `name`, `kind`, `description`, `version`, `added`, `updated`, `spec`, and `links`. `kind` is one of `format`, `spec`, `platform`, `tool`, `language`, or `stack`; `spec` is an array of collection-relative rule paths; `links` is an object whose optional keys are `homepage`, `repo`, `docs`, and `community`, each a URI string. `icon` MAY be a collection-relative asset path. Record IDs MUST be unique within the array. Dates in `added` and `updated` MUST use the full-date form `YYYY-MM-DD`.

JSON object member order is insignificant. Array order is significant and MUST be preserved by readers. Unknown object members MAY be ignored by a 1.0 reader. JSON strings MUST use UTF-8 and valid JSON escaping. A consumer MUST reject malformed JSON and invalid required values. This section defines the v2 data contract; it does not assert that a JSON Schema or reference validator is currently published.

## Profiles and overlays

A profile supplies collection-specific values such as project name, URLs, paths, and display settings. Profiles are data, not executable instructions. A profile's values MUST NOT alter the meaning of format fields or the trigger grammar. A profile MAY define additional string-valued variables for template rendering.

An overlay applies a bounded set of overrides to a selected profile. The 1.0 TOML overlay model has `[overrides]` with optional `disable = ["<rule-id>", ...]`, and optional `[overrides.set]` with string-valued `profile.<key> = "<value>"` entries. An overlay MUST disable rules by stable ID, never by path. It MUST NOT introduce or rewrite rule content. A collection MAY define a precedence order; when it supports the common layers, the order is base profile, organization profile, team overlay, project overlay, then user overlay. Later string assignments replace earlier values. Disabled IDs are cumulative: once disabled, a later overlay cannot re-enable the rule. A renderer MUST reject an ID that does not exist in the selected collection.

The format does not prescribe how a host discovers, activates, combines, or prioritizes profiles or overlays. A collection MUST document any precedence beyond these rules.

## Host behavior and interoperability boundary

The format defines portable document content and selectors. It does not guarantee that any agent host discovers a file, follows nested directories, honors a particular glob field, activates a rule on demand, or resolves conflicts in a common way. A host MAY require an adapter that translates the format into its native instruction mechanism. Adapters MUST preserve rule meaning to the extent the target host can express it and SHOULD report unsupported selectors instead of silently presenting them as guaranteed behavior.

Automatic discovery paths, context-size limits, instruction precedence, skills installation, adapter output, and runtime rule selection are out of scope. A collection's documentation MUST state host-specific behavior it relies on.

## Prose license

The normative prose of this specification is licensed under the repository's MIT License, the same license as the surrounding project. A collection that adopts this format MAY choose another license for its own prose; conformance to the format does not transfer ownership or licensing of rule content.

## References

- [RFC 2119: Key words for use in RFCs to Indicate Requirement Levels](https://www.rfc-editor.org/rfc/rfc2119.html)
- [RFC 8174: Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words](https://www.rfc-editor.org/rfc/rfc8174.html)
- [RFC 5234: Augmented BNF for Syntax Specifications](https://www.rfc-editor.org/rfc/rfc5234.html)
- [YAML 1.2.2 Specification](https://yaml.org/spec/1.2.2/)
- [JSON Schema Draft 2020-12](https://json-schema.org/specification)
- [Semantic Versioning 2.0.0](https://semver.org/)
