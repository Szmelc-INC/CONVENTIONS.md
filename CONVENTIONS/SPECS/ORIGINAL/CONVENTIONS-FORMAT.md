---
id: conventions.specs.original.format-1.0
---
# Conventions Format 1.0
> Load when: implementing, validating, or changing the Conventions Format 1.0 document contract.

**Format 1.0** · [spec landing page](https://szmelc-inc.github.io/CONVENTIONS.md/SPEC/) · [schema set](https://szmelc-inc.github.io/CONVENTIONS.md/SPEC/schemas/)

## Status and language

This document defines Conventions Format 1.0, a repository-independent format for collections of Markdown instruction rules, indexes, profiles, and overlays. The format version describes this document contract. A repository's release version describes that repository's releases and is independent of the format version.

Interpret the key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **NOT RECOMMENDED**, **MAY**, and **OPTIONAL** as described in BCP 14 (RFC 2119 and RFC 8174). This meaning applies only when each term appears in uppercase.

An implementation conforms to version 1.0 when it follows all applicable MUST and MUST NOT requirements in this document. SHOULD-level recommendations permit a documented, reasoned exception. This document does not require a particular programming language, parser library, or host agent.

## Format versioning

Every format manifest or index that declares a format version MUST use `format_version: "1.0"` for this version. A format version MUST NOT be inferred from a repository version, release tag, directory name, or schema version. A repository MAY contain rules in this format without publishing a manifest. In that case its documentation or distribution metadata declares the format version.

The format version follows `MAJOR.MINOR`. A major increment denotes an incompatible change to required parsing, data model, or interpretation. A minor increment denotes an additive change that a 1.0 reader can safely ignore. A correction that does not change conforming input or interpretation MAY be published without changing the format version. Readers MUST reject an unsupported major version. Readers of 1.0 MAY ignore unknown optional fields. They MUST NOT reinterpret a known field based on the repository's release version.

Rule `id` values identify rules, not releases or file locations. An ID MUST be unique within a collection, MUST remain unchanged when the rule is moved or retitled, and MUST NOT be reused after removal. The format does not prescribe a globally unique namespace across unrelated repositories.

## Rule files

A rule is a UTF-8 Markdown file with a first-level heading, a `Load when` line, and zero or one YAML front matter block. A rule file MUST begin either with `# ` or with a front matter delimiter at the start of the file. If present, the front matter MUST be the first block and MUST close before the Markdown body. After front matter, the first nonblank content line MUST be `# <title>` and the next nonblank line MUST be `> Load when: <expression>`.

The title and trigger line MUST each occupy one physical line. The title MUST be non-empty. The trigger expression MUST be non-empty. A rule MUST have a stable `id` in front matter when it is indexed as stable or experimental. A collection MUST reject duplicate IDs.

Front matter is a format convention layered over YAML. YAML itself does not define Markdown front matter. The opening and closing delimiters are lines containing exactly three ASCII hyphen-minus characters (`---`), with no surrounding whitespace. The enclosed content MUST parse as exactly one YAML mapping. It MUST use the YAML 1.2.2 core schema as restricted below. Duplicate mapping keys, aliases, anchors, explicit tags, merge keys, multiple YAML documents, and non-JSON values (including timestamps, binary values, and non-finite numbers) are invalid. Scalars MUST be interpreted as strings, booleans, null, or finite JSON numbers. Implementations MUST NOT apply YAML 1.1 implicit boolean or date coercions.

The JSON Schema at `SPEC/schemas/front-matter.schema.json` validates the decoded mapping. It does not parse YAML or validate Markdown framing. A conforming validator MUST perform both steps.

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
| `locales` | string | Optional space-separated `<language-tag>=<path>` companion mappings. English stays canonical; each path is relative to the collection root and points to a companion document outside the indexed rule tree. |

An ID MUST match `[a-z0-9]+([.-][a-z0-9]+)*`. `scope`, `tools`, `tags`, and `supersedes` MUST contain only non-empty strings and MUST NOT contain duplicate values. Unknown front matter keys are extensions: a 1.0 reader MUST preserve or ignore them without assigning meaning. Producers SHOULD use a reverse-domain or repository-qualified prefix for extension keys to reduce collisions.

The `locales` value contains space-separated `tag=path` pairs. For example, use `locales: pl=translations/RULE-PL.md`. Tags MUST be valid BCP 47 language tags and unique after case-insensitive comparison. Paths MUST be safe collection-relative paths that exist. A path MUST NOT point to the canonical English rule. The canonical rule remains the source for IDs, triggers, status and scope. A consumer MAY show a language selector when companions exist. Missing languages MUST fall back to English. Companion files are not separate rules. They MUST NOT be indexed or included in an all-rules bundle.

## Schemas and conformance

The normative schemas are published under the stable site path `SPEC/schemas/`. A schema URL ending in `index-v2.schema.json` validates the index object. `front-matter.schema.json` validates a parsed rule metadata mapping. `profile.schema.json` validates the JSON profile interchange object. Source profiles MAY use another serialization, such as TOML. They MUST normalize to that object before validation. `compat-registry.schema.json` validates the compatibility registry interchange object and the `compatible` records embedded in an index. Schema URLs are immutable within a format major version. A breaking schema change requires a new major-version directory and identifier.

Schemas validate data shape, not all format semantics. A conforming implementation MUST additionally check unique rule IDs and paths, references to existing files, front-matter delimiters, heading/trigger order, path glob safety, and valid trigger syntax. The reference suite in `SPEC/tests/` includes both valid and invalid inputs. A validator MUST reject every invalid fixture and accept every valid fixture. Implementations SHOULD add fixtures for edge cases they discover.

## Interoperability and native adapters

An adapter compiles each rule independently and retains its stable `id`, title, trigger, optional scope and body. It MUST NOT silently turn every lazy rule into an always-on instruction. Where a host has no native lazy selector, the adapter MUST state that limitation and emit an on-demand reference or a clearly labelled one-shot bundle. The supported mappings and limits are recorded in `SPEC/INTEROP.md`.

Each generated output MUST include enough source information to trace it to the originating rule. An implementation MUST escape metadata for the target format and MUST treat the Markdown body as data, not as a template. It MUST NOT evaluate shell syntax or interpolate rule content into commands.

## Change process

Format changes begin as a GitHub Discussion tagged RFC. An accepted proposal is published under `CONVENTIONS/EXPERIMENTAL/` with an owner, rationale, compatibility notes and a decision record under `SPEC/decisions/`. After review and conformance fixtures, a proposal MAY move to stable. The decision record states accepted alternatives and migration impact. A change to the meaning of a 1.0 field is prohibited. Additive optional fields MAY be standardized as a compatible revision. Breaking semantics require Format 2.0.

## License

The specification prose is licensed under MIT, the same license as this repository. Implementations remain free to use any license. Reusers SHOULD preserve the copyright and license notice when copying prose.

### Path glob syntax

All paths and patterns use `/` as the separator, regardless of the host operating system. A pattern is relative to the collection root, MUST NOT begin with `/`, and MUST NOT contain a `..` path segment. Matching is case-sensitive and is performed against a normalized relative path with `.` segments removed. Backslash is an ordinary character and MUST NOT be treated as a separator or escape.

The glob operators are `*`, `?`, bracket classes, and `**`. `*` matches zero or more characters other than `/`. `?` matches one character other than `/`. Bracket classes such as `[abc]` or `[a-z]` match one character other than `/`. `**` matches zero or more characters including `/` wherever it appears. A bracket class MUST be closed and non-empty. An initial `!` negates the class. All other characters match themselves. Implementations MUST apply these rules to `scope` patterns and `glob` trigger atoms.

### Trigger expression

The text after `> Load when:` is a trigger expression. Its purpose is to let a reader decide whether to load a rule. The expression uses the following ABNF (RFC 5234). Literal names are case-sensitive. The payload of `keyword` and `task` is case-insensitive:

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

The ABNF is applied to UTF-8 octets. The complete trigger line MUST also be valid UTF-8. `UTF8-OCTET` does not by itself validate a multibyte sequence.

`AND` binds more tightly than `OR`. Parentheses and implicit operators are not part of version 1.0. A `keyword` atom matches a whole case-insensitive token in the user's task text. A `task` atom matches a whole case-insensitive task-class token supplied by the caller. Examples include `build`, `review`, and `documentation`. The format does not prescribe a universal task-class vocabulary. A `glob` atom matches a repository-relative path under the path-glob rules above. It is true if it matches any path in the task context. A `text` atom is descriptive natural-language guidance evaluated by the consuming agent. It has no deterministic string-matching algorithm. An expression is a candidate to load when it evaluates true. A consumer that cannot evaluate one or more atom types MAY use the complete trigger line as a natural-language hint. It MUST NOT claim deterministic matching for those atoms.

For backward compatibility with existing collections, version 1.0 readers MAY accept a non-empty trigger line that is not a valid expression as a legacy natural-language trigger. Producers of new 1.0 rule files SHOULD use the explicit atom syntax. Legacy trigger lines are hints only and do not have deterministic matching semantics.

## Cores and maps

A core is a named collection of rules and supporting documents. A core map is a Markdown file that lists paths, short descriptions, and load triggers. Map generation and directory layout are repository choices. This format does not require a particular build script.

When a collection provides `INDEX.md`, it MUST use UTF-8 Markdown. It SHOULD explain how to read the index. It SHOULD then list always-loaded entry points, cores, stable rules, skills, experimental material, and legacy material as applicable. Each listed path MUST be relative to the collection root and MUST identify one entry. An index MUST distinguish experimental entries from stable rules and MUST mark legacy entries as archival. Human-readable indexes MAY omit fields that are present in `index.json`.

Generated maps and indexes SHOULD carry a notice identifying them as generated and pointing to their authoritative sources. Consumers MUST treat such generated files as read-only outputs when source files are available.

## `index.json` version 2

`index.json` is a UTF-8 JSON object. A version 2 index MUST include a `$schema` string, `format_version`, `name`, `repo`, `entries`, `compatible_disclaimer`, and `compatible`. `format_version` MUST be `"1.0"`. `$schema` identifies the schema for this JSON instance. It does not declare the Conventions format version. `name` is the collection's short name. `repo` is its canonical repository URI.

`entries` is an ordered array. Every entry MUST include `path`, `title`, `load_when`, `status`, and `kind`. `path` is a unique normalized relative path with `/` separators and no `.` or `..` segments. `title` and `load_when` are non-empty strings. `status` is `always`, `stable`, `experimental`, or `legacy`. `kind` is `global`, `core`, `skill`, `rule`, or `archive`. A `rule` entry MUST include its front matter `id`. Other entry kinds MAY include `id` when the collection defines its meaning. An entry MAY include `origin` (`third-party` or `original`) and `compat`, an array of compatibility-record IDs.

`compatible_disclaimer` is a string. `compatible` is an ordered array of compatibility records. Each record MUST contain `id`, `name`, `kind`, `description`, `version`, `added`, `updated`, `spec`, and `links`. `kind` is `format`, `spec`, `platform`, `tool`, `language`, or `stack`. `spec` is an array of collection-relative rule paths. `links` is an object with optional URI keys: `homepage`, `repo`, `docs`, and `community`. `icon` MAY be a collection-relative asset path. Record IDs MUST be unique. Dates in `added` and `updated` MUST use the full-date form `YYYY-MM-DD`.

JSON object member order is insignificant. Readers MUST preserve array order. A 1.0 reader MAY ignore unknown object members. JSON strings MUST use UTF-8 and valid JSON escaping. A consumer MUST reject malformed JSON and invalid required values. The schemas and reference validator are published in `SPEC/`.

## Profiles and overlays

A profile supplies collection-specific values such as project name, URLs, paths, and display settings. Profiles are data, not executable instructions. A profile's values MUST NOT alter the meaning of format fields or the trigger grammar. A profile MAY define additional string-valued variables for template rendering.

An overlay applies a bounded set of overrides to a selected profile. The 1.0 TOML overlay model has `[overrides]` with optional `disable = ["<rule-id>", ...]`. It MAY also have `[overrides.set]` with string-valued `profile.<key> = "<value>"` entries. An overlay MUST disable rules by stable ID, never by path. It MUST NOT introduce or rewrite rule content. A collection MAY define precedence. When it supports common layers, use this order: base profile, organization profile, team overlay, project overlay, then user overlay. Later string assignments replace earlier values. Disabled IDs are cumulative. A later overlay cannot re-enable a disabled rule. A renderer MUST reject IDs that do not exist in the selected collection.

The format does not prescribe how a host discovers, activates, combines, or prioritizes profiles or overlays. A collection MUST document any precedence beyond these rules.

## Host behavior and interoperability boundary

The format defines portable document content and selectors. It does not guarantee that an agent host discovers files or follows nested directories. A host may ignore a glob field, fail to activate a rule on demand, or resolve conflicts differently. A host MAY require an adapter that translates the format into its native instruction mechanism. Adapters MUST preserve rule meaning to the extent the target host can express it. They SHOULD report unsupported selectors instead of presenting them as guaranteed behavior.

Automatic discovery paths, context-size limits, instruction precedence, skills installation, adapter output, and runtime rule selection are out of scope. A collection's documentation MUST state host-specific behavior it relies on.

## Prose license

The normative prose uses the repository's MIT License, the same license as the surrounding project. A collection that adopts this format MAY choose another license for its own prose. Conformance does not transfer ownership or licensing of rule content.

## References

- [RFC 2119: Key words for use in RFCs to Indicate Requirement Levels](https://www.rfc-editor.org/rfc/rfc2119.html)
- [RFC 8174: Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words](https://www.rfc-editor.org/rfc/rfc8174.html)
- [RFC 5234: Augmented BNF for Syntax Specifications](https://www.rfc-editor.org/rfc/rfc5234.html)
- [YAML 1.2.2 Specification](https://yaml.org/spec/1.2.2/)
- [JSON Schema Draft 2020-12](https://json-schema.org/specification)
- [Semantic Versioning 2.0.0](https://semver.org/)
