package build

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const validCompatRegistry = `disclaimer = "Names are trademarks."

[[compat]]
id = "sample"
name = "Sample Format"
kind = "format"
description = "A test format."
version = "1.0"
added = 2026-01-01
updated = 2026-01-02
spec = ["CONVENTIONS/FORMATS/SAMPLE.md"]

[compat.links]
homepage = "https://example.org/"
`

func TestReadCompatAcceptsDocumentedSubset(t *testing.T) {
	root := writeCompatRegistry(t, validCompatRegistry)
	records, disclaimer, by, err := readCompat(root)
	if err != nil {
		t.Fatal(err)
	}
	if disclaimer != "Names are trademarks." || len(records) != 1 || records[0].ID != "sample" {
		t.Fatalf("unexpected parsed registry: records=%+v disclaimer=%q", records, disclaimer)
	}
	if got := strings.Join(by["CONVENTIONS/FORMATS/SAMPLE.md"], ","); got != "sample" {
		t.Fatalf("spec index = %q, want sample", got)
	}
}

func TestReadCompatRejectsSyntaxOutsideAwkSubset(t *testing.T) {
	tests := []struct {
		name, input, want string
	}{
		{"duplicate key", strings.Replace(validCompatRegistry, "name = \"Sample Format\"", "name = \"Sample Format\"\nname = \"Other\"", 1), "duplicate key"},
		{"unknown key", strings.Replace(validCompatRegistry, "kind = \"format\"", "unknown = \"value\"\nkind = \"format\"", 1), "unknown key"},
		{"escaped string", strings.Replace(validCompatRegistry, "name = \"Sample Format\"", `name = "Sample \"Format"`, 1), "invalid string value"},
		{"inline comment", strings.Replace(validCompatRegistry, "name = \"Sample Format\"", `name = "Sample Format" # comment`, 1), "invalid string value"},
		{"wrong field shape", strings.Replace(validCompatRegistry, `spec = ["CONVENTIONS/FORMATS/SAMPLE.md"]`, `spec = "CONVENTIONS/FORMATS/SAMPLE.md"`, 1), "invalid array value"},
		{"trailing syntax", strings.Replace(validCompatRegistry, "kind = \"format\"", "kind = \"format\" trailing", 1), "invalid string value"},
		{"missing disclaimer", strings.TrimPrefix(validCompatRegistry, "disclaimer = \"Names are trademarks.\"\n\n"), "missing disclaimer"},
		{"duplicate links table", validCompatRegistry + "\n[compat.links]\nrepo = \"https://example.org/repo\"\n", "must follow a [[compat]] record once"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			_, _, _, err := readCompat(writeCompatRegistry(t, tc.input))
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("error = %v, want containing %q", err, tc.want)
			}
		})
	}
}

func writeCompatRegistry(t *testing.T, content string) string {
	t.Helper()
	root := t.TempDir()
	path := filepath.Join(root, "META", "compat", "registry.toml")
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	return root
}
