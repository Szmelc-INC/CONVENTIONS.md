package app

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"

	"github.com/Szmelc-INC/CONVENTIONS.md/internal/catalog"
	"github.com/Szmelc-INC/CONVENTIONS.md/internal/config"
	"github.com/Szmelc-INC/CONVENTIONS.md/internal/installer"
	"github.com/Szmelc-INC/CONVENTIONS.md/internal/lint"
)

const version = "3.2.0-dev"

var commit = "unknown"

func Run(args []string, out, errOut io.Writer) int {
	if len(args) == 0 {
		help(out)
		return 0
	}
	jsonOut, noColor, configPath := false, false, ""
	filtered := []string{}
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--json":
			jsonOut = true
		case "--no-color":
			noColor = true
		case "--config":
			if i+1 >= len(args) {
				fmt.Fprintln(errOut, "E_USAGE: --config needs a path")
				return 2
			}
			i++
			configPath = args[i]
		default:
			filtered = append(filtered, args[i])
		}
	}
	cfg, e := config.Load(configPath)
	if e != nil {
		return fail(errOut, "E_CONFIG", e, 1)
	}
	args = filtered
	if len(args) == 0 {
		help(out)
		return 0
	}
	cmd, rest := args[0], args[1:]
	if has(rest, "--help") || has(rest, "-h") || (cmd == "help" && len(rest) > 0) {
		if cmd == "help" && len(rest) > 0 {
			cmd = rest[0]
		}
		color := cfg.Color == "always" || (cfg.Color == "auto" && !noColor && os.Getenv("NO_COLOR") == "" && isTerminal(out))
		if noColor || os.Getenv("NO_COLOR") != "" {
			color = false
		}
		commandHelp(out, cmd, color)
		return 0
	}
	switch cmd {
	case "help", "--help", "-h":
		help(out)
		return 0
	case "version":
		if jsonOut || has(rest, "--json") {
			_ = json.NewEncoder(out).Encode(map[string]string{"version": version, "go": runtime.Version(), "commit": commit})
		} else {
			fmt.Fprintln(out, version)
		}
		return 0
	case "init":
		path := config.DefaultPath()
		if len(rest) > 0 {
			path = rest[0]
		}
		if e := os.MkdirAll(filepath.Dir(path), 0700); e != nil {
			return fail(errOut, "E_CONFIG_WRITE", e, 1)
		}
		if _, e := os.Stat(path); e == nil {
			return fail(errOut, "E_EXISTS", fmt.Errorf("config already exists: %s", path), 1)
		}
		data := "# conventions configuration\n# Color mode: auto, always, or never. Default: auto.\ncolor = \"auto\"\n# Install profile. Default: neutral.\nprofile = \"neutral\"\n"
		if e := os.WriteFile(path, []byte(data), 0600); e != nil {
			return fail(errOut, "E_CONFIG_WRITE", e, 1)
		}
		fmt.Fprintf(errOut, "✓ created %s\n", path)
		return 0
	case "status":
		targets := installer.Status()
		if jsonOut {
			_ = json.NewEncoder(out).Encode(map[string]any{"targets": targets})
			return 0
		}
		rows := [][]string{}
		for _, t := range targets {
			rows = append(rows, []string{t.Harness, t.State, t.Path})
		}
		table(out, []string{"HARNESS", "STATE", "PATH"}, rows)
		return 0
	case "install", "uninstall":
		only := ""
		dryRun, yes := false, false
		for i := 0; i < len(rest); i++ {
			if rest[i] == "--only" && i+1 < len(rest) {
				i++
				only = rest[i]
			} else if rest[i] == "--dry-run" {
				dryRun = true
			} else if rest[i] == "--yes" || rest[i] == "-y" {
				yes = true
			}
		}
		selected, e := installer.ParseOnly(only)
		if e != nil {
			return fail(errOut, "E_USAGE", e, 2)
		}
		if cmd == "uninstall" && !dryRun && !yes && !confirmUninstall(errOut) {
			return fail(errOut, "E_CONFIRM_REQUIRED", errors.New("uninstall needs confirmation; rerun with --yes"), 2)
		}
		if e := installer.Apply(cmd == "uninstall", selected, dryRun); e != nil {
			return fail(errOut, "E_INSTALL", e, 1)
		}
		if dryRun {
			fmt.Fprintf(errOut, "==> dry run: no changes made\n")
		} else {
			fmt.Fprintf(errOut, "✓ %s complete\n", cmd)
		}
		return 0
	case "build":
		return fail(errOut, "E_NOT_IMPLEMENTED", errors.New("build generation is not yet ported from META/tools/build.sh"), 1)
	case "lint":
		root, sarif := ".", ""
		for i := 0; i < len(rest); i++ {
			if rest[i] == "--format" && i+1 < len(rest) && rest[i+1] == "sarif" {
				i++
				sarif = "-"
				if i+1 < len(rest) && !strings.HasPrefix(rest[i+1], "-") {
					i++
					sarif = rest[i]
				}
			} else if !strings.HasPrefix(rest[i], "-") {
				root = rest[i]
			}
		}
		report, lintErr := lint.Run(root)
		if lintErr != nil {
			return fail(errOut, "E_LINT", lintErr, 1)
		}
		if sarif != "" {
			b := lint.SARIF(report)
			if sarif == "-" {
				_, _ = out.Write(b)
			} else if e := os.WriteFile(sarif, b, 0644); e != nil {
				return fail(errOut, "E_IO", e, 1)
			}
		} else if jsonOut {
			_ = json.NewEncoder(out).Encode(report)
		} else {
			for _, f := range report.Findings {
				fmt.Fprintf(out, "%s:%d: %s: %s\n", f.File, f.Line, f.ID, f.Message)
			}
			fmt.Fprintf(errOut, "%d markdown files, %d finding(s)\n", report.Files, len(report.Findings))
		}
		if len(report.Findings) > 0 {
			return 1
		}
		return 0
	case "doctor":
		fmt.Fprintf(out, "version %s\nconfig %s\nos %s/%s\ntelemetry disabled\n", version, config.DefaultPath(), runtime.GOOS, runtime.GOARCH)
		return 0
	case "completion":
		if len(rest) != 1 {
			return fail(errOut, "E_USAGE", errors.New("completion requires zsh, bash, or fish"), 2)
		}
		s, e := completion(rest[0])
		if e != nil {
			return fail(errOut, "E_USAGE", e, 2)
		}
		fmt.Fprint(out, s)
		return 0
	case "explain":
		if len(rest) != 1 {
			return fail(errOut, "E_USAGE", errors.New("explain requires a rule id"), 2)
		}
		rules, _ := catalog.Find(".")
		for _, r := range rules {
			if r.ID == rest[0] {
				fmt.Fprintf(out, "# %s\n%s\n", r.Title, r.Body)
				return 0
			}
		}
		return fail(errOut, "E_NOT_FOUND", fmt.Errorf("rule id not found: %s", rest[0]), 1)
	case "match":
		if len(rest) == 0 {
			return fail(errOut, "E_USAGE", errors.New("match requires a task description"), 2)
		}
		task := rest[0]
		rules, _ := catalog.Find(".")
		matches, matchErr := matchRules(rules, task, rest[1:])
		if matchErr != nil {
			return fail(errOut, "E_MATCH_INPUT", matchErr, 1)
		}
		if jsonOut {
			_ = json.NewEncoder(out).Encode(matches)
		} else {
			for _, r := range matches {
				fmt.Fprintf(out, "%-38s %s\n", r.ID, r.Path)
			}
		}
		return 0
	case "add", "update":
		return fail(errOut, "E_NOT_IMPLEMENTED", fmt.Errorf("%s requires pack registry support", cmd), 1)
	case "tui":
		return runTUI(shouldDisableTUIColor(noColor, cfg.Color))
	default:
		fmt.Fprintf(errOut, "E_USAGE: unknown command %q (run conventions help)\n", cmd)
		return 2
	}
}
func fail(w io.Writer, id string, e error, code int) int {
	fmt.Fprintf(w, "✗ %s: %v\n", id, e)
	return code
}
func confirmUninstall(w io.Writer) bool {
	if !isTerminal(os.Stdin) {
		return false
	}
	fmt.Fprint(w, "!! Type uninstall to continue: ")
	line, err := bufio.NewReader(os.Stdin).ReadString('\n')
	return err == nil && strings.TrimSpace(line) == "uninstall"
}
func shouldDisableTUIColor(noColor bool, configColor string) bool {
	return noColor || os.Getenv("NO_COLOR") != "" || configColor == "never"
}
func has(a []string, s string) bool {
	for _, v := range a {
		if v == s {
			return true
		}
	}
	return false
}
func intersects(a, b string) bool {
	tokens := strings.FieldsFunc(a, func(r rune) bool { return !(r >= 'a' && r <= 'z' || r >= '0' && r <= '9') })
	for _, t := range tokens {
		if len(t) > 3 && strings.Contains(b, t) {
			return true
		}
	}
	return false
}
func matchRules(rules []catalog.Rule, task string, files []string) ([]catalog.Rule, error) {
	context := strings.ToLower(task)
	for _, path := range files {
		content, err := os.ReadFile(path)
		if err != nil {
			return nil, fmt.Errorf("read match input %s: %w", path, err)
		}
		context += " " + strings.ToLower(filepath.ToSlash(path)) + " " + strings.ToLower(string(content))
	}
	matches := []catalog.Rule{}
	for _, rule := range rules {
		needle := strings.ToLower(rule.Trigger + " " + rule.Title + " " + rule.ID + " " + rule.Path)
		if intersects(context, needle) {
			matches = append(matches, rule)
		}
	}
	return matches, nil
}
func help(w io.Writer) {
	fmt.Fprintf(w, "conventions — conventions manager\n\nCommands: %s\nGlobal flags: --json, --no-color, --config PATH\nConfig: ~/.config/conventions/config.toml (TOML); telemetry is disabled.\n", strings.Join(commandNames(), ", "))
}

var commandUsages = map[string]string{
	"init": "init [path]", "install": "install [--only HARNESS,...] [--dry-run]", "uninstall": "uninstall [--only HARNESS,...] [--dry-run] [--yes]",
	"status": "status", "lint": "lint [dir] [--format sarif [file]]", "build": "build [dir]",
	"add": "add <pack|git-url>", "update": "update", "doctor": "doctor", "explain": "explain <rule-id>",
	"match": "match <task> [files…]", "tui": "tui", "completion": "completion <zsh|bash|fish>", "version": "version [--json]",
}

func commandNames() []string {
	names := make([]string, 0, len(commandUsages))
	for name := range commandUsages {
		names = append(names, name)
	}
	sort.Strings(names)
	return names
}

func commandHelp(w io.Writer, command string, color bool) {
	if syntax, ok := commandUsages[command]; ok {
		name := "conventions " + command
		if color {
			fmt.Fprintf(w, "\033[38;2;31;138;138m%s\033[0m\n\nUsage: %s\n", name, syntax)
		} else {
			fmt.Fprintf(w, "%s\n\nUsage: %s\n", name, syntax)
		}
		fmt.Fprintln(w, "Global flags: --json, --no-color, --config PATH")
		return
	}
	help(w)
}
func isTerminal(w io.Writer) bool {
	f, ok := w.(*os.File)
	if !ok {
		return false
	}
	info, err := f.Stat()
	return err == nil && info.Mode()&os.ModeCharDevice != 0
}
func completion(shell string) (string, error) {
	cmds := strings.Join(commandNames(), " ")
	switch shell {
	case "bash":
		return "_conventions() { COMPREPLY=( $(compgen -W '" + cmds + "' -- \"${COMP_WORDS[COMP_CWORD]}\") ); }\ncomplete -F _conventions conventions\n", nil
	case "zsh":
		return "#compdef conventions\n_arguments '1:command:(" + cmds + ")' '*::arg:->args'\n", nil
	case "fish":
		out := ""
		for _, c := range strings.Fields(cmds) {
			out += "complete -c conventions -f -a '" + c + "'\n"
		}
		return out, nil
	}
	return "", fmt.Errorf("unsupported shell %q", shell)
}
func table(w io.Writer, head []string, rows [][]string) {
	width := make([]int, len(head))
	for i, v := range head {
		width[i] = len(v)
	}
	for _, r := range rows {
		for i, v := range r {
			if i < len(width) && len(v) > width[i] {
				width[i] = len(v)
			}
		}
	}
	fmt.Fprintln(w, strings.Join(pad(head, width), "  "))
	for _, r := range rows {
		fmt.Fprintln(w, strings.Join(pad(r, width), "  "))
	}
}
func pad(a []string, w []int) []string {
	b := []string{}
	for i, v := range a {
		b = append(b, fmt.Sprintf("%-*s", w[i], v))
	}
	return b
}
