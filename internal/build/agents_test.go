package build

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestAgentsMapBlockMatchesTrackedArtifact(t *testing.T) {
	root := filepath.Join("..", "..")
	got, err := AgentsMapBlock(root)
	if err != nil {
		t.Fatal(err)
	}
	tracked, err := os.ReadFile(filepath.Join(root, "AGENTS.md"))
	if err != nil {
		t.Fatal(err)
	}
	text := string(tracked)
	start := strings.Index(text, "<!-- map:begin -->")
	end := strings.Index(text, "<!-- map:end -->")
	if start < 0 || end < start {
		t.Fatal("AGENTS.md has no complete generated map block")
	}
	want := text[start : end+len("<!-- map:end -->")]
	if string(got) != want {
		i := 0
		for i < len(got) && i < len(want) && got[i] == want[i] {
			i++
		}
		t.Fatalf("AGENTS.md map differs at byte %d: got %q want %q", i, got[max(0, i-24):min(len(got), i+60)], want[max(0, i-24):min(len(want), i+60)])
	}
}

func TestAgentsMapBlockReportsMissingSource(t *testing.T) {
	_, err := AgentsMapBlock(t.TempDir())
	if err == nil || !strings.Contains(err.Error(), "AGENTS/README.md") {
		t.Fatalf("error = %v, want missing README path", err)
	}
}
