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
  { render_entity, main_entity }
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
  depth_load_op : Camera3dDepthLoadOp
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
  world_from_local : @math.Affine3
  previous_world_from_local : @math.Affine3
  transform : @transform.Transform
  previous_transform : @transform.Transform
  aabb : @camera_primitives.Aabb?
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
  skinning_key_hi : Int
  has_previous_skin : Bool
  morph_weights_index : Int
  previous_morph_weights_index : Int
  morph_targets_texture_id : Int
  instance_vertex_buffer_id : Int
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
  current_uniform_index : @render_phase.InputUniformIndex
  phase : Int
  draw_function : @material.DrawFunctionId
  pipeline_id : @material.CachedRenderPipelineId
  distance : Float
  mesh_asset_id : Int
  slabs : @render_mesh.MeshSlabs
  material_bind_group_index : Int
  material_bind_group_slot : Int
}

///|
// One executable prepass/deferred phase draw. `phase_id` selects the retained
// phase's own preprocess buffers on the renderer side; `output_index` is the
// item's slot in that phase's prepared instance buffer, or `-1` when the slot
// is not CPU-authored (GPU-unpacked multidraw bins and indirect-mode
// unbatchables), in which case the draw uses the per-draw payload slot path.
priv struct Render3dPrepassPhaseDrawItem3d {
  phase_item : MeshPhaseItem3d
  phase_id : String
  output_index : Int
}

///|
priv struct Render3dMainViewDrawItems {
  views : Map[UInt64, Array[MeshPhaseItem3d]]
}

///|
fn Render3dMainViewDrawItems::Render3dMainViewDrawItems() -> Render3dMainViewDrawItems {
  { views: Map([]) }
}

///|
let render3d_main_view_draw_items_key : @ecs.ResourceKey[
  Render3dMainViewDrawItems,
] = @ecs.register_resource(debug_name="mgstudio_pbr::Render3dMainViewDrawItems")

///|
impl @app.Resource for Render3dMainViewDrawItems with fn resource() {
  render3d_main_view_draw_items_key
}

///|
fn Render3dMainViewDrawItems::set_draw_items(
  self : Render3dMainViewDrawItems,
  retained_view_entity : @core.Entity,
  draw_items : Array[MeshPhaseItem3d],
) -> Unit {
  self.views.set(retained_view_entity.to_bits(), draw_items.copy())
}

///|
fn Render3dMainViewDrawItems::retain_live_views(
  self : Render3dMainViewDrawItems,
  live_views : Map[UInt64, Bool],
) -> Unit {
  let stale : Array[UInt64] = []
  for view_bits, _draw_items in self.views {
    if !live_views.contains(view_bits) {
      stale.push(view_bits)
    }
  }
  for view_bits in stale {
    self.views.remove(view_bits)
  }
}

///|
fn Render3dMainViewDrawItems::items(
  self : Render3dMainViewDrawItems,
  retained_view_entity : @core.Entity,
) -> Array[MeshPhaseItem3d]? {
  self.views.get(retained_view_entity.to_bits())
}

///|
fn Render3dMainViewDrawItems::len(
  self : Render3dMainViewDrawItems,
  retained_view_entity : @core.Entity,
) -> Int {
  match self.items(retained_view_entity) {
    Some(draw_items) => draw_items.length()
    None => 0
  }
}

///|
fn render3d_sort_mesh_phase_items(
  items : Array[MeshPhaseItem3d],
) -> Array[MeshPhaseItem3d] {
  items.sort_by(fn(a, b) {
    let phase_cmp = @pbr_render.cmp_int(a.phase, b.phase)
    if phase_cmp != 0 {
      return phase_cmp
    }
    if a.phase == RENDER3D_PHASE_TRANSMISSIVE ||
      a.phase == RENDER3D_PHASE_TRANSPARENT {
      let depth_cmp = @pbr_render.cmp_float(b.distance, a.distance)
      if depth_cmp != 0 {
        return depth_cmp
      }
    } else {
      let depth_cmp = @pbr_render.cmp_float(a.distance, b.distance)
      if depth_cmp != 0 {
        return depth_cmp
      }
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  items
}

///|
fn render3d_merge_main_view_phase_items(
  existing : Array[MeshPhaseItem3d],
  meshes : Array[ExtractedMesh3d],
  dequeued : Array[@render.MainEntity],
  queued : Array[MeshPhaseItem3d],
) -> Array[MeshPhaseItem3d] {
  let extracted_index_by_main_entity : Map[UInt64, Int] = Map([])
  for index in 0..<meshes.length() {
    extracted_index_by_main_entity.set(
      meshes[index].entity.main_entity.to_bits(),
      index,
    )
  }
  let dequeued_main_entities : Map[UInt64, Bool] = Map([])
  for main_entity in dequeued {
    dequeued_main_entities.set(main_entity.id().to_bits(), true)
  }
  let queued_by_main_entity : Map[UInt64, MeshPhaseItem3d] = Map([])
  for queued_item in queued {
    guard extracted_index_by_main_entity.get(
        queued_item.entity.main_entity.to_bits(),
      )
      is Some(extracted_index) else {
      abort(
        "queued pbr main phase entity is missing its current extracted draw payload",
      )
    }
    queued_by_main_entity.set(queued_item.entity.main_entity.to_bits(), {
      ..queued_item,
      extracted_index,
    })
  }
  let merged : Array[MeshPhaseItem3d] = []
  for item in existing {
    let main_entity_bits = item.entity.main_entity.to_bits()
    if dequeued_main_entities.contains(main_entity_bits) ||
      queued_by_main_entity.contains(main_entity_bits) {
      continue
    }
    guard extracted_index_by_main_entity.get(main_entity_bits)
      is Some(extracted_index) else {
      abort(
        "retained pbr main phase entity is missing its current extracted draw payload",
      )
    }
    merged.push({ ..item, extracted_index, })
  }
  for _, queued_item in queued_by_main_entity {
    merged.push(queued_item)
  }
  render3d_sort_mesh_phase_items(merged)
}

///|
priv struct Render3dMainViewPhaseIndexStore {
  views : Map[UInt64, Array[Int]]
}

///|
fn Render3dMainViewPhaseIndexStore::Render3dMainViewPhaseIndexStore() -> Render3dMainViewPhaseIndexStore {
  { views: Map([]) }
}

///|
fn Render3dMainViewPhaseIndexStore::set_indices(
  self : Render3dMainViewPhaseIndexStore,
  retained_view_entity : @core.Entity,
  indices : Array[Int],
) -> Unit {
  self.views.set(retained_view_entity.to_bits(), indices.copy())
}

///|
fn Render3dMainViewPhaseIndexStore::retain_live_views(
  self : Render3dMainViewPhaseIndexStore,
  live_views : Map[UInt64, Bool],
) -> Unit {
  let stale : Array[UInt64] = []
  for view_bits, _indices in self.views {
    if !live_views.contains(view_bits) {
      stale.push(view_bits)
    }
  }
  for view_bits in stale {
    self.views.remove(view_bits)
  }
}

///|
fn Render3dMainViewPhaseIndexStore::indices(
  self : Render3dMainViewPhaseIndexStore,
  retained_view_entity : @core.Entity,
) -> Array[Int]? {
  self.views.get(retained_view_entity.to_bits())
}

///|
priv struct Render3dOpaqueMainViewPhases {
  store : Render3dMainViewPhaseIndexStore
}

///|
fn Render3dOpaqueMainViewPhases::Render3dOpaqueMainViewPhases() -> Render3dOpaqueMainViewPhases {
  { store: Render3dMainViewPhaseIndexStore() }
}

///|
let render3d_opaque_main_view_phases_key : @ecs.ResourceKey[
  Render3dOpaqueMainViewPhases,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::Render3dOpaqueMainViewPhases",
)

///|
impl @app.Resource for Render3dOpaqueMainViewPhases with fn resource() {
  render3d_opaque_main_view_phases_key
}

///|
priv struct Render3dAlphaMaskMainViewPhases {
  store : Render3dMainViewPhaseIndexStore
}

///|
fn Render3dAlphaMaskMainViewPhases::Render3dAlphaMaskMainViewPhases() -> Render3dAlphaMaskMainViewPhases {
  { store: Render3dMainViewPhaseIndexStore() }
}

///|
let render3d_alpha_mask_main_view_phases_key : @ecs.ResourceKey[
  Render3dAlphaMaskMainViewPhases,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::Render3dAlphaMaskMainViewPhases",
)

///|
impl @app.Resource for Render3dAlphaMaskMainViewPhases with fn resource() {
  render3d_alpha_mask_main_view_phases_key
}

///|
priv struct Render3dTransmissiveMainViewPhases {
  store : Render3dMainViewPhaseIndexStore
}

///|
fn Render3dTransmissiveMainViewPhases::Render3dTransmissiveMainViewPhases() -> Render3dTransmissiveMainViewPhases {
  { store: Render3dMainViewPhaseIndexStore() }
}

///|
let render3d_transmissive_main_view_phases_key : @ecs.ResourceKey[
  Render3dTransmissiveMainViewPhases,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::Render3dTransmissiveMainViewPhases",
)

///|
impl @app.Resource for Render3dTransmissiveMainViewPhases with fn resource() {
  render3d_transmissive_main_view_phases_key
}

///|
priv struct Render3dTransparentMainViewPhases {
  store : Render3dMainViewPhaseIndexStore
}

///|
fn Render3dTransparentMainViewPhases::Render3dTransparentMainViewPhases() -> Render3dTransparentMainViewPhases {
  { store: Render3dMainViewPhaseIndexStore() }
}

///|
let render3d_transparent_main_view_phases_key : @ecs.ResourceKey[
  Render3dTransparentMainViewPhases,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::Render3dTransparentMainViewPhases",
)

///|
impl @app.Resource for Render3dTransparentMainViewPhases with fn resource() {
  render3d_transparent_main_view_phases_key
}

///|
fn ensure_render3d_main_view_phase_resources(world : @ecs.World) -> Unit {
  if world.get_resource(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dMainViewDrawItems]),
    )
    is None {
    world.insert_resource(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dMainViewDrawItems]),
      Render3dMainViewDrawItems(),
    )
  }
  if world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dOpaqueMainViewPhases]),
    )
    is None {
    world.insert_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dOpaqueMainViewPhases]),
      Render3dOpaqueMainViewPhases(),
    )
  }
  if world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskMainViewPhases]),
    )
    is None {
    world.insert_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskMainViewPhases]),
      Render3dAlphaMaskMainViewPhases(),
    )
  }
  if world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dTransmissiveMainViewPhases]),
    )
    is None {
    world.insert_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dTransmissiveMainViewPhases]),
      Render3dTransmissiveMainViewPhases(),
    )
  }
  if world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dTransparentMainViewPhases]),
    )
    is None {
    world.insert_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dTransparentMainViewPhases]),
      Render3dTransparentMainViewPhases(),
    )
  }
}

///|
fn render3d_main_view_draw_items_mut_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[Render3dMainViewDrawItems] {
  ensure_render3d_main_view_phase_resources(world)
  match
    world.get_resource_mut(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dMainViewDrawItems]),
    ) {
    Some(draw_items) => draw_items
    None => abort("Missing Render3dMainViewDrawItems resource in render world")
  }
}

///|
fn render3d_partition_main_view_phase_indices(
  draw_items : Array[MeshPhaseItem3d],
) -> (Array[Int], Array[Int], Array[Int], Array[Int]) {
  let opaque_draw_item_indices : Array[Int] = []
  let alpha_mask_draw_item_indices : Array[Int] = []
  let transmissive_draw_item_indices : Array[Int] = []
  let transparent_draw_item_indices : Array[Int] = []
  for index in 0..<draw_items.length() {
    let item = draw_items[index]
    if item.phase == RENDER3D_PHASE_OPAQUE {
      opaque_draw_item_indices.push(index)
    } else if item.phase == RENDER3D_PHASE_ALPHA_MASK {
      alpha_mask_draw_item_indices.push(index)
    } else if item.phase == RENDER3D_PHASE_TRANSMISSIVE {
      transmissive_draw_item_indices.push(index)
    } else if item.phase == RENDER3D_PHASE_TRANSPARENT {
      transparent_draw_item_indices.push(index)
    }
  }
  (
    opaque_draw_item_indices, alpha_mask_draw_item_indices, transmissive_draw_item_indices,
    transparent_draw_item_indices,
  )
}

///|
fn render3d_prepare_main_view_phase(
  world : @ecs.World,
  retained_view_entity : @core.Entity,
  draw_items : Array[MeshPhaseItem3d],
) -> Unit {
  ensure_render3d_main_view_phase_resources(world)
  let (
    opaque_draw_item_indices,
    alpha_mask_draw_item_indices,
    transmissive_draw_item_indices,
    transparent_draw_item_indices,
  ) = render3d_partition_main_view_phase_indices(draw_items)
  let draw_items_resource = render3d_main_view_draw_items_mut_or_abort(world)
  draw_items_resource.modify(fn(value) {
    value.set_draw_items(retained_view_entity, draw_items)
  })
  guard world.get_resource_mut(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dOpaqueMainViewPhases]),
    )
    is Some(opaque_phases) else {
    abort("Missing Render3dOpaqueMainViewPhases resource in render world")
  }
  opaque_phases.modify(fn(value) {
    value.store.set_indices(retained_view_entity, opaque_draw_item_indices)
  })
  guard world.get_resource_mut(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskMainViewPhases]),
    )
    is Some(alpha_mask_phases) else {
    abort("Missing Render3dAlphaMaskMainViewPhases resource in render world")
  }
  alpha_mask_phases.modify(fn(value) {
    value.store.set_indices(retained_view_entity, alpha_mask_draw_item_indices)
  })
  guard world.get_resource_mut(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dTransmissiveMainViewPhases]),
    )
    is Some(transmissive_phases) else {
    abort("Missing Render3dTransmissiveMainViewPhases resource in render world")
  }
  transmissive_phases.modify(fn(value) {
    value.store.set_indices(
      retained_view_entity, transmissive_draw_item_indices,
    )
  })
  guard world.get_resource_mut(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dTransparentMainViewPhases]),
    )
    is Some(transparent_phases) else {
    abort("Missing Render3dTransparentMainViewPhases resource in render world")
  }
  transparent_phases.modify(fn(value) {
    value.store.set_indices(retained_view_entity, transparent_draw_item_indices)
  })
}

///|
fn render3d_apply_main_view_phase_queue(
  world : @ecs.World,
  retained_view_entity : @core.Entity,
  meshes : Array[ExtractedMesh3d],
  dequeued : Array[@render.MainEntity],
  queued : Array[MeshPhaseItem3d],
) -> Array[MeshPhaseItem3d] {
  ensure_render3d_main_view_phase_resources(world)
  let existing = match
    world.get_resource(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dMainViewDrawItems]),
    ) {
    Some(draw_items) =>
      match draw_items.items(retained_view_entity) {
        Some(items) => items.copy()
        None => []
      }
    None => []
  }
  let merged = render3d_merge_main_view_phase_items(
    existing, meshes, dequeued, queued,
  )
  render3d_prepare_main_view_phase(world, retained_view_entity, merged)
  merged
}

///|
fn render3d_retain_live_main_view_phases(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
) -> Unit {
  let live_views : Map[UInt64, Bool] = Map([])
  for camera in cameras {
    live_views.set(camera.entity.main_entity.to_bits(), true)
  }
  ensure_render3d_main_view_phase_resources(world)
  let draw_items = render3d_main_view_draw_items_mut_or_abort(world)
  draw_items.modify(fn(value) { value.retain_live_views(live_views) })
  guard world.get_resource_mut(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dOpaqueMainViewPhases]),
    )
    is Some(opaque_phases) else {
    abort("Missing Render3dOpaqueMainViewPhases resource in render world")
  }
  opaque_phases.modify(fn(value) { value.store.retain_live_views(live_views) })
  guard world.get_resource_mut(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskMainViewPhases]),
    )
    is Some(alpha_mask_phases) else {
    abort("Missing Render3dAlphaMaskMainViewPhases resource in render world")
  }
  alpha_mask_phases.modify(fn(value) {
    value.store.retain_live_views(live_views)
  })
  guard world.get_resource_mut(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dTransmissiveMainViewPhases]),
    )
    is Some(transmissive_phases) else {
    abort("Missing Render3dTransmissiveMainViewPhases resource in render world")
  }
  transmissive_phases.modify(fn(value) {
    value.store.retain_live_views(live_views)
  })
  guard world.get_resource_mut(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dTransparentMainViewPhases]),
    )
    is Some(transparent_phases) else {
    abort("Missing Render3dTransparentMainViewPhases resource in render world")
  }
  transparent_phases.modify(fn(value) {
    value.store.retain_live_views(live_views)
  })
}

///|
fn render3d_main_view_phase_items_or_abort(
  world : @ecs.World,
  retained_view_entity : @core.Entity,
) -> Array[MeshPhaseItem3d] {
  guard world.get_resource(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dMainViewDrawItems]),
    )
    is Some(draw_items) else {
    abort("Missing Render3dMainViewDrawItems resource during pbr main pass")
  }
  guard draw_items.items(retained_view_entity) is Some(items) else {
    abort("Missing retained Render3dMainViewDrawItems during pbr main pass")
  }
  items.copy()
}

///|
fn render3d_main_view_phase_draw_item_indices_or_abort(
  world : @ecs.World,
  retained_view_entity : @core.Entity,
) -> Array[Int] {
  guard world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dOpaqueMainViewPhases]),
    )
    is Some(opaque_phases) else {
    abort("Missing Render3dOpaqueMainViewPhases resource during pbr main pass")
  }
  guard world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dAlphaMaskMainViewPhases]),
    )
    is Some(alpha_mask_phases) else {
    abort(
      "Missing Render3dAlphaMaskMainViewPhases resource during pbr main pass",
    )
  }
  guard world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dTransmissiveMainViewPhases]),
    )
    is Some(transmissive_phases) else {
    abort(
      "Missing Render3dTransmissiveMainViewPhases resource during pbr main pass",
    )
  }
  guard world.get_resource(
      (
        @app.Resource::resource() :
        @ecs.ResourceKey[Render3dTransparentMainViewPhases]),
    )
    is Some(transparent_phases) else {
    abort(
      "Missing Render3dTransparentMainViewPhases resource during pbr main pass",
    )
  }
  let indices : Array[Int] = []
  match opaque_phases.store.indices(retained_view_entity) {
    Some(opaque_indices) =>
      for index in opaque_indices {
        indices.push(index)
      }
    None => ()
  }
  match alpha_mask_phases.store.indices(retained_view_entity) {
    Some(alpha_mask_indices) =>
      for index in alpha_mask_indices {
        indices.push(index)
      }
    None => ()
  }
  match transmissive_phases.store.indices(retained_view_entity) {
    Some(transmissive_indices) =>
      for index in transmissive_indices {
        indices.push(index)
      }
    None => ()
  }
  match transparent_phases.store.indices(retained_view_entity) {
    Some(transparent_indices) =>
      for index in transparent_indices {
        indices.push(index)
      }
    None => ()
  }
  indices
}

///|
fn render3d_main_view_phase_item_count_or_abort(
  world : @ecs.World,
  retained_view_entity : @core.Entity,
) -> Int {
  guard world.get_resource(
      (@app.Resource::resource() : @ecs.ResourceKey[Render3dMainViewDrawItems]),
    )
    is Some(draw_items) else {
    abort(
      "Missing Render3dMainViewDrawItems resource during pbr draw storage reservation",
    )
  }
  draw_items.len(retained_view_entity)
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
    items.push({
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
fn render3d_mesh_phase_kind(properties : @material.MaterialProperties) -> Int {
  match properties.render_phase_type {
    Opaque => RENDER3D_PHASE_OPAQUE
    AlphaMask => RENDER3D_PHASE_ALPHA_MASK
    Transmissive => RENDER3D_PHASE_TRANSMISSIVE
    Transparent => RENDER3D_PHASE_TRANSPARENT
  }
}

///|
fn render3d_main_pass_draw_function(
  properties : @material.MaterialProperties,
) -> @material.DrawFunctionId? {
  match properties.render_phase_type {
    Opaque => properties.get_draw_function(MAIN_PASS_OPAQUE_DRAW_FUNCTION_LABEL)
    AlphaMask =>
      properties.get_draw_function(MAIN_PASS_ALPHA_MASK_DRAW_FUNCTION_LABEL)
    Transmissive =>
      properties.get_draw_function(MAIN_PASS_TRANSMISSIVE_DRAW_FUNCTION_LABEL)
    Transparent =>
      properties.get_draw_function(MAIN_PASS_TRANSPARENT_DRAW_FUNCTION_LABEL)
  }
}

///|
fn render3d_material_phase_distance(
  visible_entity : @render.MainEntity,
  mesh_instance : RenderMeshQueueData,
  render_mesh_instances : RenderMeshInstances,
  render_mesh_assets : @render_mesh.RenderMeshAssets,
  maybe_batched_instance_buffers : RenderMeshInstanceGpuBatchedInstanceBuffers?,
  material_properties : @material.MaterialProperties,
  camera_transform : @transform.Transform,
) -> Float {
  match material_properties.render_phase_type {
    Transmissive | Transparent => {
      guard render_mesh_assets.get(mesh_instance.mesh_asset_id())
        is Some(render_mesh) else {
        abort(
          "Missing prepared RenderMesh during pbr transparent material queueing",
        )
      }
      let world_from_local = get_mesh_instance_world_from_local(
        visible_entity,
        mesh_instance.current_uniform_index(),
        render_mesh_instances,
        maybe_batched_instance_buffers,
      )
      let mesh_center = world_from_local.transform_point3(
        render_mesh.aabb_center(),
      )
      @pbr_render.render3d_mesh_position_view_depth(
        mesh_center, camera_transform,
      ) +
      material_properties.depth_bias
    }
    _ => 0.0F
  }
}

///|
fn render3d_queue_resolved_material_for_mesh(
  material_slots : RenderMaterial3dResolvedSlots,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
) -> Render3dResolvedMaterial? {
  match material_slots.get(visible_entity.id()) {
    Some(Resolved(material)) => Some(material)
    Some(Pending) | None => {
      pending_mesh_material_queues
      .queues()
      .push_current(retained_view_entity, render_entity, visible_entity)
      None
    }
  }
}

///|
fn render3d_queue_material_instance_for_mesh(
  render_material_instances : RenderMaterialInstances,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
) -> RenderMaterialInstance? {
  match render_material_instances.get(visible_entity.id()) {
    Some(instance) => Some(instance)
    None => {
      pending_mesh_material_queues
      .queues()
      .push_current(retained_view_entity, render_entity, visible_entity)
      None
    }
  }
}

///|
fn render3d_queue_material_binding_for_instance(
  render_material_bindings : RenderMaterialBindings,
  pending_mesh_material_queues : PendingMeshMaterialQueues,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
  instance : RenderMaterialInstance,
) -> MaterialBindingId? {
  if instance.asset_id() == DUMMY_MESH_MATERIAL_ID {
    return Some(MaterialBindingId())
  }
  match render_material_bindings.get(instance.asset_id()) {
    Some(binding) => Some(binding)
    None => {
      pending_mesh_material_queues
      .queues()
      .push_current(retained_view_entity, render_entity, visible_entity)
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
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  match render_mesh_instances.render_mesh_queue_data(visible_entity) {
    Some(mesh_instance) => Some(mesh_instance)
    None => {
      pending_mesh_material_queues
      .queues()
      .push_current(retained_view_entity, render_entity, visible_entity)
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
