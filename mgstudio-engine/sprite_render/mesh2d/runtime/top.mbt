// Copyright 2025 International Digital Economy Academy
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
pub(all) struct PhaseEntityRef {
  render_entity : @core.Entity
  main_entity : @core.Entity
}

///|
pub fn phase_entity_ref_for_main(main_entity : @core.Entity) -> PhaseEntityRef {
  PhaseEntityRef::{ render_entity: main_entity, main_entity }
}

///|
pub fn phase_entity_ref_placeholder() -> PhaseEntityRef {
  let placeholder = @core.Entity::placeholder()
  PhaseEntityRef::{ render_entity: placeholder, main_entity: placeholder }
}

///|
fn cmp_int(lhs : Int, rhs : Int) -> Int {
  if lhs < rhs {
    -1
  } else if lhs > rhs {
    1
  } else {
    0
  }
}

///|
pub fn phase_entity_ref_cmp(lhs : PhaseEntityRef, rhs : PhaseEntityRef) -> Int {
  let render_id = cmp_int(lhs.render_entity.id, rhs.render_entity.id)
  if render_id != 0 {
    return render_id
  }
  let render_generation = cmp_int(
    lhs.render_entity.generation,
    rhs.render_entity.generation,
  )
  if render_generation != 0 {
    return render_generation
  }
  let main_id = cmp_int(lhs.main_entity.id, rhs.main_entity.id)
  if main_id != 0 {
    return main_id
  }
  cmp_int(lhs.main_entity.generation, rhs.main_entity.generation)
}

///|
pub const MESH2D_PRIMITIVE_TOPOLOGY_LINE_STRIP : UInt = 2U

///|
pub const MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST : UInt = 3U

///|
pub const MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP : UInt = 4U

///|
pub const MESH2D_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_MASK_BITS : UInt = 0b111U

///|
pub const MESH2D_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_SHIFT_BITS : Int = 26

///|
pub const MESH2D_PIPELINE_KEY_INDEX_FORMAT_SHIFT_BITS : Int = 18

///|
pub const MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_NONE : Int = 0 <<
  MESH2D_PIPELINE_KEY_INDEX_FORMAT_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_U32 : Int = 1 <<
  MESH2D_PIPELINE_KEY_INDEX_FORMAT_SHIFT_BITS

///|
pub const MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_U16 : Int = 2 <<
  MESH2D_PIPELINE_KEY_INDEX_FORMAT_SHIFT_BITS

///|
pub fn mesh2d_primitive_topology_is_strip(primitive_topology : UInt) -> Bool {
  primitive_topology == MESH2D_PRIMITIVE_TOPOLOGY_LINE_STRIP ||
  primitive_topology == MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP
}

///|
pub fn mesh2d_pipeline_key_bits_for_primitive(
  primitive_topology : UInt,
  index_count : Int,
  uses_u32_indices : Bool,
) -> Int {
  let primitive_bits = (primitive_topology &
    MESH2D_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_MASK_BITS).reinterpret_as_int() <<
    MESH2D_PIPELINE_KEY_PRIMITIVE_TOPOLOGY_SHIFT_BITS
  let strip_index_bits = if mesh2d_primitive_topology_is_strip(
      primitive_topology,
    ) {
    if index_count <= 0 {
      MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_NONE
    } else if uses_u32_indices {
      MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_U32
    } else {
      MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_U16
    }
  } else {
    MESH2D_PIPELINE_KEY_STRIP_INDEX_FORMAT_NONE
  }
  primitive_bits | strip_index_bits
}

///|
test "mesh2d pipeline key encodes primitive topology" {
  debug_inspect(
    mesh2d_pipeline_key_bits_for_primitive(
      MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      0,
      false,
    ),
    content="201326592",
  )
}

///|
test "mesh2d pipeline key encodes strip index format only for strips" {
  debug_inspect(
    mesh2d_pipeline_key_bits_for_primitive(
      MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP,
      6,
      false,
    ),
    content="268959744",
  )
  debug_inspect(
    mesh2d_pipeline_key_bits_for_primitive(
      MESH2D_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      6,
      true,
    ),
    content="201326592",
  )
}

///|
pub(all) struct Mesh2dDrawPayload {
  mesh_id : Int
  transform : @transform.Transform
  layers : @camera_render_layers.RenderLayers
  wireframe : Bool
  wireframe_color : @color.Color
}

///|
pub(all) struct ExtractedMesh2d {
  entity : PhaseEntityRef
  payload : Mesh2dDrawPayload
}
