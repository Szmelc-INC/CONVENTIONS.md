# Migration from v2 to v3

Version 3 makes the conventions usable without adopting one maintainer's personal settings. The default profile is `neutral`; the former Szmelc settings are available with `--profile szmelc`.

## What changed

- Rule files now carry stable `id` values. Use those IDs in overrides instead of file paths.
- The source tree has six neutral cores. Szmelc-only documentation and repository discovery live under `PROFILES/szmelc/`.
- `META/tools/build.sh` defaults to the neutral profile. Render another profile with `META/tools/build.sh --profile szmelc`.
- Overlay order is neutral core, selected organization profile, team, project, then user. An overlay can disable rules by ID and set profile values; see [`CONVENTIONS/PROFILES/OVERLAYS.md`](CONVENTIONS/PROFILES/OVERLAYS.md).
- The installer defaults to the neutral profile and preserves existing global instruction files by replacing only its `conventions` marked block. `--replace` opts into symlink replacement. `uninstall` removes only managed blocks.
- The global skill is now named `conventions`. The installer keeps the previous `szmelc-conventions` link as a compatibility alias for this major version.

## Upgrade

1. Back up local changes to the repository checkout before updating it.
2. Update the checkout to v3 and run `./install.sh --profile neutral` (or `./install.sh --profile szmelc` to retain the previous settings).
3. Run `./install.sh status` and review the managed block in each detected harness file.
4. To remove the integration, run `./install.sh uninstall`; it removes the managed block and leaves surrounding user content intact.

Existing v2 symlinks are not rewritten in place by default. The installer reports the current destinations; choose `--replace` only when you want the installer to replace those files, with its normal backup behavior.

## Rollback

Restore the prior checkout or release, then run its installer. For any file previously replaced with `--replace`, restore the timestamped backup created by that installer. The v3 managed-block path does not alter text outside its markers.
