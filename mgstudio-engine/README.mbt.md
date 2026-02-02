# Milky2018/mgstudio

`mgstudio-engine` is a small Bevy-inspired runtime core implemented in MoonBit.

## Text2d pipeline (engine-led)

Text rendering is implemented in the guest (engine) and only relies on the host
runtime for I/O and GPU texture updates:

- Shaping / line-breaking / BiDi: `Milky2018/moon_cosmic`
- Glyph rasterization: `Milky2018/moon_swash`
- Font bytes: host provides `asset_load_font` + `asset_font_bytes_*` (read-only)
- Glyph atlas upload: host provides `asset_create_dynamic_texture` and
  `asset_update_texture_region_bytes`

The legacy host APIs `font_rasterize_glyph` / `font_measure_advance` are kept
only for backwards-compatibility and are not used by the current engine text
pipeline.
