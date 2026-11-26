package build

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestProfileFileOutputsMatchShellGenerator(t *testing.T) {
	root := filepath.Join("..", "..")
	for _, profile := range []string{"neutral", "szmelc"} {
		t.Run(profile, func(t *testing.T) {
			got, err := ProfileFileOutputs(root, IndexOptions{Profile: profile})
			if err != nil {
				t.Fatal(err)
			}
			want := shellProfileFileOutputs(t, root, profile, nil)
			assertProfileFilesEqual(t, got, want)
		})
	}
}

func TestProfileFileOutputsAppliesOverlays(t *testing.T) {
	root := filepath.Join("..", "..")
	overlay := filepath.Join(t.TempDir(), "project.toml")
	contents := "[overrides.set]\nprofile.project_name = \"Example & Research | Labs\"\nprofile.skill_name = \"example-skill\"\n"
	if err := os.WriteFile(overlay, []byte(contents), 0600); err != nil {
		t.Fatal(err)
	}
	got, err := ProfileFileOutputs(root, IndexOptions{Profile: "szmelc", Overlays: []string{overlay}})
	if err != nil {
		t.Fatal(err)
	}
	want := shellProfileFileOutputs(t, root, "szmelc", []string{"--project", overlay})
	assertProfileFilesEqual(t, got, want)
	if !strings.Contains(string(got["SKILL.md"]), "# Example & Research | Labs conventions") {
		t.Fatal("profile overlay was not rendered as literal text")
	}
}

func TestProfileFileOutputsRejectsInvalidProfiles(t *testing.T) {
	root := filepath.Join("..", "..")
	for _, tc := range []struct{ profile, want string }{
		{"../neutral", "invalid profile name"},
		{"missing", "profile not found"},
	} {
		t.Run(tc.profile, func(t *testing.T) {
			_, err := ProfileFileOutputs(root, IndexOptions{Profile: tc.profile})
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("error = %v, want containing %q", err, tc.want)
			}
		})
	}
}

func shellProfileFileOutputs(t *testing.T, root, profile string, extraArgs []string) map[string][]byte {
	t.Helper()
	out := t.TempDir()
	args := []string{"META/tools/build.sh", "--profile", profile, "--output", out}
	args = append(args, extraArgs...)
	cmd := exec.Command("bash", args...)
	cmd.Dir = root
	if output, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("shell generator failed: %v\n%s", err, output)
	}
	result := make(map[string][]byte, 2)
	for _, path := range []string{"SKILL.md", "AGENTS/global/AGENTS.md"} {
		data, err := os.ReadFile(filepath.Join(out, filepath.FromSlash(path)))
		if err != nil {
			t.Fatalf("read shell output %s: %v", path, err)
		}
		result[path] = data
	}
	return result
}

func assertProfileFilesEqual(t *testing.T, got, want map[string][]byte) {
	t.Helper()
	for _, path := range []string{"SKILL.md", "AGENTS/global/AGENTS.md"} {
		if string(got[path]) != string(want[path]) {
			i := 0
			for i < len(got[path]) && i < len(want[path]) && got[path][i] == want[path][i] {
				i++
			}
			t.Errorf("%s differs at byte %d: got %q want %q", path, i, got[path][max(0, i-24):min(len(got[path]), i+60)], want[path][max(0, i-24):min(len(want[path]), i+60)])
		}
	}
}
