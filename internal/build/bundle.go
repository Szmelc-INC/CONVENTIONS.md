package build

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

const bundleUsage = "> One-shot reference for tools that cannot lazy-load (aider `--read`, web chats, project knowledge). Agents with file access use `SKILL.md` + `INDEX.md` instead; never load this file alongside them. Stable rules only; the lazy-load instructions below do not apply here because every stable rule is inlined."

// BundleOutput renders the all-in-one conventions reference for a profile.
// An empty profile selects neutral; overlays apply in team, project, user order.
func BundleOutput(root string, opts IndexOptions) ([]byte, error) {
	if opts.Profile == "" {
		opts.Profile = "neutral"
	}
	profile, disabled, err := indexProfile(root, opts.Profile, opts.Overlays)
	if err != nil {
		return nil, err
	}
	mapData, err := renderBundleMap(root)
	if err != nil {
		return nil, err
	}
	files, err := indexMarkdownFiles(root)
	if err != nil {
		return nil, err
	}
	var out strings.Builder
	fmt.Fprintf(&out, "# {{profile.project_name}} Conventions (all-in-one)\n%s\n%s\n\n## Map of `CONVENTIONS/`\n", generatedNote, bundleUsage)
	out.WriteString(string(mapData))
	for _, path := range append([]string{"AGENTS/global/AGENTS.md"}, stableBundlePaths(files, disabled)...) {
		separator := "\n\n---\n"
		if strings.HasSuffix(out.String(), "\n") {
			separator = "\n---\n"
		}
		out.WriteString(separator + "<!-- source: " + path + " -->\n")
		data, err := os.ReadFile(filepath.Join(root, filepath.FromSlash(path)))
		if err != nil {
			return nil, fmt.Errorf("read %s: %w", path, err)
		}
		out.WriteString(demote(string(data)))
	}
	return renderProfile(bytes.TrimRight([]byte(out.String()), "\n"), profile), nil
}

func renderBundleMap(root string) ([]byte, error) {
	readmePath := "CONVENTIONS/README.md"
	files, err := indexMarkdownFiles(root)
	if err != nil {
		return nil, err
	}
	var out strings.Builder
	fmt.Fprintf(&out, "Map of `CONVENTIONS/`. Full guide: [`%s`](%s).\n\n", readmePath, readmePath)
	out.WriteString("| Path | What | Load when |\n|---|---|---|\n")
	for _, file := range files {
		if !strings.HasPrefix(file.path, "CONVENTIONS/") || file.path == readmePath || indexStatus(file.path) != "stable" {
			continue
		}
		fmt.Fprintf(&out, "| [`%s`](%s) | %s | %s |\n", file.path, file.path, file.title, file.trigger)
	}
	for _, lane := range []struct{ path, about, when string }{
		{"CONVENTIONS/EXPERIMENTAL/", "Opt-in proposals (lane `experimental`)", "User opts into experimental conventions"},
		{"CONVENTIONS/LEGACY/", "Superseded material, archived (lane `legacy`)", "Asked about history"},
	} {
		fmt.Fprintf(&out, "| [`%s`](%s) | %s | %s |\n", lane.path, lane.path, lane.about, lane.when)
	}
	return []byte(strings.TrimRight(out.String(), "\n")), nil
}

func stableBundlePaths(files []indexSource, disabled map[string]bool) []string {
	var paths []string
	for _, file := range files {
		if indexStatus(file.path) == "stable" && !disabled[file.id] {
			paths = append(paths, file.path)
		}
	}
	return paths
}

func demote(text string) string {
	lines := strings.Split(text, "\n")
	for i, line := range lines {
		if strings.HasPrefix(line, "#") {
			level := 0
			for level < len(line) && line[level] == '#' {
				level++
			}
			if level < len(line) && line[level] == ' ' {
				lines[i] = "#" + line
			}
		}
	}
	return strings.Join(lines, "\n")
}
