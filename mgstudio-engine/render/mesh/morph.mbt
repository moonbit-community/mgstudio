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

///|
// Bevy source: `bevy/crates/bevy_render/src/mesh/morph.rs`.

///|
pub const RENDER_MORPH_MAX_TEXTURE_WIDTH : Int = 2048

///|
pub const RENDER_MORPH_MAX_WEIGHTS : Int = 256

///|
pub const RENDER_MORPH_ATTRIBUTE_COMPONENT_COUNT : Int = 9

///|
pub(all) enum RenderMorphBuildError {
  TooManyAttributes(vertex_count~ : Int, component_count~ : Int)
  TooManyTargets(target_count~ : Int)
} derive(Eq, Debug)

///|
pub struct RenderMorphTextureRect {
  width : Int
  height : Int
  padding : Int
} derive(Eq, Debug)

///|
pub fn RenderMorphTextureRect::width(self : RenderMorphTextureRect) -> Int {
  self.width
}

///|
pub fn RenderMorphTextureRect::height(self : RenderMorphTextureRect) -> Int {
  self.height
}

///|
pub fn RenderMorphTextureRect::padding(self : RenderMorphTextureRect) -> Int {
  self.padding
}

///|
pub struct MorphTargetImagePlan {
  width : Int
  height : Int
  depth_or_array_layers : Int
  padding_components_per_layer : Int
  component_count_per_layer : Int
  byte_count : Int
} derive(Eq, Debug)

///|
pub fn MorphTargetImagePlan::width(self : MorphTargetImagePlan) -> Int {
  self.width
}

///|
pub fn MorphTargetImagePlan::height(self : MorphTargetImagePlan) -> Int {
  self.height
}

///|
pub fn MorphTargetImagePlan::depth_or_array_layers(
  self : MorphTargetImagePlan,
) -> Int {
  self.depth_or_array_layers
}

///|
pub fn MorphTargetImagePlan::padding_components_per_layer(
  self : MorphTargetImagePlan,
) -> Int {
  self.padding_components_per_layer
}

///|
pub fn MorphTargetImagePlan::component_count_per_layer(
  self : MorphTargetImagePlan,
) -> Int {
  self.component_count_per_layer
}

///|
pub fn MorphTargetImagePlan::byte_count(self : MorphTargetImagePlan) -> Int {
  self.byte_count
}

///|
pub(all) enum RenderMorphTargetAllocatorMode {
  Image
  Storage
} derive(Eq, Debug)

///|
pub struct RenderMorphTargetAllocatorState {
  mode : RenderMorphTargetAllocatorMode
  mesh_ids : Array[Int]
} derive(Debug)

///|
pub fn RenderMorphTargetAllocatorState::image() -> RenderMorphTargetAllocatorState {
  RenderMorphTargetAllocatorState::{ mode: Image, mesh_ids: [] }
}

///|
pub fn RenderMorphTargetAllocatorState::storage() -> RenderMorphTargetAllocatorState {
  RenderMorphTargetAllocatorState::{ mode: Storage, mesh_ids: [] }
}

///|
pub fn RenderMorphTargetAllocatorState::mode(
  self : RenderMorphTargetAllocatorState,
) -> RenderMorphTargetAllocatorMode {
  self.mode
}

///|
pub fn RenderMorphTargetAllocatorState::allocate(
  self : RenderMorphTargetAllocatorState,
  mesh_id : Int,
) -> Unit {
  if self.mode is Storage {
    return
  }
  if !self.mesh_ids.contains(mesh_id) {
    self.mesh_ids.push(mesh_id)
  }
}

///|
pub fn RenderMorphTargetAllocatorState::free(
  self : RenderMorphTargetAllocatorState,
  mesh_id : Int,
) -> Unit {
  if self.mode is Storage {
    return
  }
  let mut index = 0
  while index < self.mesh_ids.length() {
    if self.mesh_ids[index] == mesh_id {
      ignore(self.mesh_ids.remove(index))
      return
    }
    index = index + 1
  }
}

///|
pub fn RenderMorphTargetAllocatorState::has_image(
  self : RenderMorphTargetAllocatorState,
  mesh_id : Int,
) -> Bool {
  self.mode is Image && self.mesh_ids.contains(mesh_id)
}

///|
pub fn render_morph_lowest_2d(
  min_includes : Int,
  max_edge? : Int = RENDER_MORPH_MAX_TEXTURE_WIDTH,
) -> RenderMorphTextureRect? {
  if min_includes <= 0 || max_edge <= 0 {
    return None
  }
  let mut best_width = 0
  let mut best_height = 0
  let mut best_padding = 0
  for width = 1; width <= max_edge; width = width + 1 {
    let height = render_morph_div_ceil(min_includes, width)
    if height <= max_edge {
      let padding = width * height - min_includes
      if best_width == 0 || padding < best_padding {
        best_width = width
        best_height = height
        best_padding = padding
      }
    }
  }
  if best_width == 0 {
    None
  } else {
    Some(RenderMorphTextureRect::{
      width: best_width,
      height: best_height,
      padding: best_padding,
    })
  }
}

///|
pub fn render_morph_target_image_plan(
  target_count : Int,
  vertex_count : Int,
) -> Result[MorphTargetImagePlan, RenderMorphBuildError] {
  if target_count > RENDER_MORPH_MAX_WEIGHTS {
    return Err(TooManyTargets(target_count~))
  }
  let component_count = vertex_count * RENDER_MORPH_ATTRIBUTE_COMPONENT_COUNT
  guard render_morph_lowest_2d(component_count) is Some(rect) else {
    return Err(TooManyAttributes(vertex_count~, component_count~))
  }
  let layer_component_count = component_count + rect.padding
  Ok(MorphTargetImagePlan::{
    width: rect.width,
    height: rect.height,
    depth_or_array_layers: target_count,
    padding_components_per_layer: rect.padding,
    component_count_per_layer: component_count,
    byte_count: layer_component_count * target_count * 4,
  })
}

///|
pub fn render_morph_pack_attribute_components(
  position_x~ : Float,
  position_y~ : Float,
  position_z~ : Float,
  normal_x~ : Float,
  normal_y~ : Float,
  normal_z~ : Float,
  tangent_x~ : Float,
  tangent_y~ : Float,
  tangent_z~ : Float,
) -> Array[Float] {
  [
    position_x, position_y, position_z, normal_x, normal_y, normal_z, tangent_x,
    tangent_y, tangent_z,
  ]
}

///|
fn render_morph_div_ceil(value : Int, divisor : Int) -> Int {
  if divisor <= 0 {
    abort("render morph divisor must be positive")
  }
  if value <= 0 {
    0
  } else {
    (value + divisor - 1) / divisor
  }
}
