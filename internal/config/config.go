package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/BurntSushi/toml"
)

type Config struct {
	Color   string `toml:"color"`
	Profile string `toml:"profile"`
}

func DefaultPath() string {
	if p := os.Getenv("XDG_CONFIG_HOME"); p != "" {
		return filepath.Join(p, "conventions", "config.toml")
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".config", "conventions", "config.toml")
}

func Load(path string) (Config, error) {
	c := Config{Color: "auto", Profile: "neutral"}
	if path == "" {
		path = DefaultPath()
	}
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return c, nil
	}
	md, err := toml.DecodeFile(path, &c)
	if err != nil {
		return c, fmt.Errorf("config: %w", err)
	}
	for _, key := range md.Undecoded() {
		return c, fmt.Errorf("config: unknown key %q", key.String())
	}
	if c.Color != "auto" && c.Color != "always" && c.Color != "never" {
		return c, fmt.Errorf("config: color must be auto, always, or never")
	}
	if c.Profile == "" {
		return c, fmt.Errorf("config: profile must not be empty")
	}
	return c, nil
}

func HomeForHarness(harness string) string {
	home := strings.TrimSpace(os.Getenv("HOME"))
	if home == "" {
		home, _ = os.UserHomeDir()
	}
	if home == "" && os.Getenv("USERPROFILE") != "" {
		home = os.Getenv("USERPROFILE")
	}
	rel := map[string]string{"claude": ".claude", "codex": ".codex", "gemini": ".gemini", "qwen": ".qwen", "opencode": ".config/opencode", "kiro": ".kiro", "windsurf": ".codeium/windsurf", "grok": ".grok", "jcode": ".jcode", "agents": ".agents"}[harness]
	if rel == "" || home == "" {
		return ""
	}
	return filepath.Join(home, filepath.FromSlash(rel))
}
