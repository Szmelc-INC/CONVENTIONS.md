package build

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// AgentsMapBlock renders the generated map block embedded in AGENTS.md.
func AgentsMapBlock(root string) ([]byte, error) {
	const core = "AGENTS"
	readmePath := core + "/README.md"
	readme, err := os.ReadFile(filepath.Join(root, filepath.FromSlash(readmePath)))
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", readmePath, err)
	}
	trigger := mapTrigger(string(readme))
	files := make([]string, 0)
	err = filepath.WalkDir(filepath.Join(root, core), func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if path == filepath.Join(root, core) || d.IsDir() {
			return nil
		}
		// WalkDir does not follow symlinks, but generated maps include symlink entries.
		rel, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		files = append(files, filepath.ToSlash(rel))
		return nil
	})
	if err != nil {
		return nil, err
	}
	sort.Strings(files)

	var out strings.Builder
	out.WriteString("<!-- map:begin -->\n## Map of `AGENTS/`\n")
	out.WriteString(generatedNote)
	fmt.Fprintf(&out, "\n> Load when: %s\n\nMap of `%s/`. Full guide: [`%s`](%s).\n\n", trigger, core, readmePath, readmePath)
	out.WriteString("| Path | What | Load when |\n|---|---|---|\n")
	for _, path := range files {
		if path == readmePath || ignoredMapPath(path) {
			continue
		}
		data, err := os.ReadFile(filepath.Join(root, filepath.FromSlash(path)))
		if err != nil {
			return nil, fmt.Errorf("read %s: %w", path, err)
		}
		fmt.Fprintf(&out, "| [`%s`](%s) | %s | %s |\n", path, path, mapAbout(path, string(data)), mapTrigger(string(data)))
	}
	out.WriteString("<!-- map:end -->")
	return []byte(out.String()), nil
}
