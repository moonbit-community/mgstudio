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
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::Shadow`.
// This is intentionally small for the first migration step: it owns shadow
// caster filtering and item identity before the draw loop is moved to a real
// binned render phase.

///|
priv struct ShadowPhaseItem3d {
  entity : PhaseEntityRef3d
  extracted_index : Int
  draw_item_index : Int
}

///|
fn render3d_shadow_phase_item_debug_key(item : ShadowPhaseItem3d) -> Int {
  item.entity.render_entity.id * 31 +
  item.entity.render_entity.generation * 17 +
  item.entity.main_entity.id
}

///|
fn render3d_mesh_can_cast_shadow(mesh : Mesh3dExtractedPayload) -> Bool {
  if mesh.has_not_shadow_caster {
    return false
  }
  if mesh.is_forward_decal || mesh.clustered_decal is Some(_) {
    return false
  }
  guard render3d_mesh_draw_alpha(
      mesh.material.alpha_mode,
      mesh.material.base_color.a,
    )
    is Some(shadow_alpha) else {
    return false
  }
  shadow_alpha >= 0.999F
}

///|
fn render3d_queue_shadow_phase_items(
  draw_items : Array[MeshPhaseItem3d],
  meshes : Array[ExtractedMesh3d],
  opaque_alpha_draw_item_indices : Array[Int],
) -> Array[ShadowPhaseItem3d] {
  let shadow_items : Array[ShadowPhaseItem3d] = []
  for draw_item_index in opaque_alpha_draw_item_indices {
    let draw_item = draw_items[draw_item_index]
    if draw_item.phase != RENDER3D_PHASE_OPAQUE &&
      draw_item.phase != RENDER3D_PHASE_ALPHA_MASK {
      continue
    }
    let extracted_mesh = meshes[draw_item.extracted_index]
    if !render3d_mesh_can_cast_shadow(extracted_mesh.payload) {
      continue
    }
    shadow_items.push(ShadowPhaseItem3d::{
      entity: extracted_mesh.entity,
      extracted_index: draw_item.extracted_index,
      draw_item_index,
    })
  }
  shadow_items
}
