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
// Bevy source: `bevy/crates/bevy_pbr/src/prepass/mod.rs`,
// `SpecializedPrepassMaterialPipelineCache`,
// `ViewKeyPrepassCache`, and `specialize_prepass_material_meshes`.

///|
priv struct SpecializedPrepassMaterialPipelineCacheEntry {
  tick : @core.Tick
  pipeline_id : @material.CachedRenderPipelineId
  draw_function : @material.DrawFunctionId
}

///|
priv struct SpecializedPrepassMaterialViewPipelineCache {
  entries : Map[UInt64, SpecializedPrepassMaterialPipelineCacheEntry]
}

///|
fn SpecializedPrepassMaterialViewPipelineCache::new() -> SpecializedPrepassMaterialViewPipelineCache {
  SpecializedPrepassMaterialViewPipelineCache::{ entries: Map([]) }
}

///|
fn SpecializedPrepassMaterialViewPipelineCache::clear(
  self : SpecializedPrepassMaterialViewPipelineCache,
) -> Unit {
  self.entries.clear()
}

///|
fn SpecializedPrepassMaterialViewPipelineCache::contains(
  self : SpecializedPrepassMaterialViewPipelineCache,
  entity : @core.Entity,
) -> Bool {
  self.entries.contains(entity.to_bits())
}

///|
fn SpecializedPrepassMaterialViewPipelineCache::get(
  self : SpecializedPrepassMaterialViewPipelineCache,
  entity : @core.Entity,
) -> SpecializedPrepassMaterialPipelineCacheEntry? {
  self.entries.get(entity.to_bits())
}

///|
fn SpecializedPrepassMaterialViewPipelineCache::insert(
  self : SpecializedPrepassMaterialViewPipelineCache,
  entity : @core.Entity,
  tick : @core.Tick,
  pipeline_id : @material.CachedRenderPipelineId,
  draw_function : @material.DrawFunctionId,
) -> Unit {
  self.entries.set(entity.to_bits(), SpecializedPrepassMaterialPipelineCacheEntry::{
    tick,
    pipeline_id,
    draw_function,
  })
}

///|
fn SpecializedPrepassMaterialViewPipelineCache::remove(
  self : SpecializedPrepassMaterialViewPipelineCache,
  entity : @core.Entity,
) -> Unit {
  self.entries.remove(entity.to_bits())
}

///|
priv struct SpecializedPrepassMaterialPipelineCache {
  views : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    SpecializedPrepassMaterialViewPipelineCache,
  ]
}

///|
fn SpecializedPrepassMaterialPipelineCache::new() -> SpecializedPrepassMaterialPipelineCache {
  SpecializedPrepassMaterialPipelineCache::{ views: @hashmap.HashMap([]) }
}

///|
let specialized_prepass_material_pipeline_cache_key : @ecs.ResourceKey[
  SpecializedPrepassMaterialPipelineCache,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::SpecializedPrepassMaterialPipelineCache",
)

///|
impl @app.Resource for SpecializedPrepassMaterialPipelineCache with fn resource() {
  specialized_prepass_material_pipeline_cache_key
}

///|
fn SpecializedPrepassMaterialPipelineCache::get(
  self : SpecializedPrepassMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
) -> SpecializedPrepassMaterialViewPipelineCache? {
  self.views.get(view)
}

///|
fn SpecializedPrepassMaterialPipelineCache::view_or_insert(
  self : SpecializedPrepassMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
) -> SpecializedPrepassMaterialViewPipelineCache {
  match self.views.get(view) {
    Some(cache) => cache
    None => {
      let cache = SpecializedPrepassMaterialViewPipelineCache::new()
      self.views.set(view, cache)
      cache
    }
  }
}

///|
fn SpecializedPrepassMaterialPipelineCache::remove(
  self : SpecializedPrepassMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
  entity : @core.Entity,
) -> Unit {
  match self.views.get(view) {
    Some(cache) => cache.remove(entity)
    None => ()
  }
}

///|
fn SpecializedPrepassMaterialPipelineCache::retain_live_views(
  self : SpecializedPrepassMaterialPipelineCache,
  live_views : @hashset.HashSet[@render_view.RetainedViewEntity],
) -> Unit {
  let stale_views : Array[@render_view.RetainedViewEntity] = []
  for view, _cache in self.views {
    if !live_views.contains(view) {
      stale_views.push(view)
    }
  }
  for view in stale_views {
    self.views.remove(view)
  }
}

///|
priv struct ViewKeyPrepassCache {
  keys : @hashmap.HashMap[@render_view.RetainedViewEntity, UInt64]
}

///|
fn ViewKeyPrepassCache::new() -> ViewKeyPrepassCache {
  ViewKeyPrepassCache::{ keys: @hashmap.HashMap([]) }
}

///|
let view_key_prepass_cache_key : @ecs.ResourceKey[ViewKeyPrepassCache] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ViewKeyPrepassCache",
)

///|
impl @app.Resource for ViewKeyPrepassCache with fn resource() {
  view_key_prepass_cache_key
}

///|
priv struct PendingPrepassMeshMaterialQueues {
  queues : @render.PendingQueues
}

///|
fn PendingPrepassMeshMaterialQueues::new() -> PendingPrepassMeshMaterialQueues {
  PendingPrepassMeshMaterialQueues::{
    queues: @render.PendingQueues::PendingQueues(),
  }
}

///|
let pending_prepass_mesh_material_queues_key : @ecs.ResourceKey[
  PendingPrepassMeshMaterialQueues,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::PendingPrepassMeshMaterialQueues",
)

///|
impl @app.Resource for PendingPrepassMeshMaterialQueues with fn resource() {
  pending_prepass_mesh_material_queues_key
}

///|
fn ensure_render3d_prepass_specialization_resources(world : @ecs.World) -> Unit {
  if world.get_resource(SpecializedPrepassMaterialPipelineCache::resource())
    is None {
    world.insert_resource(
      SpecializedPrepassMaterialPipelineCache::resource(),
      SpecializedPrepassMaterialPipelineCache::new(),
    )
  }
  if world.get_resource(ViewKeyPrepassCache::resource()) is None {
    world.insert_resource(
      ViewKeyPrepassCache::resource(),
      ViewKeyPrepassCache::new(),
    )
  }
  if world.get_resource(PendingPrepassMeshMaterialQueues::resource()) is None {
    world.insert_resource(
      PendingPrepassMeshMaterialQueues::resource(),
      PendingPrepassMeshMaterialQueues::new(),
    )
  }
}

///|
fn render3d_prepass_view_key_bits(camera : Camera3dViewPayload) -> UInt64 {
  let mut view_key = mesh_pipeline_key_msaa_bits(
    render3d_camera_msaa_samples(camera),
  )
  if camera.depth_prepass_enabled {
    view_key = view_key | MESH_PIPELINE_KEY_DEPTH_PREPASS
  }
  if camera.normal_prepass_enabled {
    view_key = view_key | MESH_PIPELINE_KEY_NORMAL_PREPASS
  }
  if camera.motion_vector_prepass_enabled {
    view_key = view_key | MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS
  }
  view_key
}

///|
fn render3d_check_prepass_views_need_specialization(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
) -> Unit {
  ensure_render3d_prepass_specialization_resources(world)
  let dirty_specializations = match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(value) => value
    None =>
      abort(
        "Missing DirtySpecializations during prepass view specialization check",
      )
  }
  let view_key_cache = world
    .get_resource(ViewKeyPrepassCache::resource())
    .unwrap()
  for camera in cameras {
    if !camera.payload.camera.is_active {
      continue
    }
    let retained_view_entity = @render_view.RetainedViewEntity::new(
      camera.entity.main_entity,
    )
    let view_key = render3d_prepass_view_key_bits(camera.payload)
    match view_key_cache.keys.get(retained_view_entity) {
      Some(current_key) =>
        if current_key != view_key {
          view_key_cache.keys.set(retained_view_entity, view_key)
          dirty_specializations.insert_view(retained_view_entity)
        }
      None => {
        view_key_cache.keys.set(retained_view_entity, view_key)
        dirty_specializations.insert_view(retained_view_entity)
      }
    }
  }
}

///|
priv struct Render3dPrepassSpecializationWorkItem {
  visible_entity : @core.Entity
  retained_view_entity : @render_view.RetainedViewEntity
  mesh_key_bits : UInt64
  layout : @mesh.MeshVertexBufferLayoutRef
  properties : @material.MaterialProperties
  material_type_tag : String
  draw_function : @material.DrawFunctionId
}

///|
priv struct Render3dPrepassSpecializationOutcome {
  decision : PbrPrepassMaterialSpecializationDecision
  work_item : Render3dPrepassSpecializationWorkItem?
}

///|
fn render3d_prepass_phases_contain_view(
  world : @ecs.World,
  retained_view_entity : @render_view.RetainedViewEntity,
) -> Bool {
  let opaque_prepass = world
    .get_resource(Render3dOpaquePrepassPhases::resource())
    .unwrap()
  let alpha_mask_prepass = world
    .get_resource(Render3dAlphaMaskPrepassPhases::resource())
    .unwrap()
  let opaque_deferred = world
    .get_resource(Render3dOpaqueDeferredPhases::resource())
    .unwrap()
  let alpha_mask_deferred = world
    .get_resource(Render3dAlphaMaskDeferredPhases::resource())
    .unwrap()
  opaque_prepass.phases.contains(retained_view_entity) ||
  alpha_mask_prepass.phases.contains(retained_view_entity) ||
  opaque_deferred.phases.contains(retained_view_entity) ||
  alpha_mask_deferred.phases.contains(retained_view_entity)
}

///|
fn render3d_enqueue_pending_prepass_material(
  queues : @render.ViewPendingQueues,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
) -> Unit {
  queues.push_current(render_entity, visible_entity)
}

///|
fn render3d_prepass_specialization_work_item(
  world : @ecs.World,
  camera : ExtractedCamera3d,
  retained_view_entity : @render_view.RetainedViewEntity,
  render_entity : @core.Entity,
  visible_entity : @render.MainEntity,
  view_key_bits : UInt64,
  view_pending_queues : @render.ViewPendingQueues,
) -> Render3dPrepassSpecializationOutcome? {
  let render_material_instances = world
    .get_resource(ecs_key_render_material_instances)
    .unwrap()
  guard render_material_instances.get(visible_entity.id()) is Some(_) else {
    render3d_enqueue_pending_prepass_material(
      view_pending_queues, render_entity, visible_entity,
    )
    return None
  }
  let render_mesh_instances = world
    .get_resource(RenderMeshInstances::resource())
    .unwrap()
  guard render_mesh_instances.render_mesh_queue_data(visible_entity)
    is Some(mesh_instance) else {
    render3d_enqueue_pending_prepass_material(
      view_pending_queues, render_entity, visible_entity,
    )
    return None
  }
  let material_slots = render_material3d_resolved_slots_or_empty(world)
  guard material_slots.get(visible_entity.id()) is Some(Resolved(material)) else {
    render3d_enqueue_pending_prepass_material(
      view_pending_queues, render_entity, visible_entity,
    )
    return None
  }
  guard world.get_resource(@render_mesh.RenderMeshAssets::resource())
    is Some(render_meshes) else {
    return None
  }
  guard render_meshes.get(mesh_instance.mesh_asset_id()) is Some(render_mesh) else {
    return None
  }
  let properties = material.material_properties()
  let emulate_unclipped_depth = !pbr_prepass_depth_clip_control_supported(world) &&
    (
      (
        view_key_bits |
        render_mesh.key_bits().bits() |
        properties.mesh_pipeline_key_bits.bits()
      ) &
      MESH_PIPELINE_KEY_UNCLIPPED_DEPTH_ORTHO
    ) !=
    0UL
  let decision = pbr_prepass_material_specialization_decision(
    properties,
    render_mesh.key_bits().bits(),
    view_key_bits,
    msaa_samples=render3d_camera_msaa_samples(camera.payload),
    has_deferred_prepass=camera.payload.deferred_prepass_enabled,
    lightmapped=render3d_material_specialization_lightmapped(
      world,
      visible_entity.id(),
    ),
    lightmap_bicubic_sampling=render3d_material_specialization_lightmap_bicubic_sampling(
      world,
      visible_entity.id(),
    ),
    visibility_range_dither=render3d_material_specialization_visibility_range_dither(
      world,
      visible_entity.id(),
    ),
    has_previous_skin=mesh_instance
      .flags()
      .contains(RenderMeshInstanceFlags::has_previous_skin()) &&
      camera.payload.motion_vector_prepass_enabled,
    has_previous_morph=mesh_instance
      .flags()
      .contains(RenderMeshInstanceFlags::has_previous_morph()) &&
      camera.payload.motion_vector_prepass_enabled,
    emulate_unclipped_depth~,
  )
  match decision {
    Queue(plan) => {
      let work_item = Render3dPrepassSpecializationWorkItem::{
        visible_entity: visible_entity.id(),
        retained_view_entity,
        mesh_key_bits: plan.mesh_key_bits(),
        layout: render_mesh.layout(),
        properties,
        material_type_tag: material.material_type_tag(),
        draw_function: plan.draw_function(),
      }
      Some(Render3dPrepassSpecializationOutcome::{
        decision,
        work_item: Some(work_item),
      })
    }
    _ =>
      Some(Render3dPrepassSpecializationOutcome::{ decision, work_item: None })
  }
}

///|
fn render3d_specialize_prepass_work_item(
  world : @ecs.World,
  item : Render3dPrepassSpecializationWorkItem,
  specialization_tick : @core.Tick,
) -> Unit {
  guard item.properties.prepass_specialize is Some(prepass_specialize) else {
    return
  }
  let key = @material.ErasedMaterialPipelineKey::new(
    @material.ErasedMeshPipelineKey::new(item.mesh_key_bits, "MeshPipelineKey"),
    item.properties.material_key,
    item.material_type_tag,
  )
  let pipeline_id = @material.material_specialize_prepass(
    prepass_specialize,
    world,
    key,
    item.layout,
    item.properties,
  ) catch {
    err => {
      @app.log_error(
        "Failed to specialize PBR prepass material pipeline for entity \{item.visible_entity.id}: \{err}",
      )
      return
    }
  }
  let cache = world
    .get_resource(SpecializedPrepassMaterialPipelineCache::resource())
    .unwrap()
  cache
  .view_or_insert(item.retained_view_entity)
  .insert(
    item.visible_entity,
    specialization_tick,
    pipeline_id,
    item.draw_function,
  )
}

///|
fn render3d_specialize_prepass_material_meshes(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
) -> Unit {
  ensure_render3d_prepass_specialization_resources(world)
  let work_items : Array[Render3dPrepassSpecializationWorkItem] = []
  let removals : Array[(@render_view.RetainedViewEntity, @core.Entity)] = []
  let all_views : @hashset.HashSet[@render_view.RetainedViewEntity] = @hashset.HashSet([],
  )
  let dirty_specializations = world
    .get_resource(@render_visibility.DirtySpecializations::resource())
    .unwrap()
  let view_key_cache = world
    .get_resource(ViewKeyPrepassCache::resource())
    .unwrap()
  let specialized_cache = world
    .get_resource(SpecializedPrepassMaterialPipelineCache::resource())
    .unwrap()
  let pending_queues = world
    .get_resource(PendingPrepassMeshMaterialQueues::resource())
    .unwrap()
  for camera in cameras {
    let retained_view_entity = @render_view.RetainedViewEntity::new(
      camera.entity.main_entity,
    )
    if !render3d_prepass_phases_contain_view(world, retained_view_entity) {
      continue
    }
    guard view_key_cache.keys.get(retained_view_entity) is Some(view_key_bits) else {
      continue
    }
    all_views.add(retained_view_entity)
    guard (try! world.get_by_key(
        camera.entity.render_entity,
        @render_visibility.ecs_key_render_visible_entities,
      ))
      is Some(visible_entities) else {
      continue
    }
    guard visible_entities.get(render3d_mesh_visibility_class())
      is Some(render_visible_mesh_entities) else {
      continue
    }
    let view_pending_queues = pending_queues.queues.prepare_for_new_frame(
      retained_view_entity,
    )
    match specialized_cache.get(retained_view_entity) {
      Some(view_cache) =>
        if dirty_specializations.must_wipe_specializations_for_view(
            retained_view_entity,
          ) {
          view_cache.clear()
        } else {
          for entity in dirty_specializations.iter_to_despecialize() {
            view_cache.remove(entity.id())
          }
        }
      None => ()
    }
    let candidates = dirty_specializations.iter_to_specialize(
      retained_view_entity,
      render_visible_mesh_entities,
      view_pending_queues.prev_frame(),
    )
    for candidate in candidates {
      let (render_entity, visible_entity) = candidate
      if specialized_cache
        .get(retained_view_entity)
        .map(fn(cache) { cache.contains(visible_entity.id()) })
        .unwrap_or(false) {
        continue
      }
      match
        render3d_prepass_specialization_work_item(
          world, camera, retained_view_entity, render_entity, visible_entity, view_key_bits,
          view_pending_queues,
        ) {
        Some(outcome) => {
          if outcome.decision is Remove {
            removals.push((retained_view_entity, visible_entity.id()))
          }
          match outcome.work_item {
            Some(work_item) => work_items.push(work_item)
            None => ()
          }
        }
        _ => ()
      }
    }
  }
  pending_queues.queues.expire_stale_views(all_views)
  let specialization_tick = world.read_change_tick()
  for item in work_items {
    render3d_specialize_prepass_work_item(world, item, specialization_tick)
  }
  for removal in removals {
    specialized_cache.remove(removal.0, removal.1)
  }
  specialized_cache.retain_live_views(all_views)
}
