# Asset Source / Loader / Hot-Reload (Native) - 2026-03-06

## Scope
- `mgstudio-engine/asset/*`
- `mgstudio-engine/runtime_native/native_asset/*`

## Implemented
1. `source://` path semantics
- Added `asset_parse_path` / `asset_strip_label` in asset API layer.
- Native asset resolver now parses source prefix and label, then resolves to:
  - default source root: `MGSTUDIO_ASSETS_DIR` (fallback `./assets`)
  - named source root: `MGSTUDIO_ASSET_SOURCE_<SOURCE>_DIR` (fallback `./assets/<source>`)

2. Loader extension registry
- Added runtime registry APIs:
  - `asset_register_loader_extension`
  - `asset_remove_loader_extension`
  - `asset_loader_kind_for_path`
- Added native dispatch API:
  - `load_with_registered_loader(path, nearest)`
- Default extension mapping includes texture, wgsl, and font types.

3. Folder watcher-driven hot reload
- Native folder records now keep per-file fingerprints.
- `poll_loaded_folder_event_kind` triggers folder refresh scan.
- On folder content delta, emits `Modified` event (`kind=1`) and refreshes loaded handles.

## Validation
- Added tests in `asset/asset_path_loader_test.mbt` for:
  - `source://` + label parsing
  - loader extension registry override behavior

## Notes
- This is a native-first implementation aligned with current native-only direction.
- Event granularity is folder-level (`LoadedFolder` modified), consistent with existing folder event model.
