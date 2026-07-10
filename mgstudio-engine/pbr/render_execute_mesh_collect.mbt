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
fn render3d_resolve_standard_material(
  material_handle : MeshMaterial3d,
  standard_material_frame_cache : Map[Int, StandardMaterial],
) -> StandardMaterial? {
  if !material_handle.is_standard_material() {
    return None
  }
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
fn render3d_resolve_forward_decal_material(
  material_handle : MeshMaterial3d,
) -> @pbr_decal.ForwardDecalMaterial? {
  if !(material_handle.material_family
    is @material.Material3dFamily::ForwardDecal) {
    return None
  }
  @pbr_decal.forward_decal_material_get(
    @asset.Handle::new(material_handle.material.id()),
  )
}

///|
priv struct Render3dResolvedMeshMaterial {
  material_draw_data : MaterialDrawData3d
  material_extension : ExtendedMaterialMetadata3d?
  material_properties : @material.MaterialProperties
  material_bind_group_data : @render_resource.MaterialBindGroupResolvedData
  forward_decal_material_ext : ForwardDecalMaterialExt?
}

///|
priv struct Render3dPrepareMeshesCounters {
  mut prepared_meshes : Int
  mut buffer_uploads : Int
  mut skipped_unchanged_meshes : Int
  mut mesh_upload_cache_hits : Int
  mut mesh_upload_cache_misses : Int
}

///|
fn Render3dPrepareMeshesCounters::Render3dPrepareMeshesCounters() -> Render3dPrepareMeshesCounters {
  {
    prepared_meshes: 0,
    buffer_uploads: 0,
    skipped_unchanged_meshes: 0,
    mesh_upload_cache_hits: 0,
    mesh_upload_cache_misses: 0,
  }
}

///|
fn render3d_prepare_meshes_emit_counters(
  counters : Render3dPrepareMeshesCounters,
) -> Unit {
  @app.timeline_trace_emit_counter_int(
    "render_3d_prepare_meshes.prepared_meshes",
    counters.prepared_meshes,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_prepare_meshes.buffer_uploads",
    counters.buffer_uploads,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_prepare_meshes.skipped_unchanged_meshes",
    counters.skipped_unchanged_meshes,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_prepare_meshes.mesh_upload_cache_hits",
    counters.mesh_upload_cache_hits,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_prepare_meshes.mesh_upload_cache_misses",
    counters.mesh_upload_cache_misses,
  )
}

///|
fn render3d_prepare_extracted_mesh_backend_uploads(
  mesh_runtime_state_value : @pbr_render.Render3dMeshRuntimeState,
  meshes : Array[ExtractedMesh3d],
  counters : Render3dPrepareMeshesCounters,
) -> Unit {
  // Bevy's extraction systems populate render-world mesh instance data; GPU
  // asset preparation is a separate render-asset owner. Mgstudio still has a
  // legacy host mesh id consumed by the draw backend, so backfill it after
  // extraction instead of owning host uploads inside per-entity extraction.
  for mesh in meshes {
    let mesh_handle = mesh.payload.mesh_handle
    let mesh_upload_cache_hit = @pbr_render.render3d_mesh_upload_cache_has_valid(
      mesh_runtime_state_value, mesh_handle,
    )
    if mesh_upload_cache_hit {
      counters.mesh_upload_cache_hits = counters.mesh_upload_cache_hits + 1
      counters.skipped_unchanged_meshes = counters.skipped_unchanged_meshes + 1
    } else {
      counters.mesh_upload_cache_misses = counters.mesh_upload_cache_misses + 1
      counters.buffer_uploads = counters.buffer_uploads + 1
    }
    ignore(
      @pbr_render.render3d_upload_mesh_handle_cached(
        mesh_runtime_state_value, mesh_handle,
      ),
    )
  }
}

///|
fn render3d_resolve_mesh_material(
  material_handle : MeshMaterial3d,
  standard_material_frame_cache : Map[Int, StandardMaterial],
  resolved_material_frame_cache : Map[Int, Render3dResolvedMeshMaterial],
  default_opaque_renderer_method : OpaqueRendererMethod,
  material_prepass_enabled : Bool,
  standard_material_texture_features : StandardMaterialTextureFeatureSet,
) -> Render3dResolvedMeshMaterial? {
  // Mirrors Bevy's render-material cache shape: the common non-extended
  // material path is resolved once per frame and reused by all mesh instances.
  let material_handle_id = material_handle.material.id()
  if material_handle.extended_material is None {
    match resolved_material_frame_cache.get(material_handle_id) {
      Some(cached) => return Some(cached)
      None => ()
    }
  }
  let (base_material, material_extension, forward_decal_material_ext) = match
    material_handle.material_family {
    @material.Material3dFamily::Standard => {
      let base_material = match
        render3d_resolve_standard_material(
          material_handle, standard_material_frame_cache,
        ) {
        Some(v) => v
        None => return None
      }
      (base_material, material_handle.extended_material, None)
    }
    @material.Material3dFamily::ForwardDecal => {
      let forward_decal_material = match
        render3d_resolve_forward_decal_material(material_handle) {
        Some(v) => v
        None => return None
      }
      let ext = forward_decal_material.extension()
      (
        forward_decal_material.base(),
        Some(forward_decal_material_extension_metadata(ext)),
        Some(ext),
      )
    }
    @material.Material3dFamily::MeshletDebug => return None
  }
  let material = @pbr_render.render3d_apply_extended_material_metadata(
    base_material, material_extension,
  )
  let material_properties = render3d_material_properties_for_standard_material(
    material,
    material_extension,
    default_opaque_renderer_method,
    material_prepass_enabled,
    standard_material_texture_features~,
  )
  let resolved = Render3dResolvedMeshMaterial::{
    material_draw_data: MaterialDrawData3d::Standard(material),
    material_extension,
    material_properties,
    material_bind_group_data: @pbr_render.render3d_resolve_material_extension_bind_group_data(
      material_extension,
    ),
    forward_decal_material_ext,
  }
  if material_handle.material_family is @material.Material3dFamily::Standard &&
    material_handle.extended_material is None {
    resolved_material_frame_cache.set(material_handle_id, resolved)
  }
  Some(resolved)
}

///|
priv struct Render3dExtractMeshRequiredComponents {
  mesh3d : @mesh.Mesh3d
  material_handle : MeshMaterial3d?
  view_visibility : @visibility.ViewVisibility
  global_transform : @transform.GlobalTransform
  previous_global_transform : @pbr_prepass.PreviousGlobalTransform?
  aabb : @camera_primitives.Aabb?
  layers : @camera_render_layers.RenderLayers?
  lightmap : Lightmap?
  is_forward_decal : Bool
  forward_decal_material_ext : ForwardDecalMaterialExt?
  clustered_decal : ClusteredDecal?
  has_not_shadow_caster : Bool
  has_no_frustum_culling : Bool
  has_no_automatic_batching : Bool
  has_no_cpu_culling : Bool
  has_not_shadow_receiver : Bool
  has_transmitted_shadow_receiver : Bool
  has_no_wireframe : Bool
  mesh3d_wireframe : Mesh3dWireframe?
  wireframe_color : WireframeColor?
  wireframe_line_width : WireframeLineWidth?
  wireframe_topology : WireframeTopology?
}

///|
fn render3d_extract_wireframe_material(
  source_world : @ecs.World,
  mesh3d_wireframe : Mesh3dWireframe?,
) -> RenderWireframeMaterial? {
  guard mesh3d_wireframe is Some(component) else { return None }
  let key : @ecs.ResourceKey[@asset.Assets[WireframeMaterial]] = @asset.assets_resource_key()
  guard source_world.get_resource(key) is Some(assets) else { return None }
  match assets.get(component.material()) {
    Some(material) => Some(RenderWireframeMaterial::from_material(material))
    None => None
  }
}

///|
fn render3d_extract_mesh_for_entity(
  render_world : @ecs.World,
  source_world : @ecs.World,
  entity : @core.Entity,
  mesh_runtime_state_value : @pbr_render.Render3dMeshRuntimeState,
  morph_indices_value : @pbr_render.MorphIndices,
  skin_uniforms_value : @pbr_render.SkinUniforms,
  world_transform_cache_value : @pbr_render.Render3dWorldTransformCache,
  standard_material_frame_cache : Map[Int, StandardMaterial],
  resolved_material_frame_cache : Map[Int, Render3dResolvedMeshMaterial],
  needs_mesh_previous_transform : Bool,
  default_opaque_renderer_method : OpaqueRendererMethod,
  material_prepass_enabled : Bool,
  standard_material_texture_features : StandardMaterialTextureFeatureSet,
  required_components : Render3dExtractMeshRequiredComponents?,
  counters : Render3dPrepareMeshesCounters,
) -> (ExtractedMesh3d?, Bool) {
  guard source_world.is_alive(entity) else { return (None, false) }
  let (
    mesh3d,
    material_handle,
    view_visibility,
    global_transform,
    prefetched_previous_global_transform,
    prefetched_aabb,
    prefetched_layers,
    prefetched_lightmap,
    prefetched_is_forward_decal,
    prefetched_forward_decal_material_ext,
    prefetched_clustered_decal,
    prefetched_has_not_shadow_caster,
    prefetched_has_no_frustum_culling,
    _prefetched_has_no_automatic_batching,
    prefetched_has_no_cpu_culling,
    prefetched_has_not_shadow_receiver,
    prefetched_has_transmitted_shadow_receiver,
    prefetched_has_no_wireframe,
    prefetched_mesh3d_wireframe,
    prefetched_wireframe_color,
    prefetched_wireframe_line_width,
    prefetched_wireframe_topology,
  ) = match required_components {
    Some(components) =>
      (
        components.mesh3d,
        components.material_handle,
        components.view_visibility,
        components.global_transform,
        components.previous_global_transform,
        components.aabb,
        components.layers,
        components.lightmap,
        components.is_forward_decal,
        components.forward_decal_material_ext,
        components.clustered_decal,
        components.has_not_shadow_caster,
        components.has_no_frustum_culling,
        components.has_no_automatic_batching,
        components.has_no_cpu_culling,
        components.has_not_shadow_receiver,
        components.has_transmitted_shadow_receiver,
        components.has_no_wireframe,
        components.mesh3d_wireframe,
        components.wireframe_color,
        components.wireframe_line_width,
        components.wireframe_topology,
      )
    None => {
      let mesh3d = match
        (try! source_world.get_by_key(entity, ecs_key_mesh3d)) {
        Some(v) => v
        None => return (None, false)
      }
      let material_handle = try! source_world.get_by_key(
        entity, ecs_key_mesh_material3d,
      )
      let view_visibility = match
        (try! source_world.get_by_key(
          entity, @visibility.ecs_key_view_visibility,
        )) {
        Some(v) => v
        None => return (None, false)
      }
      let global_transform = match
        (try! source_world.get_by_key(
          entity, @transform.ecs_key_global_transform,
        )) {
        Some(v) => v
        None => {
          let local_transform = match
            (try! source_world.get_by_key(entity, @transform.ecs_key_transform)) {
            Some(v) => v
            None => return (None, false)
          }
          @transform.GlobalTransform::from_transform(
            @pbr_render.render3d_entity_world_transform_from_components(
              source_world, entity, local_transform, world_transform_cache_value,
            ),
          )
        }
      }
      let previous_global_transform = if needs_mesh_previous_transform {
        try! source_world.get_by_key(entity, ecs_key_previous_global_transform)
      } else {
        None
      }
      let aabb = try! source_world.get_by_key(
        entity, @camera_primitives.ecs_key_aabb,
      )
      let layers = try! source_world.get_by_key(
        entity, @camera_render_layers.ecs_key_render_layers,
      )
      let lightmap = try! source_world.get_by_key(entity, ecs_key_lightmap)
      let is_forward_decal = (try! source_world.get_by_key(
          entity, ecs_key_forward_decal,
        ))
        is Some(_)
      let forward_decal_material_ext = try! source_world.get_by_key(
        entity, ecs_key_forward_decal_material_ext,
      )
      let clustered_decal = try! source_world.get_by_key(
        entity, ecs_key_clustered_decal,
      )
      let has_not_shadow_caster = (try! source_world.get_by_key(
          entity, ecs_key_not_shadow_caster,
        ))
        is Some(_)
      let has_no_frustum_culling = (try! source_world.get_by_key(
          entity, @visibility.ecs_key_no_frustum_culling,
        ))
        is Some(_)
      let has_no_automatic_batching = (try! source_world.get_by_key(
          entity,
          @render_batching.NoAutomaticBatching::component(),
        ))
        is Some(_)
      let has_no_cpu_culling = (try! source_world.get_by_key(
          entity, @visibility.ecs_key_no_cpu_culling,
        ))
        is Some(_)
      let has_not_shadow_receiver = (try! source_world.get_by_key(
          entity, ecs_key_not_shadow_receiver,
        ))
        is Some(_)
      let has_transmitted_shadow_receiver = (try! source_world.get_by_key(
          entity, ecs_key_transmitted_shadow_receiver,
        ))
        is Some(_)
      let has_no_wireframe = (try! source_world.get_by_key(
          entity, ecs_key_no_wireframe,
        ))
        is Some(_)
      let mesh3d_wireframe = try! source_world.get_by_key(
        entity, ecs_key_mesh3d_wireframe,
      )
      let wireframe_color = try! source_world.get_by_key(
        entity, ecs_key_wireframe_color,
      )
      let wireframe_line_width = try! source_world.get_by_key(
        entity, ecs_key_wireframe_line_width,
      )
      let wireframe_topology = try! source_world.get_by_key(
        entity, ecs_key_wireframe_topology,
      )
      (
        mesh3d, material_handle, view_visibility, global_transform, previous_global_transform,
        aabb, layers, lightmap, is_forward_decal, forward_decal_material_ext, clustered_decal,
        has_not_shadow_caster, has_no_frustum_culling, has_no_automatic_batching,
        has_no_cpu_culling, has_not_shadow_receiver, has_transmitted_shadow_receiver,
        has_no_wireframe, mesh3d_wireframe, wireframe_color, wireframe_line_width,
        wireframe_topology,
      )
    }
  }
  if !view_visibility.is_visible() {
    return (None, false)
  }
  let material_slots = render_material3d_resolved_slots_or_empty(render_world)
  let resolved_material = match material_handle {
    Some(value) =>
      match
        render3d_resolve_mesh_material(
          value, standard_material_frame_cache, resolved_material_frame_cache, default_opaque_renderer_method,
          material_prepass_enabled, standard_material_texture_features,
        ) {
        Some(v) => v
        None => return (None, true)
      }
    None =>
      match material_slots.get(entity) {
        Some(Resolved(value)) =>
          Render3dResolvedMeshMaterial::{
            material_draw_data: value.material_draw_data(),
            material_extension: value.material_extension(),
            material_properties: value.material_properties(),
            material_bind_group_data: value.material_bind_group_data(),
            forward_decal_material_ext: None,
          }
        Some(Pending) => return (None, true)
        None => return (None, false)
      }
  }
  let material_draw_data = resolved_material.material_draw_data
  let resolved_material_extension = resolved_material.material_extension
  let material_properties = resolved_material.material_properties
  let material_bind_group_data = resolved_material.material_bind_group_data
  let layers = match prefetched_layers {
    Some(v) => v
    None => @camera_render_layers.RenderLayers::RenderLayers()
  }
  // Bevy `bevy_pbr::render::mesh::extract_meshes_for_cpu_building` reads
  // `&GlobalTransform` directly and derives render instance transforms from it.
  let world_from_local = global_transform.affine()
  let transform = global_transform.to_transform_approx()
  let previous_global_transform = if needs_mesh_previous_transform {
    prefetched_previous_global_transform
  } else {
    None
  }
  let aabb = prefetched_aabb
  let entity_key = render3d_mesh_entity_key(entity)
  let has_previous_skin = skin_uniforms_value.previous_skins.contains(
    entity_key,
  )
  let has_previous_morph = morph_indices_value.prev.get(entity_key) is Some(_)
  let motion_vector_enabled = if needs_mesh_previous_transform {
    let supports_motion = match
      render3d_mesh_draw_alpha(
        material_properties.alpha_mode,
        material_draw_data.draw_alpha_source(),
      ) {
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
  let previous_world_from_local = match previous_global_transform {
    Some(v) => v.affine()
    None => world_from_local
  }
  let (skinning_key_hi, _skinning_key_lo) = @pbr_render.render3d_prepared_skin_binding_keys(
    skin_uniforms_value, entity,
  )
  let morph_weights_index = match morph_indices_value.current.get(entity_key) {
    Some(offset) => offset.reinterpret_as_int()
    None => -1
  }
  let previous_morph_weights_index = match
    morph_indices_value.prev.get(entity_key) {
    Some(offset) => offset.reinterpret_as_int()
    None => -1
  }
  let morph_targets_texture_id = match
    (try! source_world.get_by_key(entity, @mesh.MorphTargetMesh::component())) {
    Some(value) =>
      render3d_morph_target_texture_id(
        mesh_runtime_state_value,
        value.source_mesh(),
      )
    None => -1
  }
  let lightmap = prefetched_lightmap
  let is_forward_decal = prefetched_is_forward_decal
  let forward_decal_material_ext = match
    resolved_material.forward_decal_material_ext {
    Some(ext) => Some(ext)
    None => prefetched_forward_decal_material_ext
  }
  let clustered_decal = prefetched_clustered_decal
  let has_no_frustum_culling = prefetched_has_no_frustum_culling
  let has_no_cpu_culling = prefetched_has_no_cpu_culling
  let has_not_shadow_receiver = prefetched_has_not_shadow_receiver
  let has_transmitted_shadow_receiver = prefetched_has_transmitted_shadow_receiver
  let has_no_wireframe = prefetched_has_no_wireframe
  let mesh3d_wireframe = prefetched_mesh3d_wireframe
  let wireframe_asset_id = mesh3d_wireframe.map(fn(component) {
    component.material().id()
  })
  let wireframe_material = render3d_extract_wireframe_material(
    source_world, mesh3d_wireframe,
  )
  let wireframe_color = prefetched_wireframe_color
  let wireframe_line_width = prefetched_wireframe_line_width
  let wireframe_topology = prefetched_wireframe_topology
  let has_not_shadow_caster = prefetched_has_not_shadow_caster
  let instance_vertex_buffer_id = match
    (try! source_world.get_by_key(
      entity,
      @render.Mesh3dInstanceVertexBufferData::component(),
    )) {
    Some(instance_buffer_data) => {
      @render.host_gpu_prepare_mesh3d_instance_vertex_buffer(
        buffer_id=instance_buffer_data.buffer_id(),
        bytes=instance_buffer_data.bytes(),
        length=instance_buffer_data.length(),
      )
      instance_buffer_data.buffer_id()
    }
    None => -1
  }
  counters.prepared_meshes = counters.prepared_meshes + 1
  (
    Some(ExtractedMesh3d::{
      entity: phase_entity_ref3d_for_world_main(source_world, entity),
      payload: Mesh3dExtractedPayload::{
        mesh_handle: mesh3d.mesh(),
        world_from_local,
        previous_world_from_local,
        transform,
        previous_transform,
        aabb,
        material_draw_data,
        material_extension: resolved_material_extension,
        material_properties,
        material_bind_group_data,
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
        has_no_wireframe,
        wireframe_asset_id,
        wireframe_material,
        wireframe_color,
        wireframe_line_width,
        wireframe_topology,
        skinning_key_hi,
        has_previous_skin,
        morph_weights_index,
        previous_morph_weights_index,
        morph_targets_texture_id,
        instance_vertex_buffer_id,
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
  mesh_runtime_state_value : @pbr_render.Render3dMeshRuntimeState,
  morph_indices_value : @pbr_render.MorphIndices,
  skin_uniforms_value : @pbr_render.SkinUniforms,
  world_transform_cache_value : @pbr_render.Render3dWorldTransformCache,
  needs_mesh_previous_transform : Bool,
  default_opaque_renderer_method : OpaqueRendererMethod,
  material_prepass_enabled : Bool,
) -> Array[ExtractedMesh3d] {
  let trace_collect_meshes_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_meshes",
  )
  let standard_material_frame_cache : Map[Int, StandardMaterial] = {}
  let resolved_material_frame_cache : Map[Int, Render3dResolvedMeshMaterial] = {}
  let standard_material_texture_features = pbr_standard_material_texture_features(
    source_world,
  )
  let meshes : Array[ExtractedMesh3d] = []
  let counters = Render3dPrepareMeshesCounters::Render3dPrepareMeshesCounters()
  let mesh_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Read[@mesh.Mesh3d],
        @ecs.Optional[MeshMaterial3d],
        @ecs.Read[@visibility.ViewVisibility],
        @ecs.Read[@transform.GlobalTransform],
      ),
      (
        (
          @ecs.Optional[@pbr_prepass.PreviousGlobalTransform],
          @ecs.Optional[@camera_primitives.Aabb],
        ),
        @ecs.Optional[@camera_render_layers.RenderLayers],
        @ecs.Optional[Lightmap],
      ),
      (
        (
          @ecs.Has[ForwardDecal],
          @ecs.Optional[ForwardDecalMaterialExt],
          @ecs.Optional[ClusteredDecal],
          @ecs.Has[NotShadowCaster],
        ),
        (
          @ecs.Has[@visibility.NoFrustumCulling],
          @ecs.Has[@visibility.NoCpuCulling],
        ),
        (
          @ecs.Has[@render_batching.NoAutomaticBatching],
          @ecs.Has[NotShadowReceiver],
          @ecs.Has[TransmittedShadowReceiver],
        ),
        (
          @ecs.Has[NoWireframe],
          @ecs.Optional[Mesh3dWireframe],
          @ecs.Optional[WireframeColor],
          @ecs.Optional[WireframeLineWidth],
          @ecs.Optional[WireframeTopology],
        ),
      ),
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! mesh_query.view(fn(_query_entity, data) {
    let (
      entity,
      (mesh3d, material, view_visibility, global_transform),
      ((previous_global_transform, aabb), render_layers, lightmap),
      (
        (
          forward_decal,
          forward_decal_material_ext,
          clustered_decal,
          not_shadow_caster,
        ),
        (no_frustum_culling, no_cpu_culling),
        (no_automatic_batching, not_shadow_receiver, transmitted_shadow_receiver
        ),
        (
          no_wireframe,
          mesh3d_wireframe,
          wireframe_color,
          wireframe_line_width,
          wireframe_topology,
        ),
      ),
    ) = data
    let (next_mesh, needs_reextract_next_frame) = render3d_extract_mesh_for_entity(
      world,
      source_world,
      entity,
      mesh_runtime_state_value,
      morph_indices_value,
      skin_uniforms_value,
      world_transform_cache_value,
      standard_material_frame_cache,
      resolved_material_frame_cache,
      needs_mesh_previous_transform,
      default_opaque_renderer_method,
      material_prepass_enabled,
      standard_material_texture_features,
      Some(Render3dExtractMeshRequiredComponents::{
        mesh3d: mesh3d.value(),
        material_handle: material.value(),
        view_visibility: view_visibility.value(),
        global_transform: global_transform.value(),
        previous_global_transform: previous_global_transform.value(),
        aabb: aabb.value(),
        layers: render_layers.value(),
        lightmap: lightmap.value(),
        is_forward_decal: forward_decal.present(),
        forward_decal_material_ext: forward_decal_material_ext.value(),
        clustered_decal: clustered_decal.value(),
        has_not_shadow_caster: not_shadow_caster.present(),
        has_no_frustum_culling: no_frustum_culling.present(),
        has_no_automatic_batching: no_automatic_batching.present(),
        has_no_cpu_culling: no_cpu_culling.present(),
        has_not_shadow_receiver: not_shadow_receiver.present(),
        has_transmitted_shadow_receiver: transmitted_shadow_receiver.present(),
        has_no_wireframe: no_wireframe.present(),
        mesh3d_wireframe: mesh3d_wireframe.value(),
        wireframe_color: wireframe_color.value(),
        wireframe_line_width: wireframe_line_width.value(),
        wireframe_topology: wireframe_topology.value(),
      }),
      counters,
    )
    match next_mesh {
      Some(extracted_mesh) => meshes.push(extracted_mesh)
      None => ()
    }
    ignore(needs_reextract_next_frame)
  })
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
  render3d_prepare_extracted_mesh_backend_uploads(
    mesh_runtime_state_value, meshes, counters,
  )
  render3d_prepare_meshes_emit_counters(counters)
  meshes
}
