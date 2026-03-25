# Animation Example Parity (vs `bevy/examples/animation`)

This folder tracks parity status for Bevy animation examples.

## Status Matrix

| Bevy Example | mgstudio Example | Status | Notes |
|---|---|---|---|
| `animated_mesh.rs` | `examples/animation/animated_mesh` | Partial | Scene-root animation player wiring, graph insertion, and Fox playback flow now compile and smoke-run; skeletal parity still depends on the simplified local scene runtime rather than full Bevy descendant-player behavior. |
| `animated_mesh_control.rs` | `examples/animation/animated_mesh_control` | Partial | Keyboard transition / seek / repeat flow is implemented on the root animation player; full parity still depends on the same simplified Fox scene runtime. |
| `animated_mesh_events.rs` | N/A | Blocked | Same skinned playback blocker as `animated_mesh`, plus no Bevy-style typed animation event observer flow. |
| `animated_transform.rs` | `examples/animation/animated_transform` | Done | Runtime clip / graph / player / target flow is implemented and native-checkable. |
| `animated_ui.rs` | N/A | Blocked | Requires UI animatable-property pipeline integrated with animation clip/graph/player. |
| `animation_events.rs` | N/A | Blocked | Timeline events exist, but the Bevy example depends on typed animation-event observers rather than string/callback clip hooks. |
| `animation_graph.rs` | N/A | Blocked | Blend graph runtime exists, but this example still depends on the skinned Fox playback path and Bevy-style graph UI interaction flow. |
| `animation_masks.rs` | N/A | Blocked | Mask groups exist in the graph runtime, but the example still depends on skinned Fox playback and per-mask UI controls. |
| `color_animation.rs` | `examples/animation/color_animation` | Partial | Runtime behavior is close, but not API-identical to Bevy color curve/mix stack. |
| `custom_skinned_mesh.rs` | N/A | Blocked | Requires joint/weight vertex channels + skinning runtime/bounds updates. |
| `eased_motion.rs` | `examples/animation/eased_motion` | Partial | Easing / curve reparameterization is implemented, but clip authoring still samples curves into keyframes instead of exposing Bevy-style direct curve-to-field clip APIs. |
| `easing_functions.rs` | `examples/animation/easing_functions` | Done | Grid/curve/progress behavior is implemented and compile-checked. |
| `morph_targets.rs` | N/A | Blocked | Requires morph target import/runtime + animation player integration + asset events parity. |

## Core Missing Runtime Modules (Consolidated)

1. Skinning runtime:
   - Mesh channels for joints/weights.
   - CPU/GPU skinning path and bone matrix upload.
2. Morph target runtime:
   - Mesh morph target buffers/names/weights.
   - Per-frame morph weight evaluation from animation data.
3. Typed animation event observer model:
   - Equivalent to Bevy `AnimationEvent` derive + `On<T>` trigger flow.
4. Direct curve-to-field clip authoring:
   - Equivalent to Bevy `AnimatableCurve` / `animated_field!` flow without sampling through keyframes in the example.
5. Color curve/mix parity primitives:
   - Built-in curve/mix abstractions for `LinearRgba/Oklaba/Xyza/Oklcha` style workflows.
6. 2D sprite parity gap:
   - Pure color-only sized sprite without mandatory texture handle.

## Validation

Implemented examples in this folder are checked with:

- `moon check --target native --deny-warn --package-path examples/animation/animated_transform`
- `moon check --target native --deny-warn --package-path examples/animation/eased_motion`
- `moon check --target native --deny-warn --package-path examples/animation/easing_functions`
- `moon check --target native --deny-warn --package-path examples/animation/color_animation`
