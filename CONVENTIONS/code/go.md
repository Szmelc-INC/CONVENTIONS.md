# Go
> Load when: writing, building or releasing Go code.

- Current stable Go; `CGO_ENABLED=0`, one static binary.
- Cross-compile for linux, darwin, windows and freebsd unless the tool is Linux-only by nature.
- SQLite via `modernc.org/sqlite` (no cgo); WAL mode.
- Static web assets ship inside the binary with `embed`.
- Layout: one `main` package or `cmd/<bin>`, private code in `internal/`, tests next to the code.
- `gofmt` and `go vet` clean; every error handled or returned with context.
- Stdlib first; the Charm stack (`CONVENTIONS/interfaces/tui.md`) is the default exception.
