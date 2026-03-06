# Animation Example Parity (vs `bevy/examples/animation`)

This folder tracks parity status for Bevy animation examples.

## Status Matrix

| Bevy Example | mgstudio Example | Status | Notes |
|---|---|---|---|
| `animated_mesh.rs` | N/A | Blocked | Requires skeletal animation pipeline + `GltfAssetLabel::Animation` + `AnimationPlayer/AnimationGraph`. |
| `animated_mesh_control.rs` | N/A | Blocked | Same blockers as `animated_mesh`, plus transition/repeat APIs. |
| `animated_mesh_events.rs` | N/A | Blocked | Same blockers as `animated_mesh`, plus animation timeline events / observer trigger model. |
| `animated_transform.rs` | N/A | Blocked | Requires generic clip/graph/player/target animation framework. |
| `animated_ui.rs` | N/A | Blocked | Requires UI animatable-property pipeline integrated with animation clip/graph/player. |
| `animation_events.rs` | N/A | Blocked | Requires animation event timeline (`clip.add_event`) and observer semantics. |
| `animation_graph.rs` | N/A | Blocked | Requires graph asset/runtime with blend nodes and runtime weight control. |
| `animation_masks.rs` | N/A | Blocked | Requires animation mask groups and target-group assignment in graph runtime. |
| `color_animation.rs` | `examples/animation/color_animation` | Partial | Runtime behavior is close, but not API-identical to Bevy color curve/mix stack. |
| `custom_skinned_mesh.rs` | N/A | Blocked | Requires joint/weight vertex channels + skinning runtime/bounds updates. |
| `eased_motion.rs` | N/A | Blocked | Requires clip/graph/player + easing-curve/reparametrize/ping-pong APIs. |
| `easing_functions.rs` | `examples/animation/easing_functions` | Done | Grid/curve/progress behavior is implemented and compile-checked. |
| `morph_targets.rs` | N/A | Blocked | Requires morph target import/runtime + animation player integration + asset events parity. |

## Core Missing Runtime Modules (Consolidated)

1. Generic animation framework:
   - `AnimationClip`, `AnimationGraph`, `AnimationPlayer`, `AnimationTransitions`.
   - Animation targets (`AnimationTargetId`, target path binding, `AnimatedBy`).
2. glTF animation pipeline:
   - `GltfAssetLabel::Animation(Int)`.
   - glTF parsing for `skins`, `animations`, channels/samplers.
3. Skinning runtime:
   - Mesh channels for joints/weights.
   - CPU/GPU skinning path and bone matrix upload.
4. Morph target runtime:
   - Mesh morph target buffers/names/weights.
   - Per-frame morph weight evaluation from animation data.
5. Animation events and observer model:
   - Timeline event emission from clip playback.
   - Equivalent to Bevy `On<T>` observer trigger flow.
6. Animation graph masks/blending:
   - Mask group assignment and weighted clip blending.
7. Color curve/mix parity primitives:
   - Built-in curve/mix abstractions for `LinearRgba/Oklaba/Xyza/Oklcha` style workflows.
8. 2D sprite parity gap:
   - Pure color-only sized sprite without mandatory texture handle.

## Validation

Implemented examples in this folder are checked with:

- `moon check --target native --deny-warn --package-path examples/animation/easing_functions`
- `moon check --target native --deny-warn --package-path examples/animation/color_animation`
