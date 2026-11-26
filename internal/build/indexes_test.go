package build

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestIndexOutputsMatchTrackedArtifacts(t *testing.T) {
	root := filepath.Join("..", "..")
	got, err := IndexOutputs(root, IndexOptions{})
	if err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"INDEX.md", "index.json", "llms.txt"} {
		want, err := os.ReadFile(filepath.Join(root, name))
		if err != nil {
			t.Fatal(err)
		}
		if string(got[name]) != string(want) {
			i := 0
			for i < len(got[name]) && i < len(want) && got[name][i] == want[i] {
				i++
			}
			t.Errorf("%s differs at byte %d: got %q want %q", name, i, got[name][max(0, i-24):min(len(got[name]), i+60)], want[max(0, i-24):min(len(want), i+60)])
		}
	}
}

func TestIndexOutputsApplyProfileAndOrderedOverlay(t *testing.T) {
	root := filepath.Join("..", "..")
	team := filepath.Join(t.TempDir(), "team.toml")
	project := filepath.Join(t.TempDir(), "project.toml")
	user := filepath.Join(t.TempDir(), "user.toml")
	for path, content := range map[string]string{
		team:    "[overrides]\ndisable = [\"conventions.code.dotfiles\"]\n[overrides.set]\nprofile.skill_name = \"team-skill\"\n",
		project: "[overrides.set]\nprofile.skill_name = \"project-skill\"\n",
		user:    "[overrides.set]\nprofile.skill_name = \"user-skill\"\n",
	} {
		if err := os.WriteFile(path, []byte(content), 0600); err != nil {
			t.Fatal(err)
		}
	}
	got, err := IndexOutputs(root, IndexOptions{Profile: "szmelc", Overlays: []string{team, project, user}})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(got["INDEX.md"]), "| `SKILL.md` | Installed as skill `user-skill`; entry point and format map |") {
		t.Error("last overlay did not override the skill name in INDEX.md")
	}
	if strings.Contains(string(got["INDEX.md"]), "CONVENTIONS/CODE/DOTFILES.md") {
		t.Error("disabled stable rule remains in INDEX.md")
	}
	if !strings.Contains(string(got["index.json"]), `"name": "user-skill"`) {
		t.Error("profile and final overlay values are missing from index.json")
	}
	if !strings.Contains(string(got["llms.txt"]), "Szmelc™ Conventions") || strings.Contains(string(got["llms.txt"]), "CONVENTIONS/CODE/DOTFILES.md") {
		t.Error("profile rendering or disabled rule handling is incorrect in llms.txt")
	}
}

func TestIndexOutputsRejectInvalidInputs(t *testing.T) {
	root := filepath.Join("..", "..")
	tests := []struct {
		name    string
		options IndexOptions
		want    string
	}{
		{"invalid profile", IndexOptions{Profile: "../neutral"}, "invalid profile name"},
		{"missing profile", IndexOptions{Profile: "missing"}, "profile not found"},
		{"unknown disabled rule", IndexOptions{Overlays: []string{writeOverlay(t, "[overrides]\ndisable = [\"missing.rule\"]\n")}}, "overlay disables unknown rule id"},
		{"invalid disabled rule id", IndexOptions{Overlays: []string{writeOverlay(t, "[overrides]\ndisable = [\"Bad ID\"]\n")}}, "invalid disabled rule id"},
		{"missing overlay", IndexOptions{Overlays: []string{"missing-overlay.toml"}}, "overlay not found"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			_, err := IndexOutputs(root, tc.options)
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("error = %v, want containing %q", err, tc.want)
			}
		})
	}
}

func writeOverlay(t *testing.T, content string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "overlay.toml")
	if err := os.WriteFile(path, []byte(content), 0600); err != nil {
		t.Fatal(err)
	}
	return path
}
