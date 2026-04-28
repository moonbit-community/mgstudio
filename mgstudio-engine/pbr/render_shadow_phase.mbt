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
const SHADOW_PIPELINE_KIND_DEPTH_ONLY : Int = 0

///|
const SHADOW_PIPELINE_KIND_MATERIAL : Int = 1

///|
priv struct ShadowPhaseItem3d {
  batch_set_key : ShadowBatchSetKey3d
  bin_key : ShadowBinKey3d
  entity : PhaseEntityRef3d
  extracted_index : Int
  draw_item_index : Int
}

///|
priv struct ShadowBatchSetKey3d {
  pipeline_kind : Int
  may_discard : Bool
  topology_kind : Int
  indexed : Bool
  material_flags : UInt
  cull_mode : Int
}

///|
priv struct ShadowBinKey3d {
  mesh_id : Int
}

///|
priv struct Render3dShadowPhaseView {
  shadow_view : Render3dShadowView
  items : Array[ShadowPhaseItem3d]
}

///|
fn render3d_shadow_phase_item_debug_key(item : ShadowPhaseItem3d) -> Int {
  item.entity.render_entity.id * 31 +
  item.entity.render_entity.generation * 17 +
  item.entity.main_entity.id +
  item.bin_key.mesh_id +
  item.batch_set_key.pipeline_kind * 13 +
  item.batch_set_key.topology_kind
}

///|
fn render3d_shadow_cmp_uint(lhs : UInt, rhs : UInt) -> Int {
  if lhs < rhs {
    -1
  } else if lhs > rhs {
    1
  } else {
    0
  }
}

///|
fn render3d_shadow_cmp_bool(lhs : Bool, rhs : Bool) -> Int {
  if lhs == rhs {
    0
  } else if lhs {
    1
  } else {
    -1
  }
}

///|
fn render3d_shadow_batch_set_key(
  mesh : Mesh3dExtractedPayload,
) -> ShadowBatchSetKey3d {
  let may_discard = render3d_shadow_material_may_discard(
    mesh.material.alpha_mode,
  )
  {
    pipeline_kind: if may_discard {
      SHADOW_PIPELINE_KIND_MATERIAL
    } else {
      SHADOW_PIPELINE_KIND_DEPTH_ONLY
    },
    may_discard,
    topology_kind: mesh.mesh_topology_kind,
    indexed: mesh.mesh_is_indexed,
    material_flags: @pbr_render.render3d_standard_material_flags(
      mesh.material,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      forward_decal=mesh.is_forward_decal,
    ),
    cull_mode: @pbr_render.render3d_cull_mode_value(mesh.material, 0),
  }
}

///|
fn render3d_shadow_material_may_discard(alpha_mode : AlphaMode3d) -> Bool {
  // Bevy source: `bevy_pbr/src/render/light.rs::specialize_shadows`.
  // `MeshPipelineKey::MAY_DISCARD` selects the material shadow draw function
  // instead of the depth-only draw function for these alpha modes.
  match alpha_mode {
    Mask(_) | Blend | Premultiplied | Add | AlphaToCoverage => true
    _ => false
  }
}

///|
fn render3d_shadow_phase_item_cmp(
  lhs : ShadowPhaseItem3d,
  rhs : ShadowPhaseItem3d,
) -> Int {
  let pipeline_cmp = @pbr_render.cmp_int(
    lhs.batch_set_key.pipeline_kind,
    rhs.batch_set_key.pipeline_kind,
  )
  if pipeline_cmp != 0 {
    return pipeline_cmp
  }
  let may_discard_cmp = render3d_shadow_cmp_bool(
    lhs.batch_set_key.may_discard,
    rhs.batch_set_key.may_discard,
  )
  if may_discard_cmp != 0 {
    return may_discard_cmp
  }
  let topology_cmp = @pbr_render.cmp_int(
    lhs.batch_set_key.topology_kind,
    rhs.batch_set_key.topology_kind,
  )
  if topology_cmp != 0 {
    return topology_cmp
  }
  let indexed_cmp = render3d_shadow_cmp_bool(
    lhs.batch_set_key.indexed,
    rhs.batch_set_key.indexed,
  )
  if indexed_cmp != 0 {
    return indexed_cmp
  }
  let flags_cmp = render3d_shadow_cmp_uint(
    lhs.batch_set_key.material_flags,
    rhs.batch_set_key.material_flags,
  )
  if flags_cmp != 0 {
    return flags_cmp
  }
  let cull_cmp = @pbr_render.cmp_int(
    lhs.batch_set_key.cull_mode,
    rhs.batch_set_key.cull_mode,
  )
  if cull_cmp != 0 {
    return cull_cmp
  }
  let mesh_cmp = @pbr_render.cmp_int(lhs.bin_key.mesh_id, rhs.bin_key.mesh_id)
  if mesh_cmp != 0 {
    return mesh_cmp
  }
  phase_entity_ref3d_cmp(lhs.entity, rhs.entity)
}

///|
fn render3d_mesh_can_cast_shadow(mesh : Mesh3dExtractedPayload) -> Bool {
  if !mesh.material_properties.shadows_enabled {
    return false
  }
  if mesh.has_not_shadow_caster {
    return false
  }
  if mesh.is_forward_decal || mesh.clustered_decal is Some(_) {
    return false
  }
  true
}

///|
fn render3d_queue_shadow_phase_items(
  draw_items : Array[MeshPhaseItem3d],
  meshes : Array[ExtractedMesh3d],
) -> Array[ShadowPhaseItem3d] {
  let shadow_items : Array[ShadowPhaseItem3d] = []
  for draw_item_index in 0..<draw_items.length() {
    let draw_item = draw_items[draw_item_index]
    let extracted_mesh = meshes[draw_item.extracted_index]
    if !render3d_mesh_can_cast_shadow(extracted_mesh.payload) {
      continue
    }
    let batch_set_key = render3d_shadow_batch_set_key(extracted_mesh.payload)
    shadow_items.push(ShadowPhaseItem3d::{
      batch_set_key,
      bin_key: { mesh_id: extracted_mesh.payload.mesh_id },
      entity: extracted_mesh.entity,
      extracted_index: draw_item.extracted_index,
      draw_item_index,
    })
  }
  shadow_items.sort_by(render3d_shadow_phase_item_cmp)
  shadow_items
}

///|
fn render3d_execute_shadow_phase_view(
  camera_entity : @core.Entity,
  pass_lighting : Render3dLightingState,
  pass_kind : Int,
  point_shadow_near : Float,
  meshes : Array[ExtractedMesh3d],
  phase_view : Render3dShadowPhaseView,
) -> Unit {
  render3d_shadow_view_begin_pass(
    phase_view.shadow_view,
    pass_lighting,
    pass_kind,
    point_shadow_near,
  )
  for shadow_phase_item in phase_view.items {
    ignore(render3d_shadow_phase_item_debug_key(shadow_phase_item))
    let extracted_shadow_mesh = meshes[shadow_phase_item.extracted_index]
    let shadow_mesh = extracted_shadow_mesh.payload
    @pbr_render.render3d_draw_mesh_gpu_payload(
      @pbr_render.render3d_build_mesh_gpu_draw_payload(
        shadow_mesh.mesh_id,
        camera_entity.id,
        camera_entity.generation,
        shadow_phase_item.draw_item_index,
        MESH3D_DRAW_INDIRECT_KIND_NONE,
        -1,
        shadow_mesh.material,
        shadow_mesh.transform,
        shadow_mesh.transform,
        1.0F,
        1.0F,
        1.0F,
        1.0F,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        0.5F,
        0.5F,
        0.0F,
        0.0F,
        0.0F,
        1.5F,
        -1,
        0.0F,
        0.0F,
        -1,
        0.0F,
        0.0F,
        -1,
        -1,
        0.0F,
        @math.Quat::identity(),
        @sprite.Color::white(),
        0.0F,
        0.0F,
        0,
        skinning_key_hi=shadow_mesh.skinning_key_hi,
        skinning_key_lo=if shadow_mesh.skinning_key_hi >= 0 { 0 } else { -1 },
      ),
    )
  }
  @render.host_gpu_end_pass()
}
