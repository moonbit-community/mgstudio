// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Bevy-aligned render module anchor.

///|
// Bevy source:
// - `bevy/crates/bevy_pbr/src/render/morph.rs` (`MorphIndices`, `MorphUniforms`).
pub struct MorphIndices {
  mut current : Map[UInt64, UInt]
  mut prev : Map[UInt64, UInt]
}

///|
pub fn MorphIndices::new() -> MorphIndices {
  MorphIndices::{ current: {}, prev: {} }
}

///|
pub struct MorphUniforms {
  mut current_buffer : Array[Float]
  mut prev_buffer : Array[Float]
}

///|
pub fn MorphUniforms::new() -> MorphUniforms {
  MorphUniforms::{ current_buffer: [], prev_buffer: [] }
}

///|
pub let morph_indices_key : @ecs.ResourceKey[MorphIndices] = @ecs.register_resource(
  debug_name="mgstudio_pbr::MorphIndices",
)

///|
pub let morph_uniforms_key : @ecs.ResourceKey[MorphUniforms] = @ecs.register_resource(
  debug_name="mgstudio_pbr::MorphUniforms",
)

///|
pub impl @app.Resource for MorphIndices with resource() {
  morph_indices_key
}

///|
pub impl @app.Resource for MorphUniforms with resource() {
  morph_uniforms_key
}

///|
pub fn ensure_morph_resources(world : @ecs.World) -> Unit {
  if (try! world.get_resource(MorphIndices::resource())) is None {
    world.insert_resource(MorphIndices::resource(), MorphIndices::new())
  }
  if (try! world.get_resource(MorphUniforms::resource())) is None {
    world.insert_resource(MorphUniforms::resource(), MorphUniforms::new())
  }
}

///|
pub fn morph_indices_ref_or_abort(world : @ecs.World) -> Ref[MorphIndices] {
  ensure_morph_resources(world)
  match (try! world.get_resource_mut(MorphIndices::resource())) {
    Some(state) => Ref::new(state.peek())
    None => abort("Missing MorphIndices resource in render world")
  }
}

///|
pub fn morph_uniforms_ref_or_abort(world : @ecs.World) -> Ref[MorphUniforms] {
  ensure_morph_resources(world)
  match (try! world.get_resource_mut(MorphUniforms::resource())) {
    Some(state) => Ref::new(state.peek())
    None => abort("Missing MorphUniforms resource in render world")
  }
}

///|
pub fn morph_indices_swap_and_reset(
  morph_indices_ref : Ref[MorphIndices],
) -> Unit {
  morph_indices_ref.val.prev = morph_indices_ref.val.current
  morph_indices_ref.val.current = {}
}

///|
pub fn morph_uniforms_swap_and_reset(
  morph_uniforms_ref : Ref[MorphUniforms],
) -> Unit {
  morph_uniforms_ref.val.prev_buffer = morph_uniforms_ref.val.current_buffer
  morph_uniforms_ref.val.current_buffer = []
}

///|
pub struct Render3dMorphState {
  weights : Array[Float]
  normalized : Bool
}

///|
pub fn Render3dMorphState::default() -> Render3dMorphState {
  Render3dMorphState::{ weights: [], normalized: true }
}

///|
pub fn render3d_morph_state(weights : Array[Float]) -> Render3dMorphState {
  let normalized_weights = render3d_normalize_morph_weights(weights)
  Render3dMorphState::{ normalized: true, weights: normalized_weights }
}

///|
pub fn render3d_morph_weights_all_zero(weights : Array[Float]) -> Bool {
  for weight in weights {
    if weight != 0.0F {
      return false
    }
  }
  true
}

///|
pub fn render3d_normalize_morph_weights(weights : Array[Float]) -> Array[Float] {
  let normalized : Array[Float] = []
  let mut sum = 0.0F
  for weight in weights {
    let safe = if weight < 0.0F { 0.0F } else { weight }
    normalized.push(safe)
    sum = sum + safe
  }
  if sum <= 0.0F {
    return normalized
  }
  for index in 0..<normalized.length() {
    normalized[index] = normalized[index] / sum
  }
  normalized
}

///|
pub fn render3d_morph_non_zero_weight_count(weights : Array[Float]) -> Int {
  let mut count = 0
  for weight in weights {
    if weight != 0.0F {
      count = count + 1
    }
  }
  count
}

///|
pub fn Render3dMorphState::weights(self : Render3dMorphState) -> Array[Float] {
  self.weights
}
