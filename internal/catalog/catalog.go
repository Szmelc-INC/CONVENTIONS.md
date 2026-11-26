package catalog

import (
	"bufio"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type Rule struct{ Path, ID, Title, Trigger, Body string }

func Find(root string) ([]Rule, error) {
	var paths []string
	for _, base := range []string{"CONVENTIONS", "AGENTS", "HUMANS", "CONTRIBUTING", "TEMPLATES"} {
		_ = filepath.WalkDir(filepath.Join(root, base), func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return nil
			}
			if !d.IsDir() && strings.EqualFold(filepath.Ext(path), ".md") {
				paths = append(paths, path)
			}
			return nil
		})
	}
	sort.Strings(paths)
	out := make([]Rule, 0, len(paths))
	for _, p := range paths {
		data, err := os.ReadFile(p)
		if err != nil {
			continue
		}
		text := string(data)
		rel, _ := filepath.Rel(root, p)
		out = append(out, parse(rel, text))
	}
	return out, nil
}
func parse(path, text string) Rule {
	r := Rule{Path: filepath.ToSlash(path), Body: text}
	lines := strings.Split(text, "\n")
	front := false
	for i, line := range lines {
		t := strings.TrimSpace(line)
		if i == 0 && t == "---" {
			front = true
			continue
		}
		if front && t == "---" {
			front = false
			continue
		}
		if front {
			if strings.HasPrefix(t, "id:") {
				r.ID = strings.TrimSpace(strings.Trim(strings.TrimPrefix(t, "id:"), "\"'"))
			}
			continue
		}
		if r.Title == "" && strings.HasPrefix(t, "# ") {
			r.Title = strings.TrimSpace(strings.TrimPrefix(t, "# "))
		}
		if r.Trigger == "" && strings.HasPrefix(t, "> Load when: ") {
			r.Trigger = strings.TrimPrefix(t, "> Load when: ")
		}
	}
	return r
}
func ReadFile(path string) (string, error) {
	f, e := os.Open(path)
	if e != nil {
		return "", e
	}
	defer f.Close()
	var b strings.Builder
	s := bufio.NewScanner(f)
	for s.Scan() {
		b.WriteString(s.Text())
		b.WriteByte('\n')
	}
	return b.String(), s.Err()
}
