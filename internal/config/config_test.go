package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadDefaultsAndStrictKeys(t *testing.T) {
	got, err := Load(filepath.Join(t.TempDir(), "missing.toml"))
	if err != nil || got.Color != "auto" || got.Profile != "neutral" {
		t.Fatalf("defaults: %#v, %v", got, err)
	}
	p := filepath.Join(t.TempDir(), "config.toml")
	if err := os.WriteFile(p, []byte("color = \"auto\"\nunknown = true\n"), 0600); err != nil {
		t.Fatal(err)
	}
	if _, err := Load(p); err == nil {
		t.Fatal("expected unknown key error")
	}
}

func TestWindowsHarnessPath(t *testing.T) {
	t.Setenv("USERPROFILE", `C:\Users\Ada`)
	t.Setenv("HOME", "")
	got := HomeForHarness("codex")
	if got != filepath.Join(`C:\Users\Ada`, ".codex") {
		t.Fatalf("got %q", got)
	}
}
