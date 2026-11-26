package build

import (
	"fmt"
	"strings"
)

const compatibilityTrigger = "checking which third-party formats, specs, platforms, languages or tools these conventions are compatible with, and at which version."

// CompatibilityOutput renders COMPATIBILITY.md from the compatibility registry.
// The artifact does not use profile or overlay values, so this API takes only a
// repository root.
func CompatibilityOutput(root string) ([]byte, error) {
	records, disclaimer, _, err := readCompat(root)
	if err != nil {
		return nil, fmt.Errorf("read compatibility registry: %w", err)
	}
	var b strings.Builder
	line := func(s string) { b.WriteString(s); b.WriteByte('\n') }
	line("# Compatible with")
	line(generatedNote)
	line("> Load when: " + compatibilityTrigger)
	line("")
	line("Third-party formats, specs, platforms, languages and tools these conventions are compatible with, at the listed version. Source: `META/compat/registry.toml` (fields in its header); machine-readable in `index.json` (`compatible`). Rules about third-party formats live in `CONVENTIONS/SPECS/THIRD-PARTY/`.")
	line("")
	line("| Name | Kind | Version | What | Rules | Links | Updated |")
	line("|---|---|---|---|---|---|---|")
	for _, r := range records {
		rules := make([]string, 0, len(r.Spec))
		for _, p := range r.Spec {
			rules = append(rules, "`"+p+"`")
		}
		links := make([]string, 0, 4)
		for _, kind := range []string{"homepage", "repo", "docs", "community"} {
			if url := r.Links[kind]; url != "" {
				links = append(links, fmt.Sprintf("[%s](<%s>)", kind, url))
			}
		}
		line(fmt.Sprintf("| %s | %s | %s | %s | %s | %s | %s |",
			mdCell(r.Name), r.Kind, mdCell(r.Version), mdCell(r.Description),
			strings.Join(rules, ", "), strings.Join(links, " · "), r.Updated))
	}
	line("")
	line("_Disclaimer:_ " + disclaimer)
	// build.sh's render() captures output with command substitution, which strips
	// trailing newlines before writing the generated artifact.
	return []byte(strings.TrimRight(b.String(), "\n")), nil
}
