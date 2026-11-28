package build

import (
	"os"
	"path/filepath"
	"strings"
)

// DefaultProfile returns the profile every tool uses when none is named: the
// first non-comment line of PROFILES/DEFAULT, or neutral when the file is absent.
// It matches default_profile() in META/tools/build.sh.
func DefaultProfile(root string) string {
	data, err := os.ReadFile(filepath.Join(root, "PROFILES", "DEFAULT"))
	if err != nil {
		return "neutral"
	}
	for _, line := range strings.Split(string(data), "\n") {
		if line = strings.TrimSpace(line); line != "" && !strings.HasPrefix(line, "#") {
			return line
		}
	}
	return "neutral"
}
