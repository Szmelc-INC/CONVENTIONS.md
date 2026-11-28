package build

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
)

// ProfileFileOutputs returns the profile-rendered global rules and skill entry
// point. An empty profile selects the repository default (PROFILES/DEFAULT,
// else neutral); overlays apply in team, project, user order, matching the
// other build renderers.
func ProfileFileOutputs(root string, opts IndexOptions) (map[string][]byte, error) {
	profile, _, err := indexProfile(root, opts.Profile, opts.Overlays)
	if err != nil {
		return nil, err
	}
	outputs := make(map[string][]byte, 2)
	for _, path := range []string{"SKILL.md", "AGENTS/global/AGENTS.md"} {
		data, err := os.ReadFile(filepath.Join(root, filepath.FromSlash(path)))
		if err != nil {
			return nil, fmt.Errorf("read %s: %w", path, err)
		}
		// The shell generator reads each template through command substitution,
		// which strips trailing line feeds, then writes a single closing one.
		outputs[path] = finalNewline(renderProfile(bytes.TrimRight(data, "\n"), profile))
	}
	return outputs, nil
}
