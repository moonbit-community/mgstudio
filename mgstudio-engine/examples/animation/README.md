# Animation Example Parity (vs `bevy/examples/animation`)

This folder tracks parity status for Bevy animation examples.

## Status Matrix

| Bevy Example | mgstudio Example | Status | Notes |
|---|---|---|---|
| `animated_mesh.rs` | `examples/animation/animated_mesh` | Done | Scene-root animation player wiring, graph insertion, and Fox playback now run on the shared scene/skinning runtime. |
| `animated_mesh_control.rs` | `examples/animation/animated_mesh_control` | Done | Keyboard transition / seek / repeat flow works on the shared Fox scene runtime with the same root-player model used by the engine examples. |
| `animated_mesh_events.rs` | `examples/animation/animated_mesh_events` | Done | Typed animation events are now routed through the observer path and the example reacts on the animated Fox scene. |
| `animated_transform.rs` | `examples/animation/animated_transform` | Done | Runtime clip / graph / player / target flow is implemented and native-checkable. |
| `animated_ui.rs` | `examples/animation/animated_ui` | Done | UI text scale and `TextColor` are driven by the standard animation runtime using the current MoonBit-form target surface. |
| `animation_events.rs` | `examples/animation/animation_events` | Done | Typed clip events now drive the example through the public typed animation event surface. |
| `animation_graph.rs` | `examples/animation/animation_graph` | Done | Blend graph runtime and interaction flow are implemented on the current graph/player model. |
| `animation_masks.rs` | `examples/animation/animation_masks` | Done | Mask-group UI flow and graph mask toggling now run on the shared Fox scene/skinning path. |
| `color_animation.rs` | `examples/animation/color_animation` | Done | Bevy-style split between curve-based and mix-based color animation is now implemented with dedicated ECS components and typed query systems. |
| `custom_skinned_mesh.rs` | `examples/animation/custom_skinned_mesh` | Done | Manual meshes can now provide joint indices/weights and run through the same CPU skinning runtime as imported glTF scenes. |
| `eased_motion.rs` | `examples/animation/eased_motion` | Done | Curve-to-target authoring is available through `AnimationClip::add_curve_to_target(...)`, and the example now uses that path directly. |
| `easing_functions.rs` | `examples/animation/easing_functions` | Done | Grid/curve/progress behavior is implemented and compile-checked. |
| `morph_targets.rs` | `examples/animation/morph_targets` | Done | Morph target import, naming, animation playback, and mesh asset event observation are implemented on the current glTF runtime. |

## Core Missing Runtime Modules (Consolidated)

1. General UI property animation parity:
   - Broader UI property targeting beyond the current `Transform` + `TextColor` coverage.

## Validation

Implemented examples in this folder are checked with:

- `moon check --target native --deny-warn --package-path examples/animation/animated_mesh`
- `moon check --target native --deny-warn --package-path examples/animation/animated_mesh_control`
- `moon check --target native --deny-warn --package-path examples/animation/animated_mesh_events`
- `moon check --target native --deny-warn --package-path examples/animation/animated_transform`
- `moon check --target native --deny-warn --package-path examples/animation/animated_ui`
- `moon check --target native --deny-warn --package-path examples/animation/animation_events`
- `moon check --target native --deny-warn --package-path examples/animation/animation_graph`
- `moon check --target native --deny-warn --package-path examples/animation/eased_motion`
- `moon check --target native --deny-warn --package-path examples/animation/easing_functions`
- `moon check --target native --deny-warn --package-path examples/animation/color_animation`
- `moon check --target native --deny-warn --package-path examples/animation/animation_masks`
- `moon check --target native --deny-warn --package-path examples/animation/custom_skinned_mesh`
- `moon check --target native --deny-warn --package-path examples/animation/morph_targets`
