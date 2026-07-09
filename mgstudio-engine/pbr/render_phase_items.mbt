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

// Bevy keeps extracted item identity, render phase ordering, and raw GPU draw
// payload in distinct layers. Keep the same split here instead of collapsing
// everything into ad-hoc `*Instance` records.

///|
priv struct PhaseEntityRef3d {
  render_entity : @core.Entity
  main_entity : @core.Entity
}

///|
fn phase_entity_ref3d(
  main_entity : @core.Entity,
  render_entity : @core.Entity,
) -> PhaseEntityRef3d {
  PhaseEntityRef3d::{ render_entity, main_entity }
}

///|
fn phase_entity_ref3d_for_main(main_entity : @core.Entity) -> PhaseEntityRef3d {
  phase_entity_ref3d(main_entity, main_entity)
}

///|
fn phase_entity_ref3d_for_world_main(
  world : @ecs.World,
  main_entity : @core.Entity,
) -> PhaseEntityRef3d {
  match (try! world.get_by_key(main_entity, @render.ecs_key_render_entity)) {
    Some(value) => phase_entity_ref3d(main_entity, value.id())
    None => phase_entity_ref3d_for_main(main_entity)
  }
}

///|
fn phase_entity_ref3d_cmp(
  lhs : PhaseEntityRef3d,
  rhs : PhaseEntityRef3d,
) -> Int {
  let render_id = @pbr_render.cmp_int(
    lhs.render_entity.id,
    rhs.render_entity.id,
  )
  if render_id != 0 {
    return render_id
  }
  let render_generation = @pbr_render.cmp_int(
    lhs.render_entity.generation,
    rhs.render_entity.generation,
  )
  if render_generation != 0 {
    return render_generation
  }
  let main_id = @pbr_render.cmp_int(lhs.main_entity.id, rhs.main_entity.id)
  if main_id != 0 {
    return main_id
  }
  @pbr_render.cmp_int(lhs.main_entity.generation, rhs.main_entity.generation)
}

///|
priv struct Camera3dViewPayload {
  decal_config : CameraDecalConfig3d?
  deferred_config : CameraDeferredConfig3d?
  distance_fog : DistanceFog?
  auto_exposure : AutoExposure?
  volumetric_fog : VolumetricFog?
  atmosphere : @pbr_atmosphere.ExtractedAtmosphere?
  atmosphere_settings : @pbr_atmosphere.GpuAtmosphereSettings?
  camera : @camera_camera.Camera
  depth_texture_usages : Camera3dDepthTextureUsage
  projection : Projection
  sub_camera_view : SubCameraView3d?
  oit_settings : OrderIndependentTransparencySettings?
  screen_space_transmission : ScreenSpaceTransmission?
  bloom : Bloom?
  tonemapping : Tonemapping?
  deband_dither : DebandDither?
  chromatic_aberration : ChromaticAberration?
  contrast_adaptive_sharpening : @cas.ContrastAdaptiveSharpening?
  custom_post_process3d : CustomPostProcess3d?
  vignette : Vignette?
  motion_blur : MotionBlur?
  exposure : Exposure?
  color_grading : ColorGrading?
  environment_map_light : EnvironmentMapLight?
  generated_environment_map_light : GeneratedEnvironmentMapLight?
  atmosphere_environment_map_light : AtmosphereEnvironmentMapLight?
  has_environment_light_probes : Bool
  irradiance_volume : IrradianceVolume?
  screen_space_ambient_occlusion : ScreenSpaceAmbientOcclusion?
  screen_space_reflections : ScreenSpaceReflections?
  contact_shadows : ContactShadows?
  depth_prepass_enabled : Bool
  normal_prepass_enabled : Bool
  deferred_prepass_enabled : Bool
  no_indirect_drawing : Bool
  gpu_occlusion_culling_enabled : Bool
  hdr_enabled : Bool
  fxaa : Fxaa?
  temporal_jitter : TemporalJitter?
  temporal_anti_aliasing : TemporalAntiAliasing?
  shadow_filtering_method : ShadowFilteringMethod?
  motion_vector_prepass_enabled : Bool
  msaa : Msaa?
  transform : @transform.Transform
  previous_transform : @transform.Transform
  previous_clip_from_world : ProjectionMatrix3d?
  target_id : Int
  target_size : @math.IVec2
  scale_factor : Float
  layers : @camera_render_layers.RenderLayers
  has_no_cpu_culling : Bool
  invert_culling : Bool
}

///|
priv struct ExtractedCamera3d {
  entity : PhaseEntityRef3d
  payload : Camera3dViewPayload
}

///|
priv struct Mesh3dExtractedPayload {
  mesh_handle : @asset.Handle[@mesh.Mesh]
  mesh_id : Int
  mesh_preprocess_static : MeshPreprocessStatic3d?
  world_from_local : @math.Affine3
  previous_world_from_local : @math.Affine3
  transform : @transform.Transform
  previous_transform : @transform.Transform
  visibility_range : @visibility.VisibilityRange?
  aabb : @camera_primitives.Aabb?
  aabb_center_world : @math.Vec3?
  material_draw_data : MaterialDrawData3d
  material_extension : ExtendedMaterialMetadata3d?
  material_properties : @material.MaterialProperties
  material_bind_group_data : @render_resource.MaterialBindGroupResolvedData
  lightmap : Lightmap?
  is_forward_decal : Bool
  forward_decal_material_ext : ForwardDecalMaterialExt?
  clustered_decal : ClusteredDecal?
  has_not_shadow_caster : Bool
  has_not_shadow_receiver : Bool
  has_transmitted_shadow_receiver : Bool
  has_no_frustum_culling : Bool
  has_no_cpu_culling : Bool
  layers : @camera_render_layers.RenderLayers
  has_no_wireframe : Bool
  wireframe_asset_id : Int?
  wireframe_material : RenderWireframeMaterial?
  wireframe_color : WireframeColor?
  wireframe_line_width : WireframeLineWidth?
  wireframe_topology : WireframeTopology?
  skinning_key_hi : Int
  has_previous_skin : Bool
  morph_weights_index : Int
  previous_morph_weights_index : Int
  morph_targets_texture_id : Int
  instance_vertex_buffer_id : Int
  motion_vector_enabled : Bool
}

///|
priv struct ExtractedMesh3d {
  entity : PhaseEntityRef3d
  payload : Mesh3dExtractedPayload
}

///|
const RENDER3D_PHASE_OPAQUE : Int = 0

///|
const RENDER3D_PHASE_ALPHA_MASK : Int = 1

///|
const RENDER3D_PHASE_TRANSMISSIVE : Int = 2

///|
const RENDER3D_PHASE_TRANSPARENT : Int = 3

///|
priv struct CameraPhaseItem3d {
  entity : PhaseEntityRef3d
  extracted_index : Int
  order : Int
}

///|
priv struct Render3dCameraOrderEntry {
  entity : @core.Entity
  order : Int
  target : @camera_render_target.NormalizedRenderTarget?
}

///|
priv struct MeshPhaseItem3d {
  entity : PhaseEntityRef3d
  extracted_index : Int
  phase : Int
  pipeline_id : @material.CachedRenderPipelineId
  distance : Float
  mesh_asset_id : Int
  slabs : @render_mesh.MeshSlabs
  material_bind_group_index : Int
  material_bind_group_slot : Int
}

///|
const MESH3D_DRAW_INDIRECT_KIND_NONE : Int = 0

///|
const MESH3D_DRAW_INDIRECT_KIND_INDEXED : Int = 1

///|
const MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED : Int = 2

///|
type MeshGpuDrawPayload3d = @pbr_render.MeshGpuDrawPayload3d

///|
priv struct TransmissivePhaseItem3d {
  entity : PhaseEntityRef3d
  distance : Float
  payload : MeshGpuDrawPayload3d
}

///|
fn render3d_sort_transmissive_phase_items(
  items : Array[TransmissivePhaseItem3d],
) -> Array[TransmissivePhaseItem3d] {
  items.sort_by(fn(a, b) {
    let distance_cmp = @pbr_render.cmp_float(b.distance, a.distance)
    if distance_cmp != 0 {
      return distance_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  items
}

///|
fn render3d_queue_camera_phase_items(
  cameras : Array[ExtractedCamera3d],
) -> Array[CameraPhaseItem3d] {
  let items : Array[CameraPhaseItem3d] = []
  for i in 0..<cameras.length() {
    let camera = cameras[i]
    items.push(CameraPhaseItem3d::{
      entity: camera.entity,
      extracted_index: i,
      order: camera.payload.camera.order,
    })
  }
  items.sort_by(fn(a, b) {
    let order_cmp = @pbr_render.cmp_int(a.order, b.order)
    if order_cmp != 0 {
      return order_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  items
}

///|
fn render3d_mesh_phase_kind(
  properties : @material.MaterialProperties,
  alpha : Float,
) -> Int? {
  match properties.render_phase_type {
    @material.RenderPhaseType::Opaque => Some(RENDER3D_PHASE_OPAQUE)
    @material.RenderPhaseType::AlphaMask =>
      match properties.alpha_mode {
        Mask(cutoff) =>
          if alpha >= cutoff {
            Some(RENDER3D_PHASE_ALPHA_MASK)
          } else {
            None
          }
        _ => Some(RENDER3D_PHASE_ALPHA_MASK)
      }
    @material.RenderPhaseType::Transmissive => Some(RENDER3D_PHASE_TRANSMISSIVE)
    @material.RenderPhaseType::Transparent => Some(RENDER3D_PHASE_TRANSPARENT)
  }
}

///|
fn render3d_material_phase_distance(
  payload : Mesh3dExtractedPayload,
  material_properties : @material.MaterialProperties,
  camera_transform : @transform.Transform,
) -> Float {
  let distance = @pbr_render.render3d_mesh_position_view_depth(
    payload.world_from_local.translation,
    camera_transform,
  )
  match material_properties.render_phase_type {
    @material.RenderPhaseType::Transmissive
    | @material.RenderPhaseType::Transparent =>
      distance + material_properties.depth_bias
    _ => distance
  }
}

///|
fn render3d_queue_resolved_material_for_mesh(
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
  mesh : ExtractedMesh3d,
) -> Render3dResolvedMaterial? {
  match material_slots.get(mesh.entity.main_entity) {
    Some(Resolved(material)) => Some(material)
    Some(Pending) | None => {
      pending_mesh_material_queues
      .queues()
      .push_current(
        retained_view_entity,
        mesh.entity.render_entity,
        @render.MainEntity::new(mesh.entity.main_entity),
      )
      None
    }
  }
}

///|
fn render3d_queue_material_instance_for_mesh(
  render_material_instances : RenderMaterialInstances,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
  mesh : ExtractedMesh3d,
) -> RenderMaterialInstance? {
  let visible_entity = @render.MainEntity::new(mesh.entity.main_entity)
  match render_material_instances.get(visible_entity.id()) {
    Some(instance) => Some(instance)
    None => {
      pending_mesh_material_queues
      .queues()
      .push_current(
        retained_view_entity,
        mesh.entity.render_entity,
        visible_entity,
      )
      None
    }
  }
}

///|
fn render3d_queue_material_binding_for_instance(
  render_material_bindings : RenderMaterialBindings,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
  mesh : ExtractedMesh3d,
  instance : RenderMaterialInstance,
) -> MaterialBindingId? {
  if instance.asset_id() == DUMMY_MESH_MATERIAL_ID {
    return Some(MaterialBindingId::MaterialBindingId())
  }
  let visible_entity = @render.MainEntity::new(mesh.entity.main_entity)
  match render_material_bindings.get(instance.asset_id()) {
    Some(binding) => Some(binding)
    None => {
      pending_mesh_material_queues
      .queues()
      .push_current(
        retained_view_entity,
        mesh.entity.render_entity,
        visible_entity,
      )
      None
    }
  }
}

///|
fn render3d_queue_mesh_slabs_for_instance(
  mesh_allocator : @render_mesh.MeshAllocator,
  mesh_instance : RenderMeshQueueData,
) -> @render_mesh.MeshSlabs? {
  if mesh_instance.mesh_asset_id() <= 0 {
    return None
  }
  mesh_allocator.mesh_slabs(mesh_instance.mesh_asset_id())
}

///|
fn render3d_queue_mesh_instance_for_mesh(
  render_mesh_instances : RenderMeshInstances,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
  mesh : ExtractedMesh3d,
) -> RenderMeshQueueData? {
  let visible_entity = @render.MainEntity::new(mesh.entity.main_entity)
  match render_mesh_instances.render_mesh_queue_data(visible_entity) {
    Some(mesh_instance) => Some(mesh_instance)
    None => {
      pending_mesh_material_queues
      .queues()
      .push_current(
        retained_view_entity,
        mesh.entity.render_entity,
        visible_entity,
      )
      None
    }
  }
}

///|
fn render3d_split_phase_ranges(
  length : Int,
  max_num_splits : Int,
) -> Array[(Int, Int)] {
  if length <= 0 || max_num_splits <= 0 {
    return []
  }
  let num_splits = if length < max_num_splits { length } else { max_num_splits }
  let step = length / num_splits
  let ranges : Array[(Int, Int)] = []
  let mut remainder = length % num_splits
  let mut start = 0
  for _ in 0..<num_splits {
    let extra = if remainder > 0 {
      remainder = remainder - 1
      1
    } else {
      0
    }
    let next_end = start + step + extra
    let end_ = if next_end < length { next_end } else { length }
    ranges.push((start, end_))
    start = end_
  }
  ranges
}

///|
fn render3d_mesh_draw_alpha(alpha_mode : AlphaMode3d, alpha : Float) -> Float? {
  match alpha_mode {
    Opaque => Some(1.0F)
    Blend => Some(alpha)
    Premultiplied => Some(alpha)
    Add => Some(alpha)
    Multiply => Some(alpha)
    AlphaToCoverage => Some(alpha)
    Mask(cutoff) => if alpha >= cutoff { Some(1.0F) } else { None }
  }
}
