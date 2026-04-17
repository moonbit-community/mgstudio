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
pub(all) struct SkinBindingFreeRange {
  offset : Int
  length : Int
}

///|
pub(all) struct Render3dPhaseState {
  mut prepared_camera_order : Array[@core.Entity]
  mut camera_order_needs_refresh : Bool
  mut last_camera3d_count : Int
  mesh_upload_cache : Map[Int, Int]
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d]
  mut morph_indices_current : Map[UInt64, UInt]
  mut morph_indices_prev : Map[UInt64, UInt]
  mut morph_weights_current : Array[Float]
  mut morph_weights_prev : Array[Float]
  prepared_skin_bindings : Map[Int, PreparedSkinBinding3d]
  mut next_skin_binding_index : Int
  mut skin_binding_free_ranges : Array[SkinBindingFreeRange]
  skin_joint_to_skins : Map[UInt64, Array[@core.Entity]]
  skin_joints_by_skin : Map[UInt64, Array[@core.Entity]]
  skin_joint_count_by_skin : Map[UInt64, Int]
  skin_previous_matrices : Map[UInt64, Bool]
  mut skin_staging_rows : Array[Float]
  mut total_skin_joints : Int
  skin_upload_queue : Array[@core.Entity]
}

///|
pub fn Render3dPhaseState::new() -> Render3dPhaseState {
  Render3dPhaseState::{
    prepared_camera_order: [],
    camera_order_needs_refresh: true,
    last_camera3d_count: 0,
    mesh_upload_cache: {},
    mesh_preprocess_static_cache: {},
    morph_indices_current: {},
    morph_indices_prev: {},
    morph_weights_current: [],
    morph_weights_prev: [],
    prepared_skin_bindings: {},
    next_skin_binding_index: 0,
    skin_binding_free_ranges: [],
    skin_joint_to_skins: {},
    skin_joints_by_skin: {},
    skin_joint_count_by_skin: {},
    skin_previous_matrices: {},
    skin_staging_rows: [],
    total_skin_joints: 0,
    skin_upload_queue: [],
  }
}

///|
pub let render3d_phase_state_key : @ecs.ResourceKey[Render3dPhaseState] = @ecs.register_resource(
  debug_name="mgstudio_pbr::Render3dPhaseState",
)

///|
pub impl @app.Resource for Render3dPhaseState with resource() {
  render3d_phase_state_key
}

///|
pub fn ensure_render3d_phase_state_resource(world : @ecs.World) -> Unit {
  if (try! world.get_resource(Render3dPhaseState::resource())) is None {
    world.insert_resource(
      Render3dPhaseState::resource(),
      Render3dPhaseState::new(),
    )
  }
}

///|
pub fn render3d_phase_state_ref_or_abort(
  world : @ecs.World,
) -> Ref[Render3dPhaseState] {
  ensure_render3d_phase_state_resource(world)
  match (try! world.get_resource_ref_mut(Render3dPhaseState::resource())) {
    Some(state) => state
    None => abort("Missing Render3dPhaseState resource in render world")
  }
}

///|
pub fn render3d_phase_state_or_default(
  world : @ecs.World,
) -> Render3dPhaseState {
  ensure_render3d_phase_state_resource(world)
  match (try! world.get_resource(Render3dPhaseState::resource())) {
    Some(state) => state
    None => Render3dPhaseState::new()
  }
}
