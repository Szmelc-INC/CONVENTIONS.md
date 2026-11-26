package lint

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type Finding struct {
	ID      string `json:"ruleId"`
	Message string `json:"message"`
	File    string `json:"file"`
	Line    int    `json:"line"`
}
type Report struct {
	Findings []Finding `json:"findings"`
	Files    int       `json:"files"`
}

func Run(root string) Report {
	report := Report{}
	_ = filepath.WalkDir(root, func(p string, d os.DirEntry, e error) error {
		if e != nil {
			return nil
		}
		if d.IsDir() {
			if p != root && (d.Name() == ".git" || d.Name() == "vendor" || d.Name() == "node_modules") {
				return filepath.SkipDir
			}
			return nil
		}
		if filepath.Ext(p) != ".md" {
			return nil
		}
		report.Files++
		b, err := os.ReadFile(p)
		if err != nil {
			return nil
		}
		text := string(b)
		rel, _ := filepath.Rel(root, p)
		rel = filepath.ToSlash(rel)
		if !isRuleDocument(rel, text) {
			return nil
		}
		lines := strings.Split(text, "\n")
		titleLine, triggerLine := -1, -1
		front := len(lines) > 0 && strings.TrimSpace(lines[0]) == "---"
		closed := !front
		for i, line := range lines {
			t := strings.TrimSpace(line)
			if front {
				if i > 0 && t == "---" {
					front = false
					closed = true
				}
				continue
			}
			if titleLine < 0 && strings.HasPrefix(t, "# ") {
				titleLine = i
			}
			if triggerLine < 0 && strings.HasPrefix(t, "> Load when: ") {
				triggerLine = i
			}
		}
		if titleLine < 0 {
			report.Findings = append(report.Findings, Finding{"CONV002", "Missing Markdown title", rel, 1})
		}
		if triggerLine < 0 {
			report.Findings = append(report.Findings, Finding{"CONV003", "Missing load trigger", rel, 1})
		} else if titleLine < 0 || triggerLine != titleLine+1 {
			report.Findings = append(report.Findings, Finding{"CONV001", "Load-when line must follow the title", rel, triggerLine + 1})
		}
		if !closed {
			report.Findings = append(report.Findings, Finding{"CONV004", "Unclosed YAML front matter", rel, 1})
		}
		return nil
	})
	return report
}

func isRuleDocument(path, text string) bool {
	if strings.HasPrefix(path, "CONVENTIONS/LEGACY/") {
		return false
	}
	if strings.Contains(path, "/tests/invalid/") || strings.Contains(path, "/fixtures/invalid/") {
		return false
	}
	if strings.HasPrefix(text, "---\n") && strings.Contains(text, "\nid:") {
		return true
	}
	for _, prefix := range []string{"CONVENTIONS/", "HUMANS/", "CONTRIBUTING/", "AGENTS/PROMPT/", "AGENTS/RULES/", "AGENTS/modes/"} {
		if strings.HasPrefix(path, prefix) && path != prefix+"README.md" {
			return true
		}
	}
	if path == "CONVENTIONS/README.md" || path == "HUMANS/README.md" || path == "CONTRIBUTING/README.md" {
		return true
	}
	return false
}
func SARIF(r Report) []byte {
	type loc struct {
		Physical struct {
			ArtifactLocation struct {
				URI string `json:"uri"`
			} `json:"artifactLocation"`
			Region struct {
				StartLine int `json:"startLine"`
			} `json:"region"`
		} `json:"physicalLocation"`
	}
	type result struct {
		RuleID  string `json:"ruleId"`
		Level   string `json:"level"`
		Message struct {
			Text string `json:"text"`
		} `json:"message"`
		Locations []loc `json:"locations"`
	}
	results := make([]result, 0, len(r.Findings))
	for _, f := range r.Findings {
		x := result{RuleID: f.ID, Level: "error", Locations: []loc{{}}}
		x.Message.Text = f.Message
		x.Locations[0].Physical.ArtifactLocation.URI = f.File
		x.Locations[0].Physical.Region.StartLine = f.Line
		results = append(results, x)
	}
	payload := map[string]any{"$schema": "https://json.schemastore.org/sarif-2.1.0.json", "version": "2.1.0", "runs": []any{map[string]any{"tool": map[string]any{"driver": map[string]any{"name": "conventions", "informationUri": "https://github.com/Szmelc-INC/CONVENTIONS.md"}}, "results": results}}}
	b, e := json.MarshalIndent(payload, "", "  ")
	if e != nil {
		return []byte(fmt.Sprint(e))
	}
	return append(b, '\n')
}
