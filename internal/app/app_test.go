package app

import (
	"bytes"
	"strings"
	"testing"
)

func TestVersionJSONAndUsageExit(t *testing.T) {
	var out, errOut bytes.Buffer
	if code := Run([]string{"version", "--json"}, &out, &errOut); code != 0 || !strings.Contains(out.String(), `"version"`) {
		t.Fatalf("version: code=%d out=%q err=%q", code, out.String(), errOut.String())
	}
	out.Reset()
	errOut.Reset()
	if code := Run([]string{"nonesuch"}, &out, &errOut); code != 2 || !strings.Contains(errOut.String(), "E_USAGE") {
		t.Fatalf("usage: code=%d err=%q", code, errOut.String())
	}
}

func TestCompletionShells(t *testing.T) {
	for _, shell := range []string{"zsh", "bash", "fish"} {
		if got, err := completion(shell); err != nil || !strings.Contains(got, "conventions") {
			t.Fatalf("%s completion: %q, %v", shell, got, err)
		}
	}
}
