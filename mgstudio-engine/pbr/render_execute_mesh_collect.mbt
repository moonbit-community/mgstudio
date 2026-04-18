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
fn render3d_mesh_entity_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
priv struct Render3dExtractedMeshCache {
  mut initialized : Bool
  by_entity : Map[UInt64, ExtractedMesh3d]
  reextract_next_frame : Map[UInt64, @core.Entity]
}

///|
fn render3d_extracted_mesh_cache_default() -> Render3dExtractedMeshCache {
  Render3dExtractedMeshCache::{
    initialized: false,
    by_entity: {},
    reextract_next_frame: {},
  }
}

///|
let render3d_extracted_mesh_cache_key : @ecs.ResourceKey[
  Render3dExtractedMeshCache,
] = @ecs.register_resource(debug_name="mgstudio.render3d.extracted_mesh_cache")

///|
impl @app.Resource for Render3dExtractedMeshCache with resource() {
  render3d_extracted_mesh_cache_key
}

///|
fn ensure_render3d_extracted_mesh_cache(world : @ecs.World) -> Unit {
  if (try! world.get_resource(Render3dExtractedMeshCache::resource())) is None {
    world.insert_resource(
      Render3dExtractedMeshCache::resource(),
      render3d_extracted_mesh_cache_default(),
    )
  }
}

///|
fn render3d_extracted_mesh_cache_ref_or_abort(
  world : @ecs.World,
) -> Ref[Render3dExtractedMeshCache] {
  ensure_render3d_extracted_mesh_cache(world)
  match
    (try! world.get_resource_ref_mut(Render3dExtractedMeshCache::resource())) {
    Some(cache_ref) => cache_ref
    None => abort("Missing Render3dExtractedMeshCache resource in render world")
  }
}

///|
fn render3d_add_mesh_candidate(
  candidates : Map[UInt64, @core.Entity],
  entity : @core.Entity,
) -> Unit {
  candidates.set(render3d_mesh_entity_key(entity), entity)
}

///|
fn render3d_add_mesh_candidate_if_cached(
  cache : Render3dExtractedMeshCache,
  candidates : Map[UInt64, @core.Entity],
  entity : @core.Entity,
) -> Unit {
  let key = render3d_mesh_entity_key(entity)
  if cache.by_entity.contains(key) {
    candidates.set(key, entity)
  }
}

///|
fn[T] render3d_collect_component_delta_entities(
  source_world : @ecs.World,
  sequence : @core.SystemSequence,
  component_key : @ecs.ComponentKey[T],
  candidates : Map[UInt64, @core.Entity],
) -> Unit {
  for entity in source_world.added_components(component_key, sequence).read() {
    render3d_add_mesh_candidate(candidates, entity)
  }
  for entity in source_world.changed_components(component_key, sequence).read() {
    render3d_add_mesh_candidate(candidates, entity)
  }
  for entity in source_world.removed_components(component_key, sequence).read() {
    render3d_add_mesh_candidate(candidates, entity)
  }
}

///|
fn[T] render3d_collect_component_delta_entities_if_cached(
  source_world : @ecs.World,
  sequence : @core.SystemSequence,
  component_key : @ecs.ComponentKey[T],
  cache : Render3dExtractedMeshCache,
  candidates : Map[UInt64, @core.Entity],
) -> Unit {
  for entity in source_world.added_components(component_key, sequence).read() {
    render3d_add_mesh_candidate_if_cached(cache, candidates, entity)
  }
  for entity in source_world.changed_components(component_key, sequence).read() {
    render3d_add_mesh_candidate_if_cached(cache, candidates, entity)
  }
  for entity in source_world.removed_components(component_key, sequence).read() {
    render3d_add_mesh_candidate_if_cached(cache, candidates, entity)
  }
}

///|
fn render3d_resolve_standard_material(
  material_handle : MeshMaterial3d,
  standard_material_frame_cache : Map[Int, StandardMaterial],
) -> StandardMaterial? {
  let material_handle_id = material_handle.material.id()
  match standard_material_frame_cache.get(material_handle_id) {
    Some(cached_material) => Some(cached_material)
    None =>
      match standard_material_get(material_handle.material) {
        Some(loaded_material) => {
          standard_material_frame_cache.set(material_handle_id, loaded_material)
          Some(loaded_material)
        }
        None => None
      }
  }
}

///|
fn render3d_extract_mesh_for_entity(
  source_world : @ecs.World,
  entity : @core.Entity,
  mesh_runtime_state_ref : Ref[@pbr_render.Render3dMeshRuntimeState],
  morph_indices_ref : Ref[@pbr_render.MorphIndices],
  skin_uniforms_ref : Ref[@pbr_render.SkinUniforms],
  world_transform_cache_ref : Ref[@pbr_render.Render3dWorldTransformCache],
  standard_material_frame_cache : Map[Int, StandardMaterial],
  needs_mesh_previous_transform : Bool,
  has_render_layers_components : Bool,
  has_visibility_range_components : Bool,
  has_lightmap_components : Bool,
  has_forward_decal_components : Bool,
  has_forward_decal_material_ext_components : Bool,
  has_clustered_decal_components : Bool,
  has_not_shadow_caster_components : Bool,
  has_no_frustum_culling_components : Bool,
  has_no_cpu_culling_components : Bool,
  has_not_shadow_receiver_components : Bool,
  has_transmitted_shadow_receiver_components : Bool,
  has_wireframe_components : Bool,
  has_no_wireframe_components : Bool,
  has_wireframe_color_components : Bool,
) -> (ExtractedMesh3d?, Bool) {
  guard source_world.is_alive(entity) else { return (None, false) }
  let mesh3d = match (try! source_world.get_by_key(entity, ecs_key_mesh3d)) {
    Some(v) => v
    None => return (None, false)
  }
  let material_handle = match
    (try! source_world.get_by_key(entity, ecs_key_mesh_material3d)) {
    Some(v) => v
    None => return (None, false)
  }
  let view_visibility = match
    (try! source_world.get_by_key(entity, @visibility.ecs_key_view_visibility)) {
    Some(v) => v
    None => return (None, false)
  }
  if !view_visibility.is_visible() {
    return (None, false)
  }
  let local_transform = match
    (try! source_world.get_by_key(entity, @transform.ecs_key_transform)) {
    Some(v) => v
    None => return (None, false)
  }
  let base_material = match
    render3d_resolve_standard_material(
      material_handle, standard_material_frame_cache,
    ) {
    Some(v) => v
    None => return (None, true)
  }
  let material = @pbr_render.render3d_apply_extended_material_metadata(
    base_material,
    material_handle.extended_material,
  )
  let layers = if has_render_layers_components {
    match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_render_layers)) {
      Some(v) => v
      None => @sprite.RenderLayers::default()
    }
  } else {
    @sprite.RenderLayers::default()
  }
  let transform = @pbr_render.render3d_entity_world_transform_from_components(
    source_world, entity, local_transform, world_transform_cache_ref,
  )
  let previous_global_transform = if needs_mesh_previous_transform {
    try! source_world.get_by_key(entity, ecs_key_previous_global_transform)
  } else {
    None
  }
  let entity_key = render3d_mesh_entity_key(entity)
  let has_previous_skin = skin_uniforms_ref.val.previous_skins.contains(
    entity_key,
  )
  let has_previous_morph = morph_indices_ref.val.prev.get(entity_key) is Some(_)
  let motion_vector_enabled = if needs_mesh_previous_transform {
    let supports_motion = match
      render3d_mesh_draw_alpha(material.alpha_mode, material.base_color.a) {
      Some(alpha) => alpha >= 0.999F
      None => false
    }
    supports_motion &&
    (
      previous_global_transform is Some(_) ||
      has_previous_skin ||
      has_previous_morph
    )
  } else {
    false
  }
  let previous_transform = match previous_global_transform {
    Some(v) => v.transform()
    None => transform
  }
  let visibility_range = if has_visibility_range_components {
    try! source_world.get_by_key(entity, @visibility.ecs_key_visibility_range)
  } else {
    None
  }
  let aabb_center_world = if visibility_range is Some(range) && range.use_aabb {
    match render3d_mesh_local_aabb_center(mesh3d) {
      Some(local_center) =>
        Some(@pbr_render.render3d_transform_point(transform, local_center))
      None => None
    }
  } else {
    None
  }
  let (skinning_key_hi, _skinning_key_lo) = @pbr_render.render3d_prepared_skin_binding_keys(
    skin_uniforms_ref, entity,
  )
  let mesh_topology_kind = render3d_mesh_topology_kind(mesh3d.mesh())
  let mesh_preprocess_static = render3d_mesh_preprocess_static_cached(
    mesh3d.mesh(),
    mesh_runtime_state_ref.val.mesh_preprocess_static_cache,
  )
  let mesh_id = @pbr_render.render3d_upload_mesh_handle_cached(
    mesh_runtime_state_ref,
    mesh3d.mesh(),
  )
  let lightmap = if has_lightmap_components {
    try! source_world.get_by_key(entity, ecs_key_lightmap)
  } else {
    None
  }
  let is_forward_decal = if has_forward_decal_components {
    (try! source_world.get_by_key(entity, ecs_key_forward_decal)) is Some(_)
  } else {
    false
  }
  let forward_decal_material_ext = if has_forward_decal_material_ext_components {
    try! source_world.get_by_key(entity, ecs_key_forward_decal_material_ext)
  } else {
    None
  }
  let clustered_decal = if has_clustered_decal_components {
    try! source_world.get_by_key(entity, ecs_key_clustered_decal)
  } else {
    None
  }
  let has_not_shadow_caster = if has_not_shadow_caster_components {
    (try! source_world.get_by_key(entity, ecs_key_not_shadow_caster)) is Some(_)
  } else {
    false
  }
  let has_no_frustum_culling = if has_no_frustum_culling_components {
    (try! source_world.get_by_key(
      entity, @visibility.ecs_key_no_frustum_culling,
    ))
    is Some(_)
  } else {
    false
  }
  let has_no_cpu_culling = if has_no_cpu_culling_components {
    (try! source_world.get_by_key(entity, @visibility.ecs_key_no_cpu_culling))
    is Some(_)
  } else {
    false
  }
  let has_not_shadow_receiver = if has_not_shadow_receiver_components {
    (try! source_world.get_by_key(entity, ecs_key_not_shadow_receiver))
    is Some(_)
  } else {
    false
  }
  let has_transmitted_shadow_receiver = if has_transmitted_shadow_receiver_components {
    (try! source_world.get_by_key(entity, ecs_key_transmitted_shadow_receiver))
    is Some(_)
  } else {
    false
  }
  let has_wireframe = if has_wireframe_components {
    (try! source_world.get_by_key(entity, ecs_key_wireframe)) is Some(_)
  } else {
    false
  }
  let has_no_wireframe = if has_no_wireframe_components {
    (try! source_world.get_by_key(entity, ecs_key_no_wireframe)) is Some(_)
  } else {
    false
  }
  let wireframe_color = if has_wireframe_color_components {
    try! source_world.get_by_key(entity, ecs_key_wireframe_color)
  } else {
    None
  }
  (
    Some(ExtractedMesh3d::{
      entity: phase_entity_ref3d_for_world_main(source_world, entity),
      payload: Mesh3dExtractedPayload::{
        mesh_handle: mesh3d.mesh(),
        mesh_id,
        mesh_topology_kind,
        mesh_is_indexed: mesh_preprocess_static.is_indexed,
        mesh_preprocess_static: Some(mesh_preprocess_static),
        transform,
        previous_transform,
        visibility_range,
        aabb_center_world,
        material,
        material_extension: material_handle.extended_material,
        lightmap,
        is_forward_decal,
        forward_decal_material_ext,
        clustered_decal,
        has_not_shadow_caster,
        has_not_shadow_receiver,
        has_transmitted_shadow_receiver,
        has_no_frustum_culling,
        has_no_cpu_culling,
        layers,
        has_wireframe,
        has_no_wireframe,
        wireframe_color,
        skinning_key_hi,
        has_previous_skin,
        motion_vector_enabled,
      },
    }),
    false,
  )
}

///|
fn render3d_execute_collect_meshes(
  world : @ecs.World,
  source_world : @ecs.World,
  mesh_runtime_state_ref : Ref[@pbr_render.Render3dMeshRuntimeState],
  morph_indices_ref : Ref[@pbr_render.MorphIndices],
  skin_uniforms_ref : Ref[@pbr_render.SkinUniforms],
  world_transform_cache_ref : Ref[@pbr_render.Render3dWorldTransformCache],
  needs_mesh_previous_transform : Bool,
) -> Array[ExtractedMesh3d] {
  let trace_collect_meshes_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_meshes",
  )
  let standard_material_frame_cache : Map[Int, StandardMaterial] = {}
  let mesh_cache_ref = render3d_extracted_mesh_cache_ref_or_abort(world)
  let sequence = source_world.get_sequence_context().sequence()
  let has_render_layers_components = source_world.component_count(
      @sprite.ecs_key_render_layers,
    ) >
    0
  let has_visibility_range_components = source_world.component_count(
      @visibility.ecs_key_visibility_range,
    ) >
    0
  let has_lightmap_components = source_world.component_count(ecs_key_lightmap) >
    0
  let has_forward_decal_components = source_world.component_count(
      ecs_key_forward_decal,
    ) >
    0
  let has_forward_decal_material_ext_components = source_world.component_count(
      ecs_key_forward_decal_material_ext,
    ) >
    0
  let has_clustered_decal_components = source_world.component_count(
      ecs_key_clustered_decal,
    ) >
    0
  let has_not_shadow_caster_components = source_world.component_count(
      ecs_key_not_shadow_caster,
    ) >
    0
  let has_no_frustum_culling_components = source_world.component_count(
      @visibility.ecs_key_no_frustum_culling,
    ) >
    0
  let has_no_cpu_culling_components = source_world.component_count(
      @visibility.ecs_key_no_cpu_culling,
    ) >
    0
  let has_not_shadow_receiver_components = source_world.component_count(
      ecs_key_not_shadow_receiver,
    ) >
    0
  let has_transmitted_shadow_receiver_components = source_world.component_count(
      ecs_key_transmitted_shadow_receiver,
    ) >
    0
  let has_wireframe_components = source_world.component_count(ecs_key_wireframe) >
    0
  let has_no_wireframe_components = source_world.component_count(
      ecs_key_no_wireframe,
    ) >
    0
  let has_wireframe_color_components = source_world.component_count(
      ecs_key_wireframe_color,
    ) >
    0

  if !mesh_cache_ref.val.initialized {
    mesh_cache_ref.val.by_entity.clear()
    mesh_cache_ref.val.reextract_next_frame.clear()
    source_world.for_each_component(ecs_key_mesh3d, fn(entity, _mesh3d) {
      let entity_key = render3d_mesh_entity_key(entity)
      let (next_mesh, needs_reextract_next_frame) = render3d_extract_mesh_for_entity(
        source_world, entity, mesh_runtime_state_ref, morph_indices_ref, skin_uniforms_ref,
        world_transform_cache_ref, standard_material_frame_cache, needs_mesh_previous_transform,
        has_render_layers_components, has_visibility_range_components, has_lightmap_components,
        has_forward_decal_components, has_forward_decal_material_ext_components,
        has_clustered_decal_components, has_not_shadow_caster_components, has_no_frustum_culling_components,
        has_no_cpu_culling_components, has_not_shadow_receiver_components, has_transmitted_shadow_receiver_components,
        has_wireframe_components, has_no_wireframe_components, has_wireframe_color_components,
      )
      match next_mesh {
        Some(extracted_mesh) =>
          mesh_cache_ref.val.by_entity.set(entity_key, extracted_mesh)
        None => mesh_cache_ref.val.by_entity.remove(entity_key)
      }
      if needs_reextract_next_frame {
        mesh_cache_ref.val.reextract_next_frame.set(entity_key, entity)
      }
    })
    mesh_cache_ref.val.initialized = true
  } else {
    let candidates : Map[UInt64, @core.Entity] = {}
    for entry in mesh_cache_ref.val.reextract_next_frame.iter() {
      let (_entity_key, entity) = entry
      render3d_add_mesh_candidate(candidates, entity)
    }
    mesh_cache_ref.val.reextract_next_frame.clear()
    render3d_collect_component_delta_entities(
      source_world, sequence, ecs_key_mesh3d, candidates,
    )
    render3d_collect_component_delta_entities(
      source_world, sequence, ecs_key_mesh_material3d, candidates,
    )
    render3d_collect_component_delta_entities(
      source_world, sequence, @visibility.ecs_key_view_visibility, candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      @transform.ecs_key_transform,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      @transform.ecs_key_global_transform,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_previous_global_transform,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      @mesh.ecs_key_skinned_mesh,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      @sprite.ecs_key_render_layers,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      @visibility.ecs_key_visibility_range,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_lightmap,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_forward_decal,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_forward_decal_material_ext,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_clustered_decal,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_not_shadow_caster,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      @visibility.ecs_key_no_frustum_culling,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      @visibility.ecs_key_no_cpu_culling,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_not_shadow_receiver,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_transmitted_shadow_receiver,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_wireframe,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_no_wireframe,
      mesh_cache_ref.val,
      candidates,
    )
    render3d_collect_component_delta_entities_if_cached(
      source_world,
      sequence,
      ecs_key_wireframe_color,
      mesh_cache_ref.val,
      candidates,
    )
    for entry in candidates.iter() {
      let (_entity_key, entity) = entry
      let entity_key = render3d_mesh_entity_key(entity)
      let (next_mesh, needs_reextract_next_frame) = render3d_extract_mesh_for_entity(
        source_world, entity, mesh_runtime_state_ref, morph_indices_ref, skin_uniforms_ref,
        world_transform_cache_ref, standard_material_frame_cache, needs_mesh_previous_transform,
        has_render_layers_components, has_visibility_range_components, has_lightmap_components,
        has_forward_decal_components, has_forward_decal_material_ext_components,
        has_clustered_decal_components, has_not_shadow_caster_components, has_no_frustum_culling_components,
        has_no_cpu_culling_components, has_not_shadow_receiver_components, has_transmitted_shadow_receiver_components,
        has_wireframe_components, has_no_wireframe_components, has_wireframe_color_components,
      )
      match next_mesh {
        Some(extracted_mesh) =>
          mesh_cache_ref.val.by_entity.set(entity_key, extracted_mesh)
        None => mesh_cache_ref.val.by_entity.remove(entity_key)
      }
      if needs_reextract_next_frame {
        mesh_cache_ref.val.reextract_next_frame.set(entity_key, entity)
      }
    }
  }

  let meshes : Array[ExtractedMesh3d] = []
  for entry in mesh_cache_ref.val.by_entity.iter() {
    let (_entity_key, extracted_mesh) = entry
    meshes.push(extracted_mesh)
  }
  ignore(needs_mesh_previous_transform)
  @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(
    world,
    meshes.length(),
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_meshes",
    trace_collect_meshes_start_us,
  )
  render3d_update_mesh_preprocess_static_cache(
    mesh_runtime_state_ref.val.mesh_preprocess_static_cache,
    meshes,
  )
  meshes
}

///|
fn render3d_mesh_topology_kind(mesh_handle : @asset.Handle[@mesh.Mesh]) -> Int {
  match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) =>
      match mesh_asset.as_3d_geometry() {
        Some(geometry) => geometry.primitive_topology().to_int()
        None => 0
      }
    None => 0
  }
}
