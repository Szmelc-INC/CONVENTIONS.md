# Site screenshots
Screenshots of the live site (<https://szmelc-inc.github.io/CONVENTIONS.md/>) shown in the root `README.md`.

- Made by `META/tools/screenshots.sh`: builds the site with `META/tools/site.sh`, serves it on localhost, captures it with headless Chromium over CDP (Node >= 22) and optimizes the PNGs.
- Files: `hero-dark.png`, `menu.png`, `projects.png`, `popup-about.png`, `light.png` (1280×900), `mobile.png` (390×844 at 2×).
- Never edit by hand; rerun the script after visible site changes and commit the result.
