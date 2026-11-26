package build

import (
	"bytes"
	"encoding/json"
	"fmt"
	"sort"
	"strings"
)

// SiteDataInput contains the deterministic data-stage values collected by
// META/tools/site.sh. Network-derived project, release, roadmap, and star data
// remains the caller's responsibility; this renderer performs no I/O.
type SiteDataInput struct {
	Profile      string
	ProjectName  string
	Brand        string
	Organization string
	OrgURL       string
	InstallPath  string
	Repo         string
	Raw          string
	Site         string
	Roadmap      string
	Built        string
	Release      json.RawMessage
	Stars        json.RawMessage
	ProjectsNote string
	Owners       []string
	ProfileNav   json.RawMessage
	Cores        []json.RawMessage
	Rules        []json.RawMessage
	Skills       []json.RawMessage
	Experimental []json.RawMessage
	Legacy       []json.RawMessage
	Projects     []json.RawMessage
	Paths        json.RawMessage
	Icons        json.RawMessage
	CompatGitHub json.RawMessage
	Index        json.RawMessage
}

type siteIndex struct {
	Entries []struct {
		Path   string          `json:"path"`
		Origin json.RawMessage `json:"origin"`
		Compat []string        `json:"compat"`
	} `json:"entries"`
	Compatible           []siteCompatible `json:"compatible"`
	CompatibleDisclaimer string           `json:"compatible_disclaimer"`
}

type siteIndexRaw struct {
	Compatible json.RawMessage `json:"compatible"`
}

type siteCompatible struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Kind        string            `json:"kind"`
	Version     string            `json:"version"`
	Description string            `json:"description"`
	Icon        *string           `json:"icon"`
	Links       map[string]string `json:"links"`
}

type siteRule struct {
	Core   string          `json:"core"`
	Cat    string          `json:"cat"`
	Path   string          `json:"path"`
	Title  string          `json:"title"`
	Load   string          `json:"load"`
	Src    string          `json:"src"`
	Loc    json.RawMessage `json:"loc,omitempty"`
	Origin json.RawMessage `json:"origin"`
	Compat []string        `json:"compat"`
}

type siteCompatGitHub struct {
	Stars   json.RawMessage `json:"stars"`
	Updated json.RawMessage `json:"updated"`
	Lang    string          `json:"lang"`
}

type siteThirdParty struct {
	ID      string          `json:"id"`
	Name    string          `json:"name"`
	Kind    string          `json:"kind"`
	Version string          `json:"version"`
	Desc    string          `json:"desc"`
	Icon    *string         `json:"icon"`
	URL     string          `json:"url"`
	Home    string          `json:"home"`
	Origin  string          `json:"origin"`
	Stars   json.RawMessage `json:"stars"`
	Updated json.RawMessage `json:"updated"`
	Lang    string          `json:"lang"`
}

type siteData struct {
	Name                 string            `json:"name"`
	ProjectName          string            `json:"project_name"`
	Brand                string            `json:"brand"`
	Organization         string            `json:"organization"`
	OrgURL               string            `json:"org_url"`
	InstallPath          string            `json:"install_path"`
	ProfileNav           json.RawMessage   `json:"profile_nav"`
	Repo                 string            `json:"repo"`
	Raw                  string            `json:"raw"`
	Site                 string            `json:"site"`
	Roadmap              string            `json:"roadmap"`
	Built                string            `json:"built"`
	Release              json.RawMessage   `json:"release"`
	Stars                json.RawMessage   `json:"stars"`
	Cores                []json.RawMessage `json:"cores"`
	Rules                []siteRule        `json:"rules"`
	Skills               []json.RawMessage `json:"skills"`
	Experimental         []json.RawMessage `json:"experimental"`
	Legacy               []json.RawMessage `json:"legacy"`
	Compatible           json.RawMessage   `json:"compatible"`
	CompatibleDisclaimer string            `json:"compatible_disclaimer"`
	Icons                json.RawMessage   `json:"icons"`
	Projects             []json.RawMessage `json:"projects"`
	ProjectsNote         string            `json:"projects_note"`
	Owners               []string          `json:"owners"`
	Paths                json.RawMessage   `json:"paths"`
	ThirdParty           []siteThirdParty  `json:"third_party"`
}

// SiteData assembles the site's conventions.json data object from deterministic
// checked-in build outputs and caller-supplied runtime data. It mirrors the
// final data assembly in META/tools/site.sh without fetching APIs or touching
// the filesystem. The HTML template and source discovery are not part of this
// renderer yet.
func SiteData(in SiteDataInput) ([]byte, error) {
	var index siteIndex
	if err := json.Unmarshal(in.Index, &index); err != nil {
		return nil, fmt.Errorf("decode site index: %w", err)
	}
	if len(in.Index) == 0 || string(bytes.TrimSpace(in.Index)) == "null" {
		return nil, fmt.Errorf("decode site index: expected JSON object")
	}
	var indexRaw siteIndexRaw
	if err := json.Unmarshal(in.Index, &indexRaw); err != nil || len(indexRaw.Compatible) == 0 {
		return nil, fmt.Errorf("decode site index: missing compatible array")
	}
	if err := requireJSONArray("site index compatible", indexRaw.Compatible); err != nil {
		return nil, err
	}
	if err := requireJSON("profile navigation", in.ProfileNav); err != nil {
		return nil, err
	}
	if err := requireJSONArray("profile navigation", in.ProfileNav); err != nil {
		return nil, err
	}
	if err := requireJSON("paths", in.Paths); err != nil {
		return nil, err
	}
	if err := requireJSONArray("paths", in.Paths); err != nil {
		return nil, err
	}
	if err := requireJSON("icons", in.Icons); err != nil {
		return nil, err
	}
	if err := requireJSONObject("icons", in.Icons); err != nil {
		return nil, err
	}
	if err := requireJSON("compatibility GitHub data", in.CompatGitHub); err != nil {
		return nil, err
	}
	if err := requireJSON("release", in.Release); err != nil {
		return nil, err
	}
	if err := requireJSON("stars", in.Stars); err != nil {
		return nil, err
	}
	var compatRows []struct {
		Key   string           `json:"key"`
		Value siteCompatGitHub `json:"value"`
	}
	if err := json.Unmarshal(in.CompatGitHub, &compatRows); err != nil {
		return nil, fmt.Errorf("decode compatibility GitHub data: %w", err)
	}
	compatGitHub := make(map[string]siteCompatGitHub, len(compatRows))
	for _, row := range compatRows {
		compatGitHub[row.Key] = row.Value
	}
	origins := make(map[string]siteIndexEntry, len(index.Entries))
	for _, entry := range index.Entries {
		compat := entry.Compat
		if compat == nil {
			compat = []string{}
		}
		origins[entry.Path] = siteIndexEntry{origin: nonNull(entry.Origin), compat: compat}
	}
	rules := make([]siteRule, 0, len(in.Rules))
	for i, raw := range in.Rules {
		var rule siteRule
		if err := json.Unmarshal(raw, &rule); err != nil {
			return nil, fmt.Errorf("decode site rule %d: %w", i, err)
		}
		if rule.Path == "" {
			return nil, fmt.Errorf("decode site rule %d: missing path", i)
		}
		entry, found := origins[rule.Path]
		if !found {
			entry.compat = []string{}
		}
		if len(entry.origin) == 0 {
			rule.Origin = json.RawMessage("null")
		} else {
			rule.Origin = entry.origin
		}
		rule.Compat = entry.compat
		rules = append(rules, rule)
	}
	type datedProject struct {
		raw     json.RawMessage
		updated string
		hasDate bool
	}
	orderedProjects := make([]datedProject, 0, len(in.Projects))
	for i, raw := range in.Projects {
		updated, hasDate, err := projectUpdated(raw)
		if err != nil {
			return nil, fmt.Errorf("decode project %d updated timestamp: %w", i, err)
		}
		orderedProjects = append(orderedProjects, datedProject{raw: raw, updated: updated, hasDate: hasDate})
	}
	sort.SliceStable(orderedProjects, func(i, j int) bool {
		if orderedProjects[i].hasDate != orderedProjects[j].hasDate {
			return !orderedProjects[i].hasDate
		}
		return orderedProjects[i].updated < orderedProjects[j].updated
	})
	projects := make([]json.RawMessage, 0, len(orderedProjects))
	for i := len(orderedProjects) - 1; i >= 0; i-- {
		projects = append(projects, orderedProjects[i].raw)
	}
	thirdParty := make([]siteThirdParty, 0, len(index.Compatible))
	for _, c := range index.Compatible {
		url := c.Links["repo"]
		if url == "" {
			url = c.Links["homepage"]
		}
		home := c.Links["homepage"]
		gh := compatGitHub[c.ID]
		if len(gh.Stars) == 0 {
			gh.Stars = json.RawMessage("null")
		}
		if len(gh.Updated) == 0 {
			gh.Updated = json.RawMessage("null")
		}
		thirdParty = append(thirdParty, siteThirdParty{
			ID: c.ID, Name: c.Name, Kind: c.Kind, Version: c.Version,
			Desc: c.Description, Icon: c.Icon, URL: url, Home: home,
			Origin: "third-party", Stars: gh.Stars, Updated: gh.Updated, Lang: gh.Lang,
		})
	}
	data := siteData{
		Name: in.Profile, ProjectName: in.ProjectName, Brand: in.Brand,
		Organization: in.Organization, OrgURL: in.OrgURL, InstallPath: in.InstallPath,
		ProfileNav: in.ProfileNav, Repo: in.Repo, Raw: in.Raw, Site: in.Site,
		Roadmap: in.Roadmap, Built: in.Built, Release: in.Release, Stars: in.Stars,
		Cores: nonNilRaw(in.Cores), Rules: rules, Skills: nonNilRaw(in.Skills), Experimental: nonNilRaw(in.Experimental),
		Legacy: nonNilRaw(in.Legacy), Compatible: indexRaw.Compatible,
		CompatibleDisclaimer: index.CompatibleDisclaimer, Icons: in.Icons,
		Projects: nonNilRaw(projects), ProjectsNote: in.ProjectsNote, Owners: nonNilStrings(in.Owners),
		Paths: in.Paths, ThirdParty: thirdParty,
	}
	var out bytes.Buffer
	enc := json.NewEncoder(&out)
	enc.SetEscapeHTML(false)
	enc.SetIndent("", "  ")
	if err := enc.Encode(data); err != nil {
		return nil, fmt.Errorf("encode site data: %w", err)
	}
	return out.Bytes(), nil
}

type siteIndexEntry struct {
	origin json.RawMessage
	compat []string
}

func nonNull(raw json.RawMessage) json.RawMessage {
	if len(raw) == 0 || strings.TrimSpace(string(raw)) == "null" {
		return nil
	}
	return raw
}

func requireJSON(name string, raw json.RawMessage) error {
	if len(raw) == 0 || !json.Valid(raw) {
		return fmt.Errorf("%s: expected valid JSON", name)
	}
	return nil
}

func requireJSONArray(name string, raw json.RawMessage) error {
	var value []json.RawMessage
	if err := json.Unmarshal(raw, &value); err != nil || value == nil {
		return fmt.Errorf("%s: expected JSON array", name)
	}
	return nil
}

func requireJSONObject(name string, raw json.RawMessage) error {
	var value map[string]json.RawMessage
	if err := json.Unmarshal(raw, &value); err != nil || value == nil {
		return fmt.Errorf("%s: expected JSON object", name)
	}
	return nil
}

func projectUpdated(raw json.RawMessage) (string, bool, error) {
	var p map[string]json.RawMessage
	if err := json.Unmarshal(raw, &p); err != nil || p == nil {
		if err != nil {
			return "", false, err
		}
		return "", false, fmt.Errorf("expected JSON object")
	}
	updated := p["updated"]
	if len(updated) == 0 || string(bytes.TrimSpace(updated)) == "null" {
		return "", false, nil
	}
	var value string
	if err := json.Unmarshal(updated, &value); err != nil {
		return "", false, err
	}
	return value, true, nil
}

func nonNilRaw(items []json.RawMessage) []json.RawMessage {
	if items == nil {
		return []json.RawMessage{}
	}
	return items
}

func nonNilStrings(items []string) []string {
	if items == nil {
		return []string{}
	}
	return items
}
