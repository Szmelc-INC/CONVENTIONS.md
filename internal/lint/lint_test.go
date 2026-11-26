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
	r, err := Run(root)
	if err != nil {
		t.Fatal(err)
	}
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

func TestRunReportsMissingRoot(t *testing.T) {
	if _, err := Run(filepath.Join(t.TempDir(), "missing")); err == nil {
		t.Fatal("expected missing root error")
	}
}

func TestRunAcceptsValidStableIDsAndMatchingIndex(t *testing.T) {
	root := t.TempDir()
	writeRule(t, root, "CONVENTIONS/ONE.md", "conventions.one")
	writeRule(t, root, "CONVENTIONS/TWO.md", "agents.prompt.two")
	index := `{"entries":[{"path":"CONVENTIONS/ONE.md","kind":"rule","id":"conventions.one"},{"path":"CONVENTIONS/TWO.md","kind":"rule","id":"agents.prompt.two"}]}`
	if err := os.WriteFile(filepath.Join(root, "index.json"), []byte(index), 0600); err != nil {
		t.Fatal(err)
	}
	r, err := Run(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Findings) != 0 {
		t.Fatalf("unexpected findings: %#v", r.Findings)
	}
}

func TestRunReportsMissingInvalidAndDuplicateStableIDs(t *testing.T) {
	root := t.TempDir()
	writeRule(t, root, "CONVENTIONS/INVALID.md", "Bad_ID")
	writeRule(t, root, "CONVENTIONS/DUPLICATE.md", "Bad_ID")
	writeRule(t, root, "CONVENTIONS/MISSING.md", "")
	r, err := Run(root)
	if err != nil {
		t.Fatal(err)
	}
	codes := map[string]bool{}
	for _, finding := range r.Findings {
		codes[finding.ID] = true
	}
	for _, code := range []string{"CONV005", "CONV006", "CONV007"} {
		if !codes[code] {
			t.Errorf("missing finding %s: %#v", code, r.Findings)
		}
	}
}

func TestRunReportsIndexIDMismatch(t *testing.T) {
	root := t.TempDir()
	writeRule(t, root, "CONVENTIONS/ONE.md", "conventions.one")
	writeRule(t, root, "CONVENTIONS/TWO.md", "conventions.two")
	index := `{"entries":[{"path":"CONVENTIONS/ONE.md","kind":"rule","id":"conventions.two"}]}`
	if err := os.WriteFile(filepath.Join(root, "index.json"), []byte(index), 0600); err != nil {
		t.Fatal(err)
	}
	r, err := Run(root)
	if err != nil {
		t.Fatal(err)
	}
	seen := map[string]bool{}
	for _, finding := range r.Findings {
		if finding.ID == "CONV008" {
			seen[finding.File] = true
		}
	}
	for _, path := range []string{"CONVENTIONS/ONE.md", "CONVENTIONS/TWO.md"} {
		if !seen[path] {
			t.Errorf("missing index ID finding for %s: %#v", path, r.Findings)
		}
	}
}

func writeRule(t *testing.T, root, path, id string) {
	t.Helper()
	fullPath := filepath.Join(root, filepath.FromSlash(path))
	if err := os.MkdirAll(filepath.Dir(fullPath), 0700); err != nil {
		t.Fatal(err)
	}
	frontMatter := "---\n"
	if id != "" {
		frontMatter += "id: " + id + "\n"
	}
	frontMatter += "---\n# Rule\n> Load when: checking the rule.\n"
	if err := os.WriteFile(fullPath, []byte(frontMatter), 0600); err != nil {
		t.Fatal(err)
	}
}
