# Gizmos Example Parity (vs `bevy/examples/gizmos`)

This folder tracks parity status for Bevy gizmo examples.

## Status Matrix

| Bevy Example | mgstudio Example | Status | Notes |
| --- | --- | --- | --- |
| `2d_gizmos.rs` | `examples/gizmos/2d_gizmos` | Done | 2D line, strip, primitive, curve, and grid gizmos are implemented on the standard gizmo runtime. |
| `2d_text_gizmos.rs` | `examples/gizmos/2d_text_gizmos` | Done | 2D gizmo text is implemented with the simplex stroke-font path. |
| `3d_gizmos.rs` | `examples/gizmos/3d_gizmos` | Done | 3D lines, strips, arrows, axes, and primitives render through the PBR scene path. |
| `3d_text_gizmos.rs` | `examples/gizmos/3d_text_gizmos` | Done | 3D gizmo text is implemented and rendered with the standard 3D gizmo queue. |
| `anchored_text_gizmos.rs` | `examples/gizmos/anchored_text_gizmos` | Done | Anchored text placement is supported through the shared stroke-text runtime. |
| `axes.rs` | `examples/gizmos/axes` | Done | 3D axis helpers and transform visualization are implemented on the public gizmo API. |
| `light_gizmos.rs` | `examples/gizmos/light_gizmos` | Done | Light gizmo drawing and config-group wiring are implemented through the light runtime helpers. |
| `text_gizmos_font.rs` | `examples/gizmos/text_gizmos_font` | Done | Custom stroke-font selection for gizmo text is implemented. |

## Runtime Coverage

- `Gizmos[T]` supports both 2D and 3D drawing through one public surface.
- Text gizmos are available as `text_2d(...)` and `text_3d(...)`.
- Config groups are supported through `GizmoConfigGroup`, `GizmoConfigStore`, and `init_gizmo_group(...)`.
- Light gizmos are implemented as runtime systems, not example-local helpers.

## Validation

Implemented examples in this folder are validated with:

- `moon test gizmos --target native`
- `moon test sprite --target native`
- `moon test pbr --target native`
- `moon check --target native`
