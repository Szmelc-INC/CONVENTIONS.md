package lint

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestRunAndSARIF(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "good.md"), []byte("---\nid: test.rule\n---\n# Good\n> Load when: testing this rule.\n"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := os.Mkdir(filepath.Join(root, "CONVENTIONS"), 0700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "CONVENTIONS", "bad.md"), []byte("# Missing trigger\n"), 0600); err != nil {
		t.Fatal(err)
	}
	r := Run(root)
	if r.Files != 2 || len(r.Findings) < 1 {
		t.Fatalf("unexpected report: %#v", r)
	}
	var payload map[string]any
	if err := json.Unmarshal(SARIF(r), &payload); err != nil {
		t.Fatal(err)
	}
	if payload["version"] != "2.1.0" {
		t.Fatalf("invalid SARIF: %#v", payload)
	}
}
