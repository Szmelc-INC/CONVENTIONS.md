package build

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestDefaultProfileReadsTheMarkerFile(t *testing.T) {
	for _, tc := range []struct{ name, content, want string }{
		{"absent", "", "neutral"},
		{"id", "team\n", "team"},
		{"comment and spaces", "# the profile used when none is named\n  team  \n", "team"},
		{"comments only", "# none yet\n\n", "neutral"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			root := t.TempDir()
			if tc.content != "" {
				if err := os.MkdirAll(filepath.Join(root, "PROFILES"), 0700); err != nil {
					t.Fatal(err)
				}
				if err := os.WriteFile(filepath.Join(root, "PROFILES", "DEFAULT"), []byte(tc.content), 0600); err != nil {
					t.Fatal(err)
				}
			}
			if got := DefaultProfile(root); got != tc.want {
				t.Fatalf("DefaultProfile() = %q, want %q", got, tc.want)
			}
		})
	}
}

func TestIndexProfileUsesTheDefaultWhenNoneIsNamed(t *testing.T) {
	root := t.TempDir()
	write := func(path, content string) {
		t.Helper()
		if err := os.MkdirAll(filepath.Dir(filepath.Join(root, path)), 0700); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(root, path), []byte(content), 0600); err != nil {
			t.Fatal(err)
		}
	}
	write("PROFILES/neutral/profile.toml", "[profile]\nskill_name = \"conventions\"\nraw_url = \"https://example.invalid/raw\"\n")
	write("PROFILES/team/profile.toml", "[profile]\nskill_name = \"team-conventions\"\n")
	write("PROFILES/DEFAULT", "# used when none is named\nteam\n")

	unnamed, _, err := indexProfile(root, "", nil)
	if err != nil {
		t.Fatal(err)
	}
	if unnamed["profile.skill_name"] != "team-conventions" || unnamed["profile.raw_url"] != "https://example.invalid/raw" {
		t.Fatalf("unnamed profile = %v, want team on top of neutral", unnamed)
	}
	named, _, err := indexProfile(root, "neutral", nil)
	if err != nil {
		t.Fatal(err)
	}
	if named["profile.skill_name"] != "conventions" {
		t.Fatalf("neutral profile = %v", named)
	}
	write("PROFILES/DEFAULT", "missing\n")
	if _, _, err := indexProfile(root, "", nil); err == nil || !strings.Contains(err.Error(), "profile not found") {
		t.Fatalf("error = %v, want profile not found", err)
	}
}
