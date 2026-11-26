---
id: conventions.interfaces.webui.routing
---
# Web UI routing
> Load when: adding views, deep links or URL handling to a web UI.

- The URL hash is the router: `#<view>`, `#<item-path>`, `#<group>/`. `hashchange` calls `route()`, `route()` sets state, then calls `render()`.
- Every view, group and item has a deep link. Loading it restores the view, opens the item and scrolls it below the sticky bar (`scroll-margin-top`).
- Unknown hash: show the first view. No error page.
- Old hashes keep working: `route()` maps retired ids to their new target.
- Overlay routes are transient (`#install`, `#about`, `#<kind>/<id>`): set them with `history.replaceState`, render the view under the overlay, restore the previous hash on close.
- A content link inside an overlay closes the overlay and moves focus to the target, not to the opener.
- Filter text and toggles stay out of the hash. A deep link clears the filter.
- The hash carries routes only. A skip link moves focus without changing the hash.
- Query parameters only for view options that are not saved (`?theme=`).
