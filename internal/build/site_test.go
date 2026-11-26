package build

import (
	"bytes"
	"encoding/json"
	"path/filepath"
	"strings"
	"testing"
)

func TestSiteDataMatchesGolden(t *testing.T) {
	in := SiteDataInput{
		Profile: "neutral", ProjectName: "Conventions", Brand: "Szmelc",
		Organization: "Szmelc, Inc.", OrgURL: "https://example.test/org",
		InstallPath: "install.sh", Repo: "https://example.test/repo",
		Raw: "https://example.test/raw", Site: "https://example.test/site",
		Roadmap: "https://example.test/roadmap", Built: "2026-01-02T03:04:05Z",
		Release: json.RawMessage(`{"tag":"v1.0","url":"https://example.test/releases/v1.0"}`),
		Stars:   json.RawMessage(`17`), ProjectsNote: "No repositories were returned.",
		Owners:       []string{"Szmelc-INC"},
		ProfileNav:   json.RawMessage(`[{"id":"neutral","label":"Neutral","href":"./"}]`),
		Cores:        []json.RawMessage{json.RawMessage(`{"id":"CONVENTIONS","title":"Rules","readme":"Guide","map":"CONVENTIONS.md","files":[]}`)},
		Rules:        []json.RawMessage{json.RawMessage(`{"core":"CONVENTIONS","cat":"WORKFLOW","path":"CONVENTIONS/WORKFLOW/RULE.md","title":"Rule","load":"when needed","src":"Use <safe> & clear.","loc":{"pl":"Używaj jasno."}}`)},
		Skills:       []json.RawMessage{json.RawMessage(`{"path":"SKILL.md","name":"conventions","desc":"Entry point"}`)},
		Experimental: []json.RawMessage{},
		Legacy:       []json.RawMessage{},
		Projects:     []json.RawMessage{json.RawMessage(`{"name":"older","updated":"2025-01-01T00:00:00Z"}`), json.RawMessage(`{"name":"newer","updated":"2026-01-01T00:00:00Z"}`)},
		Paths:        json.RawMessage(`["CONVENTIONS/WORKFLOW/RULE.md"]`),
		Icons:        json.RawMessage(`{"META/compat/icons/spec.svg":"M0 0"}`),
		CompatGitHub: json.RawMessage(`[ {"key":"spec","value":{"stars":12,"updated":"2025-12-01T00:00:00Z","lang":"Go"}} ]`),
		Index: json.RawMessage(`{
  "entries": [
    {"path":"CONVENTIONS/WORKFLOW/RULE.md","origin":"profile","compat":["spec"]}
  ],
  "compatible_disclaimer":"Verify the source.",
  "compatible":[
    {"id":"spec","name":"Example Spec","kind":"format","version":"1.0","description":"Spec & docs","icon":"META/compat/icons/spec.svg","links":{"repo":"https://example.test/spec","homepage":"https://example.test/home"}}
  ]
}`),
	}
	got, err := SiteData(in)
	if err != nil {
		t.Fatal(err)
	}
	const want = `{
  "name": "neutral",
  "project_name": "Conventions",
  "brand": "Szmelc",
  "organization": "Szmelc, Inc.",
  "org_url": "https://example.test/org",
  "install_path": "install.sh",
  "profile_nav": [
    {
      "id": "neutral",
      "label": "Neutral",
      "href": "./"
    }
  ],
  "repo": "https://example.test/repo",
  "raw": "https://example.test/raw",
  "site": "https://example.test/site",
  "roadmap": "https://example.test/roadmap",
  "built": "2026-01-02T03:04:05Z",
  "release": {
    "tag": "v1.0",
    "url": "https://example.test/releases/v1.0"
  },
  "stars": 17,
  "cores": [
    {
      "id": "CONVENTIONS",
      "title": "Rules",
      "readme": "Guide",
      "map": "CONVENTIONS.md",
      "files": []
    }
  ],
  "rules": [
    {
      "core": "CONVENTIONS",
      "cat": "WORKFLOW",
      "path": "CONVENTIONS/WORKFLOW/RULE.md",
      "title": "Rule",
      "load": "when needed",
      "src": "Use <safe> & clear.",
      "loc": {
        "pl": "Używaj jasno."
      },
      "origin": "profile",
      "compat": [
        "spec"
      ]
    }
  ],
  "skills": [
    {
      "path": "SKILL.md",
      "name": "conventions",
      "desc": "Entry point"
    }
  ],
  "experimental": [],
  "legacy": [],
  "compatible": [
    {
      "id": "spec",
      "name": "Example Spec",
      "kind": "format",
      "version": "1.0",
      "description": "Spec & docs",
      "icon": "META/compat/icons/spec.svg",
      "links": {
        "repo": "https://example.test/spec",
        "homepage": "https://example.test/home"
      }
    }
  ],
  "compatible_disclaimer": "Verify the source.",
  "icons": {
    "META/compat/icons/spec.svg": "M0 0"
  },
  "projects": [
    {
      "name": "newer",
      "updated": "2026-01-01T00:00:00Z"
    },
    {
      "name": "older",
      "updated": "2025-01-01T00:00:00Z"
    }
  ],
  "projects_note": "No repositories were returned.",
  "owners": [
    "Szmelc-INC"
  ],
  "paths": [
    "CONVENTIONS/WORKFLOW/RULE.md"
  ],
  "third_party": [
    {
      "id": "spec",
      "name": "Example Spec",
      "kind": "format",
      "version": "1.0",
      "desc": "Spec & docs",
      "icon": "META/compat/icons/spec.svg",
      "url": "https://example.test/spec",
      "home": "https://example.test/home",
      "origin": "third-party",
      "stars": 12,
      "updated": "2025-12-01T00:00:00Z",
      "lang": "Go"
    }
  ]
}
`
	if !bytes.Equal(got, []byte(want)) {
		t.Fatalf("SiteData() differs from golden output\n got:\n%s\nwant:\n%s", got, want)
	}
}

func TestSiteDataRejectsMalformedInputs(t *testing.T) {
	base := SiteDataInput{
		ProfileNav: json.RawMessage(`[]`), Paths: json.RawMessage(`[]`),
		Icons: json.RawMessage(`{}`), CompatGitHub: json.RawMessage(`[]`),
		Release: json.RawMessage(`{}`), Stars: json.RawMessage(`null`),
		Index: json.RawMessage(`{"entries":[],"compatible":[]}`),
	}
	base.Rules = []json.RawMessage{json.RawMessage(`{"core":"CONVENTIONS"}`)}
	if _, err := SiteData(base); err == nil || !strings.Contains(err.Error(), "missing path") {
		t.Fatalf("SiteData() error = %v, want missing path", err)
	}
	base.Rules = nil
	base.Index = json.RawMessage(`not json`)
	if _, err := SiteData(base); err == nil || !strings.Contains(err.Error(), "decode site index") {
		t.Fatalf("SiteData() error = %v, want invalid index error", err)
	}
	base.Index = json.RawMessage(`{"entries":[],"compatible_disclaimer":"","compatible":[]}`)
	base.Rules = []json.RawMessage{json.RawMessage(`{"core":"CONVENTIONS","path":"CONVENTIONS/WORKFLOW/RULE.md"}`)}
	got, err := SiteData(base)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Contains(got, []byte(`"origin": null`)) || !bytes.Contains(got, []byte(`"compat": []`)) {
		t.Fatalf("missing index entry did not get jq-compatible defaults:\n%s", got)
	}
}

func TestSiteDataPreservesCheckedInIndexCompatibilityBytes(t *testing.T) {
	root, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatal(err)
	}
	outputs, err := IndexOutputs(root, IndexOptions{Profile: "neutral"})
	if err != nil {
		t.Fatal(err)
	}
	input := SiteDataInput{
		Profile: "neutral", Release: json.RawMessage(`{}`), Stars: json.RawMessage(`null`),
		ProfileNav: json.RawMessage(`[]`), Paths: json.RawMessage(`[]`),
		Icons: json.RawMessage(`{}`), CompatGitHub: json.RawMessage(`[]`),
		Index: outputs["index.json"],
	}
	got, err := SiteData(input)
	if err != nil {
		t.Fatal(err)
	}
	var index struct {
		Compatible json.RawMessage `json:"compatible"`
	}
	if err := json.Unmarshal(outputs["index.json"], &index); err != nil {
		t.Fatal(err)
	}
	var want bytes.Buffer
	if err := json.Indent(&want, index.Compatible, "  ", "  "); err != nil {
		t.Fatal(err)
	}
	if !bytes.Contains(got, want.Bytes()) {
		t.Fatal("site data changed the byte order or values of the checked-in compatibility registry")
	}
}
