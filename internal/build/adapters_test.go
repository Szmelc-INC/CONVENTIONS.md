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
	if !strings.Contains(string(got[adapterPath(t, got, "cursor")]), "description: Example global conventions (always on)") {
		t.Error("Cursor adapter does not render the project name overlay")
	}
	for _, tool := range []string{"copilot", "kiro"} {
		if !strings.Contains(string(got[adapterPath(t, got, tool)]), "# Global rules") {
			t.Errorf("%s adapter does not include the global rules", tool)
		}
	}
}

// adapterPath returns the one rendered adapter of a tool, so tests do not depend on the adapter name.
func adapterPath(t *testing.T, outputs map[string][]byte, tool string) string {
	t.Helper()
	prefix := "AGENTS/adapters/" + tool + "/"
	for path := range outputs {
		if strings.HasPrefix(path, prefix) {
			return path
		}
	}
	t.Fatalf("no %s adapter rendered", tool)
	return ""
}

func TestAdapterNameComesFromTheProfile(t *testing.T) {
	for _, tc := range []struct {
		profile map[string]string
		want    string
	}{
		{map[string]string{"profile.skill_name": "conventions", "profile.adapter_name": "team-conventions"}, "team-conventions"},
		{map[string]string{"profile.skill_name": "conventions"}, "conventions"},
	} {
		got, err := adapterName(tc.profile)
		if err != nil || got != tc.want {
			t.Errorf("adapterName(%v) = %q, %v; want %q", tc.profile, got, err, tc.want)
		}
	}
	for _, stem := range []string{"", "Bad-Name", "-lead"} {
		if _, err := adapterName(map[string]string{"profile.adapter_name": stem}); err == nil {
			t.Errorf("adapter name %q was accepted", stem)
		}
	}
}

func TestAdapterOutputsRejectInvalidProfile(t *testing.T) {
	_, err := AdapterOutputs(filepath.Join("..", ".."), IndexOptions{Profile: "../neutral"})
	if err == nil || !strings.Contains(err.Error(), "invalid profile name") {
		t.Fatalf("error = %v, want invalid profile name", err)
	}
}
