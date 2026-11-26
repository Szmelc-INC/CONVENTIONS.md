package build

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCoreMapsMatchTrackedArtifacts(t *testing.T) {
	root := filepath.Join("..", "..")
	got, err := CoreMaps(root)
	if err != nil {
		t.Fatal(err)
	}
	for name, data := range got {
		want, err := os.ReadFile(filepath.Join(root, name))
		if err != nil {
			t.Fatal(err)
		}
		if string(data) != string(want) {
			i := 0
			for i < len(data) && i < len(want) && data[i] == want[i] {
				i++
			}
			t.Errorf("%s differs at byte %d: got %q want %q", name, i, data[max(0, i-24):min(len(data), i+60)], want[max(0, i-24):min(len(want), i+60)])
		}
	}
}
