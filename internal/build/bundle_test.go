package build

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestBundleOutputMatchesTrackedArtifact(t *testing.T) {
	root := filepath.Join("..", "..")
	got, err := BundleOutput(root, IndexOptions{})
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(root, "CONVENTIONS.md"))
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != string(want) {
		i := 0
		for i < len(got) && i < len(want) && got[i] == want[i] {
			i++
		}
		t.Fatalf("CONVENTIONS.md differs at byte %d: got %q want %q", i, got[max(0, i-24):min(len(got), i+60)], want[max(0, i-24):min(len(want), i+60)])
	}
}

func TestBundleOutputAppliesProfileAndOverlay(t *testing.T) {
	root := filepath.Join("..", "..")
	overlay := filepath.Join(t.TempDir(), "project.toml")
	if err := os.WriteFile(overlay, []byte("[overrides]\ndisable = [\"conventions.code.dotfiles\"]\n[overrides.set]\nprofile.project_name = \"Example\"\n"), 0600); err != nil {
		t.Fatal(err)
	}
	got, err := BundleOutput(root, IndexOptions{Profile: "szmelc", Overlays: []string{overlay}})
	if err != nil {
		t.Fatal(err)
	}
	text := string(got)
	if !strings.HasPrefix(text, "# Example Conventions (all-in-one)\n") {
		t.Error("profile value was not rendered in bundle title")
	}
	if strings.Contains(text, "<!-- source: CONVENTIONS/CODE/DOTFILES.md -->") {
		t.Error("disabled stable rule remains in bundle")
	}
	if !strings.Contains(text, "## Go\n") {
		t.Error("source heading demotion is missing")
	}
}

func TestBundleOutputRejectsInvalidProfiles(t *testing.T) {
	root := filepath.Join("..", "..")
	for _, tc := range []struct{ profile, want string }{
		{"../neutral", "invalid profile name"},
		{"missing", "profile not found"},
	} {
		t.Run(tc.profile, func(t *testing.T) {
			_, err := BundleOutput(root, IndexOptions{Profile: tc.profile})
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("error = %v, want containing %q", err, tc.want)
			}
		})
	}
	if _, err := BundleOutput(t.TempDir(), IndexOptions{}); err == nil || !strings.Contains(err.Error(), "profile not found") {
		t.Fatalf("error = %v, want missing profile error", err)
	}
}
