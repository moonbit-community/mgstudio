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
