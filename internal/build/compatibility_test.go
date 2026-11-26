package build

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCompatibilityOutputMatchesTrackedArtifact(t *testing.T) {
	root := filepath.Join("..", "..")
	got, err := CompatibilityOutput(root)
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(root, "COMPATIBILITY.md"))
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != string(want) {
		i := 0
		for i < len(got) && i < len(want) && got[i] == want[i] {
			i++
		}
		t.Fatalf("COMPATIBILITY.md differs at byte %d: got %q want %q", i, got[max(0, i-24):min(len(got), i+60)], want[max(0, i-24):min(len(want), i+60)])
	}
}

func TestCompatibilityOutputReportsRegistryErrors(t *testing.T) {
	_, err := CompatibilityOutput(t.TempDir())
	if err == nil || !strings.Contains(err.Error(), "read compatibility registry") {
		t.Fatalf("error = %v, want compatibility registry read error", err)
	}
}
