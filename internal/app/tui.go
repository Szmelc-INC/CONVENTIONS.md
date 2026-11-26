package app

import (
	"fmt"
	"os"
	"strings"

	"github.com/Szmelc-INC/CONVENTIONS.md/internal/catalog"
	"github.com/Szmelc-INC/CONVENTIONS.md/internal/installer"
	"github.com/Szmelc-INC/CONVENTIONS.md/internal/lint"
	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/glamour"
	"github.com/charmbracelet/lipgloss"
)

type docItem struct{ catalog.Rule }

func (d docItem) Title() string       { return d.ID + "  " + d.Rule.Title }
func (d docItem) Description() string { return d.Rule.Path }
func (d docItem) FilterValue() string {
	return d.Title() + " " + d.Description() + " " + d.Rule.Trigger
}

type tuiModel struct {
	items         []catalog.Rule
	list          list.Model
	detail        viewport.Model
	input         textinput.Model
	tab           int
	help, palette bool
	width, height int
	renderer      *glamour.TermRenderer
	message       string
}

var tabs = []string{"CONVENTIONS", "AGENTS", "HUMANS", "CONTRIBUTING", "TEMPLATES"}
var accent = lipgloss.NewStyle().Foreground(lipgloss.Color("#1f8a8a"))
var subdued = lipgloss.NewStyle().Foreground(lipgloss.Color("#c0c0c0"))

func runTUI() int {
	items, _ := catalog.Find(".")
	renderer, _ := glamour.NewTermRenderer(glamour.WithAutoStyle())
	l := list.New([]list.Item{}, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Conventions"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	input := textinput.New()
	input.Prompt = ":"
	input.Placeholder = "help, install, status, lint, open <rule-id>, tab <core>, quit"
	m := tuiModel{items: items, list: l, detail: viewport.New(0, 0), input: input, renderer: renderer}
	m.refresh()
	if _, e := tea.NewProgram(m, tea.WithAltScreen()).Run(); e != nil {
		fmt.Fprintln(os.Stderr, "E_TUI:", e)
		return 1
	}
	return 0
}
func (m *tuiModel) refresh() {
	subset := []list.Item{}
	for _, r := range m.items {
		if r.Path == tabs[m.tab] || strings.HasPrefix(r.Path, tabs[m.tab]+"/") {
			subset = append(subset, docItem{r})
		}
	}
	m.list.SetItems(subset)
}
func (m tuiModel) Init() tea.Cmd { return nil }
func (m tuiModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.list.SetSize(msg.Width/2, msg.Height-5)
		m.detail.Width = msg.Width/2 - 2
		m.detail.Height = msg.Height - 7
	case tea.KeyMsg:
		if m.palette {
			switch msg.String() {
			case "esc":
				m.palette = false
				m.input.Blur()
				return m, nil
			case "enter":
				return m, m.executeCommand(strings.TrimSpace(m.input.Value()))
			default:
				var c tea.Cmd
				m.input, c = m.input.Update(msg)
				return m, c
			}
		}
		if m.help {
			if key.Matches(msg, key.NewBinding(key.WithKeys("?", "f1", "esc"))) {
				m.help = false
			}
			return m, nil
		}
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case ":":
			m.palette = true
			m.input.SetValue("")
			m.input.Focus()
			return m, textinput.Blink
		case "?", "f1":
			m.help = true
			return m, nil
		case "tab", "right":
			m.tab = (m.tab + 1) % len(tabs)
			m.refresh()
			return m, nil
		case "left":
			m.tab = (m.tab + len(tabs) - 1) % len(tabs)
			m.refresh()
			return m, nil
		case "enter":
			if it, ok := m.list.SelectedItem().(docItem); ok && m.renderer != nil {
				rendered, e := m.renderer.Render(it.Body)
				if e == nil {
					m.detail.SetContent(rendered)
				}
			}
			return m, nil
		}
	}
	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	m.detail, _ = m.detail.Update(msg)
	return m, cmd
}
func (m *tuiModel) executeCommand(command string) tea.Cmd {
	parts := strings.Fields(command)
	if len(parts) == 0 {
		m.palette = false
		return nil
	}
	switch parts[0] {
	case "quit", "q":
		return tea.Quit
	case "help", "?":
		m.help = true
	case "tab":
		if len(parts) > 1 {
			for i, t := range tabs {
				if strings.EqualFold(t, parts[1]) {
					m.tab = i
					m.refresh()
				}
			}
		}
	case "open":
		if len(parts) > 1 {
			for _, r := range m.items {
				if r.ID == parts[1] {
					if b, e := m.renderer.Render(r.Body); e == nil {
						m.detail.SetContent(b)
					}
					break
				}
			}
		}
	case "status":
		found := 0
		for _, target := range installer.Status() {
			if target.State == "detected" || target.State == "linked" {
				found++
			}
		}
		m.message = fmt.Sprintf("%d detected harness home(s).", found)
	case "install":
		if err := installer.Apply(false, nil); err != nil {
			m.message = "Install failed: " + err.Error()
		} else {
			m.message = "Install links created for detected harnesses."
		}
	case "lint":
		report := lint.Run(".")
		m.message = fmt.Sprintf("Lint checked %d Markdown files and found %d issue(s).", report.Files, len(report.Findings))
	default:
		m.message = "Unknown command: " + parts[0]
	}
	m.palette = false
	m.input.Blur()
	return nil
}
func (m tuiModel) View() string {
	if m.help {
		return accent.Render("Help") + "\n\n↑/↓ or j/k move · enter open Markdown · tab/right and left change section · : command palette · ?/F1 close help · q quit\n\nCommands: help, status, install, lint, tab <section>, open <rule-id>, quit\n"
	}
	header := accent.Render("conventions") + "  " + strings.Join(tabs, "  ") + "\n" + subdued.Render("←/→ sections · ↑/↓ browse · enter render · : commands · ? help · q quit") + "\n"
	body := lipgloss.JoinHorizontal(lipgloss.Top, m.list.View(), m.detail.View())
	if m.palette {
		return header + body + "\n" + m.input.View()
	}
	if m.message != "" {
		header += m.message + "\n"
	}
	return header + body
}
