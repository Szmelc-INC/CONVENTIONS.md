package installer

import (
	"os"
	"path/filepath"
	"testing"
)

func TestInstallUninstallAndRefuseForeignPath(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("USERPROFILE", "")
	t.Setenv("CONVENTIONS_REPO", "")
	root := repoRoot()
	if root == "" {
		t.Fatal("test must run inside a conventions checkout")
	}
	codex := filepath.Join(home, ".codex")
	if err := Apply(false, []string{"codex"}, true); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Lstat(codex); !os.IsNotExist(err) {
		t.Fatalf("dry run created harness home: %v", err)
	}
	if err := os.MkdirAll(codex, 0700); err != nil {
		t.Fatal(err)
	}
	foreign := filepath.Join(codex, "conventions")
	if err := os.WriteFile(foreign, []byte("keep"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := Apply(false, []string{"codex"}, false); err == nil {
		t.Fatal("expected refusal to replace existing file")
	}
	if b, err := os.ReadFile(foreign); err != nil || string(b) != "keep" {
		t.Fatalf("existing file changed: %q, %v", b, err)
	}
	if err := os.Remove(foreign); err != nil {
		t.Fatal(err)
	}
	if err := Apply(false, []string{"codex"}, false); err != nil {
		t.Fatal(err)
	}
	if p, err := os.Readlink(foreign); err != nil || filepath.Clean(p) != filepath.Clean(root) {
		t.Fatalf("link=%q err=%v", p, err)
	}
	if err := Apply(true, []string{"codex"}, true); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Lstat(foreign); err != nil {
		t.Fatalf("dry run removed link: %v", err)
	}
	if err := Apply(true, []string{"codex"}, false); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Lstat(foreign); !os.IsNotExist(err) {
		t.Fatalf("link still exists: %v", err)
	}
}
