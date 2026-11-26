---
id: conventions.interfaces.webui.architecture
---
# Web UI architecture
> Load when: building a web UI, docs site or Pages site from scratch, or restructuring its build or page code.

Reference implementation: `META/tools/site.sh`. Visual rules: `CONVENTIONS/INTERFACES/WEBUI/THEME.md` and `CONVENTIONS/INTERFACES/WEBUI/LAYOUT.md`. Components and accessibility: `CONVENTIONS/INTERFACES/WEBUI/COMPONENTS.md` and `CONVENTIONS/INTERFACES/WEBUI/ACCESSIBILITY.md`. Starter: `TEMPLATES/webui.html`.

- One self-contained `index.html`: markup, CSS and JS inline. No framework, no bundler, no runtime build step.
- A build script collects every source into one data object and writes it into the page as `<script type="application/json" id="data">`, with `<` escaped as `<`.
- Build-time values reach the page only through that data block. Never interpolate them into HTML or JS (quote the heredocs).
- The page works offline and over `file://`. Content never depends on a runtime request.
- Live data (stars, latest release) is optional: show the build-time value, fetch once, keep the value on any failure. No retries, no spinners.
- A small inline `<head>` script sets the theme before first paint.
- State is a few top-level variables (view, filter, open item). One `render()` rebuilds the view from state and data. Handlers change state, then call `render()` or set the hash.
- Escape every data string before it enters HTML (`esc()`). Render Markdown with a small local renderer.
- No tracking, analytics or cookies; external JS only when unavoidable, from a CDN URL pinned to an exact version with `integrity`.
- One sprite of inline SVG icons, defined once and used with `<use>`.
- Output goes to a gitignored directory (`public/`) and CI deploys it (`CONVENTIONS/GITHUB/DEPLOYMENTS/GITHUB-PAGES.md`). Never commit it.
- Verify: build, open over `file://` and over HTTP, try each deep link and each key, check 360px width and every theme.
