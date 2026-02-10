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

## Physics2d hooks

`physics2d` exposes Rapier hooks in a Bevy-like split:

- Global callback config (`Physics2dHooksConfig`) for hook functions.
- Per-collider opt-in (`ActiveHooks2d`) to enable hook categories.

Example:

```mbt
let cfg = @physics2d.physics2d_hooks_config()
@physics2d.physics2d_hooks_set_config(
  @physics2d.Physics2dHooksConfig::{
    ..cfg,
    filter_contact_pair: Some(fn(_bodies, _colliders, h1, h2) {
      let e1 = @physics2d.physics2d_hook_entity_from_collider_handle(h1)
      let e2 = @physics2d.physics2d_hook_entity_from_collider_handle(h2)
      // Return false to ignore this contact pair.
      !(e1 is Some(_) && e2 is Some(_))
    }),
  },
)

Has_ActiveHooks2d::get_active_hooks2d_store(world).insert(
  collider_entity,
  @physics2d.ActiveHooks2d::new(@collision.ActiveHooks::filter_contact_pairs()),
  tick,
)
```

Note: mgstudio reserves Rapier collider `user_data` for ECS ownership identity.
Do not overwrite it in gameplay code. Hook code should resolve entities via
`physics2d_hook_entity_from_collider_handle(...)`.
