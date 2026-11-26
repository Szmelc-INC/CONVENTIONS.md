// This file ports the source-discovery and INDEX.md, index.json, and llms.txt
// stages from META/tools/build.sh. It deliberately does not write files or
// invoke a shell; callers can choose where to persist the returned artifacts.
package build

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/BurntSushi/toml"
)

type IndexOptions struct {
	Profile  string
	Overlays []string
}

type indexSource struct{ path, title, trigger, id string }
type compatRecord struct {
	ID, Name, Kind, Description, Version, Added, Updated, Icon string
	Spec                                                       []string
	Links                                                      map[string]string
}
type registryFile struct {
	Disclaimer string `toml:"disclaimer"`
	Compat     []struct {
		ID          string            `toml:"id"`
		Name        string            `toml:"name"`
		Kind        string            `toml:"kind"`
		Description string            `toml:"description"`
		Version     string            `toml:"version"`
		Added       time.Time         `toml:"added"`
		Updated     time.Time         `toml:"updated"`
		Icon        string            `toml:"icon"`
		Spec        []string          `toml:"spec"`
		Links       map[string]string `toml:"links"`
	} `toml:"compat"`
}

// IndexOutputs returns the three standalone index artifacts in generator order.
// An empty profile selects neutral; overlays apply in team, project, user order.
func IndexOutputs(root string, opts IndexOptions) (map[string][]byte, error) {
	if opts.Profile == "" {
		opts.Profile = "neutral"
	}
	profile, disabled, err := indexProfile(root, opts.Profile, opts.Overlays)
	if err != nil {
		return nil, err
	}
	files, err := indexMarkdownFiles(root)
	if err != nil {
		return nil, err
	}
	var stable, experimental, legacy []indexSource
	allIDs := map[string]bool{}
	for _, s := range files {
		state := indexStatus(s.path)
		if state == "stable" || state == "experimental" {
			if s.id != "" {
				allIDs[s.id] = true
			}
			if disabled[s.id] {
				continue
			}
		}
		switch state {
		case "stable":
			stable = append(stable, s)
		case "experimental":
			experimental = append(experimental, s)
		case "legacy":
			legacy = append(legacy, s)
		}
	}
	for id := range disabled {
		if !allIDs[id] {
			return nil, fmt.Errorf("overlay disables unknown rule id: %s", id)
		}
	}
	skills, err := indexSkills(root)
	if err != nil {
		return nil, err
	}
	compat, disclaimer, compatOf, err := readCompat(root)
	if err != nil {
		return nil, err
	}
	globalTitle, err := readHeading(root, "AGENTS/global/AGENTS.md")
	if err != nil {
		return nil, err
	}
	globalTrigger := "Installed as global instructions (CLAUDE.md, AGENTS.md, GEMINI.md, QWEN.md, …); always active"
	entryTrigger := "Installed as skill `" + profile["profile.skill_name"] + "`; entry point and format map"
	compatTrigger := "checking which third-party formats, specs, platforms, languages or tools these conventions are compatible with, and at which version."
	result := map[string][]byte{}
	result["INDEX.md"] = renderIndex(root, stable, experimental, legacy, skills, entryTrigger, globalTrigger, compatTrigger)
	result["index.json"] = renderMachineIndex(root, profile, stable, experimental, legacy, skills, globalTitle, entryTrigger, globalTrigger, disclaimer, compat, compatOf)
	result["llms.txt"] = renderLLMIndex(root, profile, stable, experimental, legacy, skills, globalTitle, globalTrigger)
	for name, b := range result {
		result[name] = renderProfile(b, profile)
	}
	return result, nil
}

func indexProfile(root, name string, overlayFiles []string) (map[string]string, map[string]bool, error) {
	if !validProfileName(name) {
		return nil, nil, fmt.Errorf("invalid profile name: %s", name)
	}
	basePath := filepath.Join(root, "PROFILES/neutral/profile.toml")
	profilePath := filepath.Join(root, "PROFILES", name, "profile.toml")
	if _, err := os.Stat(basePath); err != nil {
		return nil, nil, fmt.Errorf("base profile not found: %s", basePath)
	}
	if _, err := os.Stat(profilePath); err != nil {
		return nil, nil, fmt.Errorf("profile not found: %s", name)
	}
	values := map[string]string{}
	loadProfile := func(path string) error {
		var doc map[string]any
		if _, e := toml.DecodeFile(path, &doc); e != nil {
			return fmt.Errorf("decode %s: %w", path, e)
		}
		profile, _ := doc["profile"].(map[string]any)
		flattenProfile(values, "profile", profile)
		return nil
	}
	if err := loadProfile(basePath); err != nil {
		return nil, nil, err
	}
	if name != "neutral" {
		if err := loadProfile(profilePath); err != nil {
			return nil, nil, err
		}
	}
	for _, key := range []string{"profile.raw_url", "profile.skill_name"} {
		if _, ok := values[key]; !ok {
			return nil, nil, fmt.Errorf("profile %s missing: %s", name, key)
		}
	}
	disabled := map[string]bool{}
	profileOverlay, err := filepath.Abs(filepath.Join(root, "PROFILES", name, "profile.toml"))
	if err != nil {
		return nil, nil, err
	}
	files := append([]string{profileOverlay}, overlayFiles...)
	for _, path := range files {
		if !filepath.IsAbs(path) {
			path = filepath.Join(root, path)
		}
		if _, err := os.Stat(path); err != nil {
			return nil, nil, fmt.Errorf("overlay not found: %s", path)
		}
		var doc map[string]any
		if _, err := toml.DecodeFile(path, &doc); err != nil {
			return nil, nil, fmt.Errorf("decode %s: %w", path, err)
		}
		over, _ := doc["overrides"].(map[string]any)
		if ids, ok := over["disable"].([]any); ok {
			for _, v := range ids {
				id, ok := v.(string)
				if !ok || !validRuleID(id) {
					return nil, nil, fmt.Errorf("invalid disabled rule id in %s: %v", path, v)
				}
				disabled[id] = true
			}
		}
		set, _ := over["set"].(map[string]any)
		setValues := map[string]string{}
		flattenProfile(setValues, "", set)
		for key, value := range setValues {
			if !strings.HasPrefix(key, "profile.") {
				return nil, nil, fmt.Errorf("overlay key must start with profile.: %s", key)
			}
			values[key] = value
		}
	}
	return values, disabled, nil
}

func flattenProfile(dst map[string]string, prefix string, src map[string]any) {
	for k, v := range src {
		key := k
		if prefix != "" {
			key = prefix + "." + k
		}
		if m, ok := v.(map[string]any); ok {
			flattenProfile(dst, key, m)
		} else if s, ok := v.(string); ok {
			dst[key] = s
		}
	}
}
func validProfileName(s string) bool {
	if s == "" {
		return false
	}
	for i, c := range s {
		if !(c >= 'a' && c <= 'z' || c >= '0' && c <= '9' || i > 0 && c == '-') {
			return false
		}
	}
	return true
}
func validRuleID(s string) bool {
	if s == "" {
		return false
	}
	prevSep := true
	for _, c := range s {
		if c >= 'a' && c <= 'z' || c >= '0' && c <= '9' {
			prevSep = false
			continue
		}
		if (c == '.' || c == '-') && !prevSep {
			prevSep = true
			continue
		}
		return false
	}
	return !prevSep
}

func indexMarkdownFiles(root string) ([]indexSource, error) {
	var out []indexSource
	for _, core := range []string{"CONVENTIONS", "AGENTS", "HUMANS", "CONTRIBUTING", "META", "TEMPLATES"} {
		err := filepath.WalkDir(filepath.Join(root, core), func(path string, d os.DirEntry, e error) error {
			if e != nil {
				return e
			}
			if d.IsDir() || d.Type()&os.ModeSymlink != 0 || !strings.HasSuffix(path, ".md") {
				return nil
			}
			rel, e := filepath.Rel(root, path)
			if e != nil {
				return e
			}
			rel = filepath.ToSlash(rel)
			text, e := os.ReadFile(path)
			if e != nil {
				return e
			}
			t := string(text)
			out = append(out, indexSource{rel, firstHeading(t), mapTrigger(t), frontmatter(t, "id")})
			return nil
		})
		if err != nil {
			return nil, err
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].path < out[j].path })
	return out, nil
}
func indexStatus(p string) string {
	if strings.HasSuffix(p, "/README.md") {
		return "core"
	}
	for _, prefix := range []string{"AGENTS/adapters/", "AGENTS/global/", "AGENTS/skills/", "AGENTS/modes/", "TEMPLATES/", "META/tools/", "META/schema/", "META/compat/", "META/assets/"} {
		if strings.HasPrefix(p, prefix) {
			return "skip"
		}
	}
	if strings.HasPrefix(p, "CONVENTIONS/EXPERIMENTAL/") {
		return "experimental"
	}
	if strings.HasPrefix(p, "CONVENTIONS/LEGACY/") {
		return "legacy"
	}
	return "stable"
}
func indexSkills(root string) ([]indexSource, error) {
	var out []indexSource
	err := filepath.WalkDir(filepath.Join(root, "AGENTS/skills"), func(path string, d os.DirEntry, e error) error {
		if e != nil {
			return e
		}
		if d.IsDir() || d.Type()&os.ModeSymlink != 0 || d.Name() != "SKILL.md" {
			return nil
		}
		rel, e := filepath.Rel(root, path)
		if e != nil {
			return e
		}
		rel = filepath.ToSlash(rel)
		if strings.Count(rel, "/") != 3 {
			return nil
		}
		b, e := os.ReadFile(path)
		if e != nil {
			return e
		}
		out = append(out, indexSource{path: rel, title: frontmatter(string(b), "name"), trigger: frontmatter(string(b), "description")})
		return nil
	})
	sort.Slice(out, func(i, j int) bool { return out[i].path < out[j].path })
	return out, err
}
func readHeading(root, p string) (string, error) {
	b, e := os.ReadFile(filepath.Join(root, p))
	if e != nil {
		return "", e
	}
	return firstHeading(string(b)), nil
}
func readCompat(root string) ([]compatRecord, string, map[string][]string, error) {
	path := filepath.Join(root, "META/compat/registry.toml")
	if err := validateCompatSubset(path); err != nil {
		return nil, "", nil, err
	}
	var doc registryFile
	md, err := toml.DecodeFile(path, &doc)
	if err != nil {
		return nil, "", nil, err
	}
	if undec := md.Undecoded(); len(undec) > 0 {
		return nil, "", nil, fmt.Errorf("%s: unknown registry keys: %v", path, undec)
	}
	out := make([]compatRecord, 0, len(doc.Compat))
	by := map[string][]string{}
	seen := map[string]bool{}
	for _, r := range doc.Compat {
		if r.ID == "" || seen[r.ID] {
			return nil, "", nil, fmt.Errorf("%s: missing or duplicate compatibility id %q", path, r.ID)
		}
		seen[r.ID] = true
		rec := compatRecord{r.ID, r.Name, r.Kind, r.Description, r.Version, r.Added.Format("2006-01-02"), r.Updated.Format("2006-01-02"), r.Icon, r.Spec, r.Links}
		out = append(out, rec)
		for _, p := range r.Spec {
			by[p] = append(by[p], r.ID)
		}
	}
	return out, doc.Disclaimer, by, nil
}

// validateCompatSubset keeps the Go reader aligned with compat.awk's deliberately
// small TOML subset. BurntSushi/toml accepts legal TOML syntax (such as escaped
// strings and inline comments) that compat.awk and the shell build do not.
func validateCompatSubset(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	section := "top"
	linksSeen := false
	disclaimerSeen := false
	seen := map[string]bool{}
	allowed := map[string]map[string]string{
		"top":    {"disclaimer": "string"},
		"record": {"id": "string", "name": "string", "kind": "string", "description": "string", "version": "string", "added": "date", "updated": "date", "icon": "string", "spec": "array"},
		"links":  {"homepage": "string", "repo": "string", "docs": "string", "community": "string"},
	}
	for i, line := range strings.Split(string(data), "\n") {
		lineNo := i + 1
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			continue
		}
		switch line {
		case "[[compat]]":
			section = "record"
			linksSeen = false
			seen = map[string]bool{}
			continue
		case "[compat.links]":
			if section != "record" || linksSeen {
				return fmt.Errorf("%s:%d: [compat.links] must follow a [[compat]] record once", path, lineNo)
			}
			section = "links"
			linksSeen = true
			seen = map[string]bool{}
			continue
		}
		sep := strings.Index(line, " = ")
		if sep <= 0 || !compatKey(line[:sep]) {
			return fmt.Errorf("%s:%d: expected 'key = value': %s", path, lineNo, line)
		}
		key, value := line[:sep], line[sep+3:]
		kind, ok := allowed[section][key]
		if !ok {
			return fmt.Errorf("%s:%d: unknown key %q in %s", path, lineNo, key, section)
		}
		if seen[key] {
			return fmt.Errorf("%s:%d: duplicate key %q", path, lineNo, key)
		}
		seen[key] = true
		if section == "top" && key == "disclaimer" {
			disclaimerSeen = true
		}
		valid := false
		switch kind {
		case "string":
			valid = compatString(value, false)
		case "date":
			valid = len(value) == 10 && value[4] == '-' && value[7] == '-'
			for j, c := range value {
				if j != 4 && j != 7 && (c < '0' || c > '9') {
					valid = false
				}
			}
		case "array":
			valid = len(value) >= 3 && value[0] == '[' && value[len(value)-1] == ']'
			if valid {
				items := strings.Split(value[1:len(value)-1], ", ")
				for _, item := range items {
					if !compatString(item, true) {
						valid = false
						break
					}
				}
			}
		}
		if !valid {
			return fmt.Errorf("%s:%d: invalid %s value for %q", path, lineNo, kind, key)
		}
	}
	if !disclaimerSeen {
		return fmt.Errorf("%s: missing disclaimer", path)
	}
	return nil
}

func compatKey(key string) bool {
	for _, c := range key {
		if (c < 'a' || c > 'z') && c != '_' {
			return false
		}
	}
	return key != ""
}

func compatString(value string, noSpaces bool) bool {
	if len(value) < 2 || value[0] != '"' || value[len(value)-1] != '"' {
		return false
	}
	inner := value[1 : len(value)-1]
	return !strings.ContainsAny(inner, `"\\`) && (!noSpaces || !strings.Contains(inner, " "))
}

func renderProfile(data []byte, values map[string]string) []byte {
	out := string(data)
	keys := make([]string, 0, len(values))
	for k := range values {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		out = strings.ReplaceAll(out, "{{"+k+"}}", values[k])
	}
	return []byte(out)
}
func mdCell(s string) string { return strings.ReplaceAll(s, "|", "\\|") }
func renderIndex(root string, stable, experimental, legacy, skills []indexSource, entry, always, compat string) []byte {
	var b strings.Builder
	line := func(s string) { b.WriteString(s); b.WriteByte('\n') }
	line("# Index")
	line(generatedNote)
	line("Read this once per session. Load only files whose trigger matches the task. Paths are relative to the conventions repo.")
	line("")
	line("## Always on")
	line("| File | Load when |")
	line("|---|---|")
	line("| `AGENTS/global/AGENTS.md` | " + mdCell(always) + " |")
	line("| `SKILL.md` | " + mdCell(entry) + " |")
	line("")
	line("## Cores")
	line("| File | Load when |")
	line("|---|---|")
	for _, c := range []string{"CONVENTIONS", "AGENTS", "HUMANS", "CONTRIBUTING", "META", "TEMPLATES"} {
		t, _ := readTriggerPath(root, c)
		line("| `" + c + "/README.md` | " + mdCell(t) + " |")
	}
	line("")
	line("## Compatibility")
	line("| File | Load when |")
	line("|---|---|")
	line("| `COMPATIBILITY.md` | " + mdCell(compat) + " |")
	line("")
	line("## Rules")
	line("| File | Load when |")
	line("|---|---|")
	for _, s := range stable {
		line("| `" + s.path + "` | " + mdCell(s.trigger) + " |")
	}
	line("")
	line("## Experimental mode bundles (explicit opt-in)")
	modes := findModePaths(root)
	if len(modes) > 0 {
		line("| File | Load when |")
		line("|---|---|")
		for _, p := range modes {
			line("| `" + p + "` | " + mdCell(triggerPath(root, p)) + " |")
		}
	} else {
		line("_None._")
	}
	line("")
	line("## Skills")
	line("| File | Load when |")
	line("|---|---|")
	for _, s := range skills {
		line("| `" + s.path + "` | " + mdCell(s.trigger) + " |")
	}
	line("")
	line("## Experimental (opt-in only)")
	if len(experimental) > 0 {
		line("| File | Load when |")
		line("|---|---|")
		for _, s := range experimental {
			line("| `" + s.path + "` | " + mdCell(s.trigger) + " |")
		}
	} else {
		line("_None._")
	}
	line("")
	line("## Legacy (archive; load only when asked)")
	if len(legacy) > 0 {
		line("| File | Title |")
		line("|---|---|")
		for _, s := range legacy {
			line("| `" + s.path + "` | " + mdCell(s.title) + " |")
		}
	} else {
		line("_None._")
	}
	return []byte(strings.TrimSuffix(b.String(), "\n"))
}
func readTriggerPath(root, p string) (string, error) {
	b, e := os.ReadFile(filepath.Join(root, p, "README.md"))
	return mapTrigger(string(b)), e
}
func triggerPath(root, p string) string {
	b, _ := os.ReadFile(filepath.Join(root, filepath.FromSlash(p)))
	return mapTrigger(string(b))
}
func findModePaths(root string) []string {
	var p []string
	_ = filepath.WalkDir(filepath.Join(root, "AGENTS/modes"), func(path string, d os.DirEntry, e error) error {
		if e == nil && !d.IsDir() && d.Type()&os.ModeSymlink == 0 && filepath.Dir(path) == filepath.Join(root, "AGENTS/modes") && strings.HasSuffix(path, ".md") {
			r, _ := filepath.Rel(root, path)
			p = append(p, filepath.ToSlash(r))
		}
		return nil
	})
	sort.Strings(p)
	return p
}

// Keep JSON's key order and whitespace identical to the source generator.
func renderMachineIndex(root string, profile map[string]string, stable, experimental, legacy, skills []indexSource, globalTitle, entry, always, disclaimer string, compat []compatRecord, compatOf map[string][]string) []byte {
	var b strings.Builder
	entries := []string{}
	add := func(path, title, load, status, kind, id string) {
		x := "    {\"path\": " + jsonString(path) + ", \"title\": " + jsonString(title) + ", \"load_when\": " + jsonString(load) + ", \"status\": " + jsonString(status) + ", \"kind\": " + jsonString(kind)
		if kind == "rule" && id != "" {
			x += ", \"id\": " + jsonString(id)
		}
		if source := indexOrigin(path); source != "" {
			x += ", \"origin\": " + jsonString(source)
		}
		if ids := compatOf[path]; len(ids) > 0 {
			parts := []string{}
			for _, v := range ids {
				parts = append(parts, jsonString(v))
			}
			x += ", \"compat\": [" + strings.Join(parts, ", ") + "]"
		}
		entries = append(entries, x+"}")
	}
	add("AGENTS/global/AGENTS.md", globalTitle, always, "always", "global", "")
	add("SKILL.md", profile["profile.skill_name"], entry, "always", "skill", "")
	for _, c := range []string{"CONVENTIONS", "AGENTS", "HUMANS", "CONTRIBUTING", "META", "TEMPLATES"} {
		title, _ := readHeading(root, c+"/README.md")
		tr, _ := readTriggerPath(root, c)
		add(c+"/README.md", title, tr, "stable", "core", "")
	}
	for _, s := range stable {
		add(s.path, s.title, s.trigger, "stable", "rule", s.id)
	}
	for _, s := range skills {
		add(s.path, s.title, s.trigger, "stable", "skill", "")
	}
	for _, s := range experimental {
		add(s.path, s.title, s.trigger, "experimental", "rule", s.id)
	}
	for _, s := range legacy {
		add(s.path, s.title, "Only when asked about superseded conventions", "legacy", "archive", "")
	}
	compatLines := []string{}
	for _, r := range compat {
		x := "    {\"id\": " + jsonString(r.ID) + ", \"name\": " + jsonString(r.Name) + ", \"kind\": " + jsonString(r.Kind) + ", \"description\": " + jsonString(r.Description) + ", \"version\": " + jsonString(r.Version) + ", \"added\": " + jsonString(r.Added) + ", \"updated\": " + jsonString(r.Updated)
		if r.Icon != "" {
			x += ", \"icon\": " + jsonString(r.Icon)
		}
		parts := []string{}
		for _, p := range r.Spec {
			parts = append(parts, jsonString(p))
		}
		x += ", \"spec\": [" + strings.Join(parts, ", ") + "]"
		links := []string{}
		for _, k := range []string{"homepage", "repo", "docs", "community"} {
			if v := r.Links[k]; v != "" {
				links = append(links, jsonString(k)+": "+jsonString(v))
			}
		}
		compatLines = append(compatLines, x+", \"links\": {"+strings.Join(links, ", ")+"}}")
	}
	b.WriteString("{\n  \"$schema\": \"https://szmelc-inc.github.io/CONVENTIONS.md/SPEC/schemas/index-v2.schema.json\",\n  \"format_version\": \"1.0\",\n  \"name\": " + jsonString("{{profile.skill_name}}") + ",\n  \"repo\": " + jsonString("{{profile.repository_url}}") + ",\n  \"entries\": [\n")
	b.WriteString(strings.Join(withCommas(entries), "\n"))
	b.WriteString("\n  ],\n  \"compatible_disclaimer\": " + jsonString(disclaimer) + ",\n  \"compatible\": [\n")
	b.WriteString(strings.Join(withCommas(compatLines), "\n"))
	b.WriteString("\n  ]\n}")
	return []byte(b.String())
}
func withCommas(lines []string) []string {
	out := append([]string(nil), lines...)
	for i := 0; i+1 < len(out); i++ {
		out[i] += ","
	}
	return out
}

func renderLLMIndex(root string, profile map[string]string, stable, experimental, legacy, skills []indexSource, globalTitle, always string) []byte {
	raw := profile["profile.raw_url"]
	var b strings.Builder
	line := func(s string) { b.WriteString(s); b.WriteByte('\n') }
	line("# {{profile.project_name}} Conventions")
	line("")
	line("> Global conventions for humans and AI agents, in six cores: CONVENTIONS (rules by category: WORKFLOW, GITHUB (repo, pull requests, actions, releases, deployments), SPECS (third-party and original document formats), FORMATS, SYSTEMS, REPO, DESIGN, INTERFACES, PACKAGING, CODE), AGENTS (always-on rules, agent behaviour rules, prompt engineering and a prompt library, skills, adapters), HUMANS (install, browse), CONTRIBUTING (extend, write, version, prompts), META (build pipeline, schema, compatibility registry) and TEMPLATES (skeletons for rules, prompts, skills, project agent files). Project identity and profile docs are separate from the core. Agents load rules lazily: read INDEX.md, then only files whose trigger matches the task.")
	line("")
	line("Entry points: [SKILL.md](" + raw + "/SKILL.md), [INDEX.md](" + raw + "/INDEX.md), [index.json](" + raw + "/index.json). All stable rules in one file: [CONVENTIONS.md](" + raw + "/CONVENTIONS.md). Compatible third-party formats, specs and tools: [COMPATIBILITY.md](" + raw + "/COMPATIBILITY.md).")
	line("")
	line("## Always on")
	line("- [" + globalTitle + "](" + raw + "/AGENTS/global/AGENTS.md): " + always)
	line("")
	line("## Cores")
	for _, c := range []string{"CONVENTIONS", "AGENTS", "HUMANS", "CONTRIBUTING", "META", "TEMPLATES"} {
		title, _ := readHeading(root, c+"/README.md")
		trigger, _ := readTriggerPath(root, c)
		line("- [" + title + "](" + raw + "/" + c + "/README.md): Load when " + trigger)
	}
	line("")
	line("## Rules")
	for _, s := range stable {
		line("- [" + s.title + "](" + raw + "/" + s.path + "): Load when " + s.trigger)
	}
	line("")
	line("## Skills")
	for _, s := range skills {
		line("- [" + s.title + "](" + raw + "/" + s.path + "): " + s.trigger)
	}
	if len(experimental) > 0 {
		line("")
		line("## Experimental")
		for _, s := range experimental {
			line("- [" + s.title + "](" + raw + "/" + s.path + "): Opt-in only. Load when " + s.trigger)
		}
	}
	if len(legacy) > 0 {
		line("")
		line("## Optional")
		for _, s := range legacy {
			line("- [" + s.title + "](" + raw + "/" + s.path + "): Legacy archive")
		}
	}
	return []byte(strings.TrimSuffix(b.String(), "\n"))
}
func jsonString(s string) string {
	var b strings.Builder
	e := json.NewEncoder(&b)
	e.SetEscapeHTML(false)
	_ = e.Encode(s)
	return strings.TrimSuffix(b.String(), "\n")
}

func indexOrigin(path string) string {
	if strings.Contains(path, "/THIRD-PARTY/") {
		return "third-party"
	}
	if strings.Contains(path, "/ORIGINAL/") {
		return "original"
	}
	return ""
}
