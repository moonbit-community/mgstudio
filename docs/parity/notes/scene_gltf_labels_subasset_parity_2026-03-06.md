# glTF Label Sub-Asset Parity (2026-03-06)

## Scope
- Package: `mgstudio-engine/scene`
- Task: `moon-game-studio-t8o.11`
- Goal: align glTF label model and labeled-path parsing behavior with Bevy `bevy_gltf::GltfAssetLabel` semantics beyond `Scene` and `Animation`.

## Bevy Reference
- `bevy/crates/bevy_gltf/src/label.rs`

## Implemented
- Expanded `GltfAssetLabel` variants in `scene/scene.mbt`:
  - `Node`, `Mesh`, `Primitive`, `MorphTarget`, `Texture`, `Material`, `DefaultMaterial`, `Skin`, `InverseBindMatrices`
  - Existing: `Scene`, `Animation`
- Added Bevy-style label formatting API:
  - `GltfAssetLabel::to_label()`
  - `GltfAssetLabel::from_asset()` now delegates to `to_label()`
- Added Bevy-style label parser:
  - `GltfAssetLabel::parse(label : String) -> GltfAssetLabel?`
- Added labeled path split helper:
  - `gltf_split_asset_path_with_label(asset_path : String) -> (String, GltfAssetLabel?)`
- Updated glTF loader request routing to use parsed labels from the generic split helper:
  - scene request selects `Scene(index)` or falls back to `0`
  - animation request selects `Animation(index)` or falls back to `0`

## Tests Added/Updated
- `scene/scene_test.mbt`
  - extended label encoding coverage for new variants
  - parser + labeled-path split coverage
- `scene/gltf_loader_wbtest.mbt`
  - split-path behavior with extended labels and unknown labels

## Follow-up Tasks
- Loader-side direct retrieval for additional label targets (`Node`, `Mesh`, `Primitive`, `Texture`, etc.) is not yet exposed as dedicated scene APIs.
- Material label currently tracks Bevy label text parity (`Material{n}` / `Material{n} (inverted)`), while full inverted-scale material routing still depends on broader loader/material pipeline alignment work.
