package installer

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/Szmelc-INC/CONVENTIONS.md/internal/config"
)

type Target struct {
	Harness string `json:"harness"`
	Home    string `json:"home"`
	State   string `json:"state"`
	Path    string `json:"path"`
}

var Harnesses = []string{"agents", "claude", "codex", "gemini", "grok", "jcode", "kiro", "opencode", "qwen", "windsurf"}

func Status() []Target {
	out := []Target{}
	root := repoRoot()
	for _, h := range Harnesses {
		home := config.HomeForHarness(h)
		if home == "" {
			continue
		}
		st := "missing"
		if _, e := os.Stat(home); e == nil {
			st = "detected"
		}
		link := filepath.Join(home, "conventions")
		if p, e := os.Readlink(link); e == nil {
			if root != "" && filepath.Clean(p) == filepath.Clean(root) {
				st = "linked"
			} else {
				st = "foreign-link"
			}
		}
		out = append(out, Target{h, home, st, link})
	}
	return out
}
func Apply(uninstall bool, selected []string, dryRun bool) error {
	allow := map[string]bool{}
	for _, h := range selected {
		allow[h] = true
	}
	root := repoRoot()
	if root == "" {
		return fmt.Errorf("cannot locate the conventions checkout; set CONVENTIONS_REPO or run from its root")
	}
	for _, t := range Status() {
		if len(allow) > 0 && !allow[t.Harness] {
			continue
		}
		if uninstall {
			p, e := os.Readlink(t.Path)
			if e == nil && filepath.Clean(p) == filepath.Clean(root) {
				if dryRun {
					continue
				}
				if e = os.Remove(t.Path); e != nil {
					return e
				}
			}
			continue
		}
		if _, e := os.Stat(t.Home); e != nil {
			if len(allow) == 0 {
				continue
			}
			if dryRun {
				continue
			}
			if e := os.MkdirAll(t.Home, 0755); e != nil {
				return e
			}
		}
		if dryRun {
			if _, e := os.Lstat(t.Path); e == nil {
				if p, re := os.Readlink(t.Path); re == nil && filepath.Clean(p) == filepath.Clean(root) {
					continue
				}
				return fmt.Errorf("refusing to replace existing path %s", t.Path)
			}
			continue
		}
		if e := os.MkdirAll(t.Home, 0755); e != nil {
			return e
		}
		if _, e := os.Lstat(t.Path); e == nil {
			return fmt.Errorf("refusing to replace existing path %s", t.Path)
		}
		if e := os.Symlink(root, t.Path); e != nil {
			return fmt.Errorf("link %s: %w", t.Path, e)
		}
	}
	return nil
}
func repoRoot() string {
	if v := os.Getenv("CONVENTIONS_REPO"); v != "" {
		if abs, err := filepath.Abs(v); err == nil {
			return abs
		}
		return ""
	}
	cwd, err := os.Getwd()
	if err != nil {
		return ""
	}
	for dir := cwd; ; dir = filepath.Dir(dir) {
		if _, err := os.Stat(filepath.Join(dir, "AGENTS", "global", "AGENTS.md")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
	}
	return ""
}
func ParseOnly(v string) ([]string, error) {
	if strings.TrimSpace(v) == "" {
		return nil, nil
	}
	valid := map[string]bool{}
	for _, h := range Harnesses {
		valid[h] = true
	}
	out := []string{}
	for _, h := range strings.Split(v, ",") {
		h = strings.TrimSpace(h)
		if !valid[h] {
			return nil, fmt.Errorf("unknown harness %q", h)
		}
		out = append(out, h)
	}
	sort.Strings(out)
	return out, nil
}
