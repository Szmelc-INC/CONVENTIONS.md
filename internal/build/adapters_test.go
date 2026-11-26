package build

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestAdapterOutputsMatchTrackedArtifacts(t *testing.T) {
	root := filepath.Join("..", "..")
	got, err := AdapterOutputs(root, IndexOptions{})
	if err != nil {
		t.Fatal(err)
	}
	for path, data := range got {
		want, err := os.ReadFile(filepath.Join(root, filepath.FromSlash(path)))
		if err != nil {
			t.Fatal(err)
		}
		if string(data) != string(want) {
			i := 0
			for i < len(data) && i < len(want) && data[i] == want[i] {
				i++
			}
			t.Errorf("%s differs at byte %d: got %q want %q", path, i, data[max(0, i-24):min(len(data), i+60)], want[max(0, i-24):min(len(want), i+60)])
		}
	}
}

func TestAdapterOutputsApplyProjectNameOverlay(t *testing.T) {
	root := filepath.Join("..", "..")
	overlay := filepath.Join(t.TempDir(), "project.toml")
	if err := os.WriteFile(overlay, []byte("[overrides.set]\nprofile.project_name = \"Example\"\n"), 0600); err != nil {
		t.Fatal(err)
	}
	got, err := AdapterOutputs(root, IndexOptions{Overlays: []string{overlay}})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(got["AGENTS/adapters/cursor/szmelc-conventions.mdc"]), "description: Example global conventions (always on)") {
		t.Error("Cursor adapter does not render the project name overlay")
	}
	for _, path := range []string{"AGENTS/adapters/copilot/szmelc-conventions.instructions.md", "AGENTS/adapters/kiro/szmelc-conventions.md"} {
		if !strings.Contains(string(got[path]), "# Global rules") {
			t.Errorf("%s does not include the global rules", path)
		}
	}
}

func TestAdapterOutputsRejectInvalidProfile(t *testing.T) {
	_, err := AdapterOutputs(filepath.Join("..", ".."), IndexOptions{Profile: "../neutral"})
	if err == nil || !strings.Contains(err.Error(), "invalid profile name") {
		t.Fatalf("error = %v, want invalid profile name", err)
	}
}
