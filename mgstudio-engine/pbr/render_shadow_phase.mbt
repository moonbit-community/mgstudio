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
const SHADOW_PIPELINE_KIND_DEPTH_ONLY : Int = 0

///|
const SHADOW_PIPELINE_KIND_MATERIAL : Int = 1

///|
priv struct ShadowPhaseItem3d {
  batch_set_key : ShadowBatchSetKey3d
  bin_key : ShadowBinKey3d
  entity : PhaseEntityRef3d
  extracted_index : Int
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
  meshes : Array[ExtractedMesh3d],
  visible_extracted_indices : Array[Int],
) -> Array[ShadowPhaseItem3d] {
  let shadow_items : Array[ShadowPhaseItem3d] = []
  for extracted_index in visible_extracted_indices {
    if extracted_index < 0 || extracted_index >= meshes.length() {
      continue
    }
    let extracted_mesh = meshes[extracted_index]
    if !render3d_mesh_can_cast_shadow(extracted_mesh.payload) {
      continue
    }
    let batch_set_key = render3d_shadow_batch_set_key(extracted_mesh.payload)
    shadow_items.push(ShadowPhaseItem3d::{
      batch_set_key,
      bin_key: { mesh_id: extracted_mesh.payload.mesh_id },
      entity: extracted_mesh.entity,
      extracted_index,
    })
  }
  shadow_items.sort_by(render3d_shadow_phase_item_cmp)
  shadow_items
}

///|
fn render3d_shadow_visible_extracted_indices(
  meshes : Array[ExtractedMesh3d],
  camera_layers : @sprite.RenderLayers,
  shadow_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
) -> Array[Int] {
  let visible : Array[Int] = []
  for extracted_index in 0..<meshes.length() {
    let mesh = meshes[extracted_index].payload
    if mesh.mesh_id <= 0 {
      continue
    }
    if !camera_layers.matches(mesh.layers) {
      continue
    }
    if !render3d_should_apply_cpu_frustum_culling_flags(
        mesh.has_no_frustum_culling,
        false,
        mesh.has_no_cpu_culling,
      ) {
      visible.push(extracted_index)
      continue
    }
    if render3d_mesh_frustum_visible(mesh, shadow_frustum_planes) {
      visible.push(extracted_index)
    }
  }
  visible
}

///|
fn render3d_prewarm_shadow_material_pipeline(
  world : @ecs.World,
  shadow_mesh : Mesh3dExtractedPayload,
) -> @material.CachedRenderPipelineId? {
  guard shadow_mesh.material_properties.prepass_specialize
    is Some(prepass_specialize) else {
    return None
  }
  guard @sprite.render_mesh_asset_get(shadow_mesh.mesh_handle)
    is Some(mesh_asset) else {
    return None
  }
  let state_ref = @pbr_render.render3d_mesh_runtime_state_ref_or_abort(world)
  let render_mesh = @render_mesh.RenderMesh::from_mesh(
    mesh_asset,
    state_ref.val.mesh_vertex_buffer_layouts,
  )
  let layout = render_mesh.host_vertex_buffer_layout(
    state_ref.val.mesh_vertex_buffer_layouts,
  )
  let base_key = material_pipeline_key_for_standard_material_render_mesh(
    shadow_mesh.material_properties,
    render_mesh,
  )
  let shadow_bits = if render3d_shadow_material_may_discard(
      shadow_mesh.material.alpha_mode,
    ) {
    base_key.mesh_key().bits() |
    MESH_PIPELINE_KEY_DEPTH_PREPASS |
    MESH_PIPELINE_KEY_MAY_DISCARD
  } else {
    base_key.mesh_key().bits() | MESH_PIPELINE_KEY_DEPTH_PREPASS
  }
  let shadow_key = @material.ErasedMaterialPipelineKey::new(
    @material.ErasedMeshPipelineKey::new(shadow_bits, "MeshPipelineKey"),
    shadow_mesh.material_properties.material_key,
    "StandardMaterial",
  )
  let prepass_pipeline_id = @material.material_specialize_prepass(
    prepass_specialize,
    world,
    shadow_key,
    layout,
    shadow_mesh.material_properties,
  ) catch {
    err =>
      abort(
        "failed to specialize pbr shadow prepass material pipeline for mesh \{shadow_mesh.mesh_handle.id()}: \{err}",
      )
  }
  let runtime_pipeline_id = pbr_prepass_runtime_pipeline_id(prepass_pipeline_id)
  match
    state_ref.val.specialized_prepass_material_pipelines.render_pipeline_descriptor(
      prepass_pipeline_id,
    ) {
    Some(descriptor) =>
      @render.host_gpu_register_mesh3d_material_pipeline_descriptor(
        material_pipeline_id=runtime_pipeline_id.id(),
        descriptor~,
      )
    None => ()
  }
  Some(runtime_pipeline_id)
}

///|
fn render3d_execute_shadow_phase_view(
  world : @ecs.World,
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
  let (shadow_view_key_hi, shadow_view_key_lo) = render3d_shadow_view_cache_key(
    camera_entity,
    phase_view.shadow_view.light_entity,
  )
  let shadow_phase = render3d_mesh_gpu_binned_phase_new()
  let draw_storage_base = @render.host_gpu_reserve_mesh3d_draw_storage(
    count=phase_view.items.length(),
  )
  if draw_storage_base < 0 && phase_view.items.length() > 0 {
    @render.host_gpu_end_pass()
    return
  }
  let mut draw_storage_offset = 0
  for shadow_phase_item in phase_view.items {
    ignore(render3d_shadow_phase_item_debug_key(shadow_phase_item))
    let extracted_shadow_mesh = meshes[shadow_phase_item.extracted_index]
    let shadow_mesh = extracted_shadow_mesh.payload
    let material_pipeline_id = render3d_prewarm_shadow_material_pipeline(
      world, shadow_mesh,
    )
    let draw_storage_index = draw_storage_base + draw_storage_offset
    render3d_mesh_gpu_binned_phase_push(
      shadow_phase,
      @pbr_render.render3d_build_mesh_gpu_draw_payload(
        shadow_mesh.mesh_id,
        shadow_view_key_hi,
        shadow_view_key_lo,
        draw_storage_index,
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
        render3d_mesh_flags(extracted_shadow_mesh),
        0,
        material_pipeline_id~,
        skinning_key_hi=shadow_mesh.skinning_key_hi,
        skinning_key_lo=if shadow_mesh.skinning_key_hi >= 0 { 0 } else { -1 },
        morph_weights_index=shadow_mesh.morph_weights_index,
        previous_morph_weights_index=shadow_mesh.previous_morph_weights_index,
        morph_targets_texture_id=shadow_mesh.morph_targets_texture_id,
        world_from_local=Some(shadow_mesh.world_from_local),
        previous_world_from_local=Some(shadow_mesh.previous_world_from_local),
      ),
    )
    draw_storage_offset += 1
  }
  @render.host_gpu_prepare_mesh3d_main_pass_draw_batch(
    preprocess_camera_key_hi=shadow_view_key_hi,
    preprocess_camera_key_lo=shadow_view_key_lo,
    pass_kind~,
    entries=render3d_mesh_gpu_binned_phase_entries(shadow_phase),
  )
  render3d_draw_mesh_gpu_binned_phase(shadow_phase)
  @render.host_gpu_end_pass()
}
