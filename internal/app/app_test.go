package app

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/Szmelc-INC/CONVENTIONS.md/internal/catalog"
	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/viewport"
	"github.com/charmbracelet/glamour"
	"github.com/charmbracelet/glamour/styles"
)

func TestVersionJSONAndUsageExit(t *testing.T) {
	var out, errOut bytes.Buffer
	if code := Run([]string{"version", "--json"}, &out, &errOut); code != 0 || !strings.Contains(out.String(), `"version"`) {
		t.Fatalf("version: code=%d out=%q err=%q", code, out.String(), errOut.String())
	}
	out.Reset()
	errOut.Reset()
	if code := Run([]string{"nonesuch"}, &out, &errOut); code != 2 || !strings.Contains(errOut.String(), "E_USAGE") {
		t.Fatalf("usage: code=%d err=%q", code, errOut.String())
	}
}

func TestCompletionShells(t *testing.T) {
	for _, shell := range []string{"zsh", "bash", "fish"} {
		if got, err := completion(shell); err != nil || !strings.Contains(got, "conventions") {
			t.Fatalf("%s completion: %q, %v", shell, got, err)
		}
	}
}

func TestNoColorOverridesAlwaysConfig(t *testing.T) {
	t.Setenv("NO_COLOR", "")
	path := filepath.Join(t.TempDir(), "config.toml")
	if err := os.WriteFile(path, []byte("color = \"always\"\nprofile = \"neutral\"\n"), 0600); err != nil {
		t.Fatal(err)
	}
	var out, errOut bytes.Buffer
	if code := Run([]string{"--config", path, "lint", "--help"}, &out, &errOut); code != 0 {
		t.Fatalf("default help: %d %s", code, errOut.String())
	}
	if !strings.Contains(out.String(), "\x1b[") {
		t.Fatal("color=always did not style help")
	}
	for _, flag := range []string{"--no-color"} {
		out.Reset()
		errOut.Reset()
		if code := Run([]string{"--config", path, flag, "lint", "--help"}, &out, &errOut); code != 0 {
			t.Fatalf("%s help: %d %s", flag, code, errOut.String())
		}
		if strings.Contains(out.String(), "\x1b[") {
			t.Fatalf("%s did not override color=always", flag)
		}
	}
	t.Setenv("NO_COLOR", "1")
	out.Reset()
	errOut.Reset()
	if code := Run([]string{"--config", path, "lint", "--help"}, &out, &errOut); code != 0 {
		t.Fatalf("NO_COLOR help: %d %s", code, errOut.String())
	}
	if strings.Contains(out.String(), "\x1b[") {
		t.Fatal("NO_COLOR did not override color=always")
	}
}

func TestTUIStylesRespectNoColor(t *testing.T) {
	t.Setenv("NO_COLOR", "")
	for _, render := range []func(string, bool) string{tuiAccent, func(s string, off bool) string { return tuiSubdued(s, off) }} {
		if got := render("plain", true); got != "plain" {
			t.Fatalf("expected unstyled text, got %q", got)
		}
	}
	if !shouldDisableTUIColor(false, "never") || !shouldDisableTUIColor(true, "always") {
		t.Fatal("explicit no-color sources must take precedence")
	}
	t.Setenv("NO_COLOR", "1")
	if !shouldDisableTUIColor(false, "always") {
		t.Fatal("NO_COLOR must disable TUI colors")
	}
	t.Setenv("NO_COLOR", "")
	renderer, err := glamour.NewTermRenderer(glamour.WithStyles(styles.ASCIIStyleConfig))
	if err != nil {
		t.Fatal(err)
	}
	item := docItem{catalog.Rule{ID: "example", Title: "Example", Path: "CONVENTIONS/example.md"}}
	l := list.New([]list.Item{item}, list.NewDefaultDelegate(), 40, 8)
	m := tuiModel{list: l, detail: viewport.New(20, 5), renderer: renderer, noColor: true}
	m.detail.SetContent("\x1b[31mmarkdown\x1b[0m")
	if view := m.View(); strings.Contains(view, "\x1b[") {
		t.Fatalf("TUI view contains ANSI sequences: %q", view)
	}
}

func TestPaletteOpenWithoutRendererIsSafe(t *testing.T) {
	m := tuiModel{items: []catalog.Rule{{ID: "sample", Body: "# Sample"}}}
	if cmd := m.executeCommand("open sample"); cmd != nil {
		t.Fatal("open should not schedule a command")
	}
	if m.message != "Markdown renderer unavailable." {
		t.Fatalf("message = %q", m.message)
	}
}

func TestInstallerDryRunAndUninstallConfirmation(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("USERPROFILE", "")
	t.Setenv("CONVENTIONS_REPO", "")
	var out, errOut bytes.Buffer
	if code := Run([]string{"install", "--only", "codex", "--dry-run"}, &out, &errOut); code != 0 {
		t.Fatalf("dry run: %d %s", code, errOut.String())
	}
	if _, err := os.Stat(filepath.Join(home, ".codex")); !os.IsNotExist(err) {
		t.Fatalf("dry run changed home: %v", err)
	}
	out.Reset()
	errOut.Reset()
	if code := Run([]string{"uninstall", "--only", "codex"}, &out, &errOut); code != 2 || !strings.Contains(errOut.String(), "E_CONFIRM_REQUIRED") {
		t.Fatalf("uninstall confirmation: %d %q", code, errOut.String())
	}
}

func TestMatchUsesFileContext(t *testing.T) {
	path := filepath.Join(t.TempDir(), "billing.md")
	if err := os.WriteFile(path, []byte("payment reconciliation"), 0600); err != nil {
		t.Fatal(err)
	}
	rules := []catalog.Rule{
		{ID: "payments.rules", Title: "Payments", Trigger: "Load when processing payments", Path: "CONVENTIONS/PAYMENTS.md"},
		{ID: "terminal.rules", Title: "Terminal UI", Trigger: "Load when building a terminal UI", Path: "CONVENTIONS/TUI.md"},
	}
	got, err := matchRules(rules, "update this document", []string{path})
	if err != nil || len(got) != 1 || got[0].ID != "payments.rules" {
		t.Fatalf("got %#v, err %v", got, err)
	}
	if _, err := matchRules(rules, "task", []string{path + ".missing"}); err == nil {
		t.Fatal("expected file read error")
	}
}

func TestBuildReportsUnimplemented(t *testing.T) {
	var out, errOut bytes.Buffer
	if code := Run([]string{"build"}, &out, &errOut); code != 1 || !strings.Contains(errOut.String(), "E_NOT_IMPLEMENTED") {
		t.Fatalf("build: code=%d err=%q", code, errOut.String())
	}
}
