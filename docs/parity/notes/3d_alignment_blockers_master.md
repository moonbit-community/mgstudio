# 3D Alignment Blockers Master

- Updated: 2026-02-28
- Verification sources:
  - `docs/parity/bevy_example_parity.csv` regenerated via `../mgstudio-dev gen` from `mgstudio-engine`.
  - Full 3D smoke sweep on 2026-02-28 with:
    - `for pkg in $(find examples/3d -mindepth 1 -maxdepth 1 -type d | sort); do moon check -p "$pkg"; done`
- Scope: Bevy `examples/3d` parity tracking only. This file now records verified current status and avoids speculative root-cause categorization.

## Verified Snapshot

| Metric | Value | Evidence |
| --- | ---: | --- |
| Bevy 3D examples tracked in parity CSV | 66 | `docs/parity/bevy_example_parity.csv` category=`3d` |
| `Exact` | 28 | parity CSV status counts |
| `Blocked` | 38 | parity CSV status counts |
| 3D smoke packages checked | 68 | `examples/3d/*` package directories |
| Smoke check pass/fail | 68 pass / 0 fail | Per-package `moon check -p <pkg>` run |

## Still Blocked for Exact Parity (Verified)

Common parity note in CSV for all rows below: `Fallback implementation exists; blocked until exact parity.`

| Bevy 3D Example | Owner | Parity Status | Smoke Check |
| --- | --- | --- | --- |
| `anti_aliasing` | `team-render` | `Blocked` | `pass` |
| `atmosphere` | `team-render` | `Blocked` | `pass` |
| `atmospheric_fog` | `team-render` | `Blocked` | `pass` |
| `auto_exposure` | `team-render` | `Blocked` | `pass` |
| `bloom_3d` | `team-render` | `Blocked` | `pass` |
| `clustered_decal_maps` | `team-render` | `Blocked` | `pass` |
| `clustered_decals` | `team-render` | `Blocked` | `pass` |
| `color_grading` | `team-render` | `Blocked` | `pass` |
| `contact_shadows` | `team-render` | `Blocked` | `pass` |
| `decal` | `team-render` | `Blocked` | `pass` |
| `deferred_rendering` | `team-render` | `Blocked` | `pass` |
| `depth_of_field` | `team-render` | `Blocked` | `pass` |
| `fog_volumes` | `team-render` | `Blocked` | `pass` |
| `fog` | `team-render` | `Blocked` | `pass` |
| `irradiance_volumes` | `team-render` | `Blocked` | `pass` |
| `light_probe_blending` | `team-render` | `Blocked` | `pass` |
| `light_textures` | `team-render` | `Blocked` | `pass` |
| `lightmaps` | `team-render` | `Blocked` | `pass` |
| `mesh_ray_cast` | `team-render` | `Blocked` | `pass` |
| `meshlet` | `team-render` | `Blocked` | `pass` |
| `mixed_lighting` | `team-render` | `Blocked` | `pass` |
| `motion_blur` | `team-render` | `Blocked` | `pass` |
| `occlusion_culling` | `team-render` | `Blocked` | `pass` |
| `order_independent_transparency` | `team-render` | `Blocked` | `pass` |
| `pccm` | `team-render` | `Blocked` | `pass` |
| `pcss` | `team-render` | `Blocked` | `pass` |
| `post_processing` | `team-render` | `Blocked` | `pass` |
| `reflection_probes` | `team-render` | `Blocked` | `pass` |
| `scrolling_fog` | `team-render` | `Blocked` | `pass` |
| `shadow_biases` | `team-render` | `Blocked` | `pass` |
| `solari` | `team-render` | `Blocked` | `pass` |
| `spherical_area_lights` | `team-render` | `Blocked` | `pass` |
| `split_screen` | `team-render` | `Blocked` | `pass` |
| `ssao` | `team-render` | `Blocked` | `pass` |
| `ssr` | `team-render` | `Blocked` | `pass` |
| `tonemapping` | `team-render` | `Blocked` | `pass` |
| `transmission` | `team-render` | `Blocked` | `pass` |
| `volumetric_fog` | `team-render` | `Blocked` | `pass` |
