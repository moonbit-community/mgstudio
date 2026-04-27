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
priv struct Render3dResolvedMeshMaterial {
  material : StandardMaterial
  material_properties : @material.MaterialProperties
  material_shader_path : String?
}

///|
fn render3d_resolve_mesh_material(
  material_handle : MeshMaterial3d,
  standard_material_frame_cache : Map[Int, StandardMaterial],
  resolved_material_frame_cache : Map[Int, Render3dResolvedMeshMaterial],
  default_opaque_renderer_method : OpaqueRendererMethod,
  material_prepass_enabled : Bool,
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
  let base_material = match
    render3d_resolve_standard_material(
      material_handle, standard_material_frame_cache,
    ) {
    Some(v) => v
    None => return None
  }
  let material = @pbr_render.render3d_apply_extended_material_metadata(
    base_material,
    material_handle.extended_material,
  )
  let material_properties = render3d_material_properties_for_standard_material(
    material,
    material_handle.extended_material,
    default_opaque_renderer_method,
    material_prepass_enabled,
  )
  let material_shader_path = match
    material_properties.get_shader("material.fragment") {
    Some(path) => Some(path)
    None =>
      match material_handle.extended_material {
        Some(extension) => extension.shader_path
        None => None
      }
  }
  let resolved = Render3dResolvedMeshMaterial::{
    material,
    material_properties,
    material_shader_path,
  }
  if material_handle.extended_material is None {
    resolved_material_frame_cache.set(material_handle_id, resolved)
  }
  Some(resolved)
}

///|
priv struct Render3dExtractMeshRequiredComponents {
  mesh3d : Mesh3d
  material_handle : MeshMaterial3d
  view_visibility : @visibility.ViewVisibility
  global_transform : @transform.GlobalTransform
  previous_global_transform : @pbr_prepass.PreviousGlobalTransform?
  layers : @sprite.RenderLayers?
  visibility_range : @visibility.VisibilityRange?
  lightmap : Lightmap?
  is_forward_decal : Bool
  forward_decal_material_ext : ForwardDecalMaterialExt?
  clustered_decal : ClusteredDecal?
  has_not_shadow_caster : Bool
  has_no_frustum_culling : Bool
  has_no_cpu_culling : Bool
  has_not_shadow_receiver : Bool
  has_transmitted_shadow_receiver : Bool
  has_wireframe : Bool
  has_no_wireframe : Bool
  wireframe_color : WireframeColor?
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
  resolved_material_frame_cache : Map[Int, Render3dResolvedMeshMaterial],
  needs_mesh_previous_transform : Bool,
  default_opaque_renderer_method : OpaqueRendererMethod,
  material_prepass_enabled : Bool,
  required_components : Render3dExtractMeshRequiredComponents?,
) -> (ExtractedMesh3d?, Bool) {
  guard source_world.is_alive(entity) else { return (None, false) }
  let (
    mesh3d,
    material_handle,
    view_visibility,
    global_transform,
    prefetched_previous_global_transform,
    prefetched_layers,
    prefetched_visibility_range,
    prefetched_lightmap,
    prefetched_is_forward_decal,
    prefetched_forward_decal_material_ext,
    prefetched_clustered_decal,
    prefetched_has_not_shadow_caster,
    prefetched_has_no_frustum_culling,
    prefetched_has_no_cpu_culling,
    prefetched_has_not_shadow_receiver,
    prefetched_has_transmitted_shadow_receiver,
    prefetched_has_wireframe,
    prefetched_has_no_wireframe,
    prefetched_wireframe_color,
  ) = match required_components {
    Some(components) =>
      (
        components.mesh3d,
        components.material_handle,
        components.view_visibility,
        components.global_transform,
        components.previous_global_transform,
        components.layers,
        components.visibility_range,
        components.lightmap,
        components.is_forward_decal,
        components.forward_decal_material_ext,
        components.clustered_decal,
        components.has_not_shadow_caster,
        components.has_no_frustum_culling,
        components.has_no_cpu_culling,
        components.has_not_shadow_receiver,
        components.has_transmitted_shadow_receiver,
        components.has_wireframe,
        components.has_no_wireframe,
        components.wireframe_color,
      )
    None => {
      let mesh3d = match
        (try! source_world.get_by_key(entity, ecs_key_mesh3d)) {
        Some(v) => v
        None => return (None, false)
      }
      let material_handle = match
        (try! source_world.get_by_key(entity, ecs_key_mesh_material3d)) {
        Some(v) => v
        None => return (None, false)
      }
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
              source_world, entity, local_transform, world_transform_cache_ref,
            ),
          )
        }
      }
      let previous_global_transform = if needs_mesh_previous_transform {
        try! source_world.get_by_key(entity, ecs_key_previous_global_transform)
      } else {
        None
      }
      let layers = try! source_world.get_by_key(
        entity, @sprite.ecs_key_render_layers,
      )
      let visibility_range = try! source_world.get_by_key(
        entity, @visibility.ecs_key_visibility_range,
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
      let has_wireframe = (try! source_world.get_by_key(
          entity, ecs_key_wireframe,
        ))
        is Some(_)
      let has_no_wireframe = (try! source_world.get_by_key(
          entity, ecs_key_no_wireframe,
        ))
        is Some(_)
      let wireframe_color = try! source_world.get_by_key(
        entity, ecs_key_wireframe_color,
      )
      (
        mesh3d, material_handle, view_visibility, global_transform, previous_global_transform,
        layers, visibility_range, lightmap, is_forward_decal, forward_decal_material_ext,
        clustered_decal, has_not_shadow_caster, has_no_frustum_culling, has_no_cpu_culling,
        has_not_shadow_receiver, has_transmitted_shadow_receiver, has_wireframe,
        has_no_wireframe, wireframe_color,
      )
    }
  }
  if !view_visibility.is_visible() {
    return (None, false)
  }
  let resolved_material = match
    render3d_resolve_mesh_material(
      material_handle, standard_material_frame_cache, resolved_material_frame_cache,
      default_opaque_renderer_method, material_prepass_enabled,
    ) {
    Some(v) => v
    None => return (None, true)
  }
  let material = resolved_material.material
  let material_properties = resolved_material.material_properties
  let material_shader_path = resolved_material.material_shader_path
  let layers = match prefetched_layers {
    Some(v) => v
    None => @sprite.RenderLayers::default()
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
  let previous_world_from_local = match previous_global_transform {
    Some(v) => v.affine()
    None => world_from_local
  }
  let visibility_range = prefetched_visibility_range
  let aabb_center_world = if visibility_range is Some(range) && range.use_aabb {
    match render3d_mesh_local_aabb_center(mesh3d) {
      Some(local_center) =>
        Some(world_from_local.transform_point3(local_center))
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
  let lightmap = prefetched_lightmap
  let is_forward_decal = prefetched_is_forward_decal
  let forward_decal_material_ext = prefetched_forward_decal_material_ext
  let clustered_decal = prefetched_clustered_decal
  let has_not_shadow_caster = prefetched_has_not_shadow_caster
  let has_no_frustum_culling = prefetched_has_no_frustum_culling
  let has_no_cpu_culling = prefetched_has_no_cpu_culling
  let has_not_shadow_receiver = prefetched_has_not_shadow_receiver
  let has_transmitted_shadow_receiver = prefetched_has_transmitted_shadow_receiver
  let has_wireframe = prefetched_has_wireframe
  let has_no_wireframe = prefetched_has_no_wireframe
  let wireframe_color = prefetched_wireframe_color
  (
    Some(ExtractedMesh3d::{
      entity: phase_entity_ref3d_for_world_main(source_world, entity),
      payload: Mesh3dExtractedPayload::{
        mesh_handle: mesh3d.mesh(),
        mesh_id,
        mesh_topology_kind,
        mesh_is_indexed: mesh_preprocess_static.is_indexed,
        mesh_preprocess_static: Some(mesh_preprocess_static),
        world_from_local,
        previous_world_from_local,
        transform,
        previous_transform,
        visibility_range,
        aabb_center_world,
        material,
        material_extension: material_handle.extended_material,
        material_properties,
        material_shader_path,
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
  let resolved_material_frame_cache : Map[Int, Render3dResolvedMeshMaterial] = {}
  let default_opaque_renderer_method = render3d_material_default_opaque_renderer_method(
    world,
  )
  let material_prepass_enabled = standard_material_prepass_enabled(world)
  let meshes : Array[ExtractedMesh3d] = []
  let mesh_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Comp[Mesh3d],
        @ecs.Comp[MeshMaterial3d],
        @ecs.Comp[@visibility.ViewVisibility],
        @ecs.Comp[@transform.GlobalTransform],
      ),
      (
        @ecs.Optional[@pbr_prepass.PreviousGlobalTransform],
        @ecs.Optional[@sprite.RenderLayers],
        @ecs.Optional[@visibility.VisibilityRange],
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
          @ecs.Has[NotShadowReceiver],
          @ecs.Has[TransmittedShadowReceiver],
        ),
        (
          @ecs.Has[Wireframe],
          @ecs.Has[NoWireframe],
          @ecs.Optional[WireframeColor],
        ),
      ),
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! mesh_query.view(fn(_query_entity, data) {
    let (
      entity,
      (mesh3d, material, view_visibility, global_transform),
      (previous_global_transform, render_layers, visibility_range, lightmap),
      (
        (
          forward_decal,
          forward_decal_material_ext,
          clustered_decal,
          not_shadow_caster,
        ),
        (
          no_frustum_culling,
          no_cpu_culling,
          not_shadow_receiver,
          transmitted_shadow_receiver,
        ),
        (wireframe, no_wireframe, wireframe_color),
      ),
    ) = data
    let (next_mesh, needs_reextract_next_frame) = render3d_extract_mesh_for_entity(
      source_world,
      entity,
      mesh_runtime_state_ref,
      morph_indices_ref,
      skin_uniforms_ref,
      world_transform_cache_ref,
      standard_material_frame_cache,
      resolved_material_frame_cache,
      needs_mesh_previous_transform,
      default_opaque_renderer_method,
      material_prepass_enabled,
      Some(Render3dExtractMeshRequiredComponents::{
        mesh3d: mesh3d.value(),
        material_handle: material.value(),
        view_visibility: view_visibility.value(),
        global_transform: global_transform.value(),
        previous_global_transform: previous_global_transform.value(),
        layers: render_layers.value(),
        visibility_range: visibility_range.value(),
        lightmap: lightmap.value(),
        is_forward_decal: forward_decal.present(),
        forward_decal_material_ext: forward_decal_material_ext.value(),
        clustered_decal: clustered_decal.value(),
        has_not_shadow_caster: not_shadow_caster.present(),
        has_no_frustum_culling: no_frustum_culling.present(),
        has_no_cpu_culling: no_cpu_culling.present(),
        has_not_shadow_receiver: not_shadow_receiver.present(),
        has_transmitted_shadow_receiver: transmitted_shadow_receiver.present(),
        has_wireframe: wireframe.present(),
        has_no_wireframe: no_wireframe.present(),
        wireframe_color: wireframe_color.value(),
      }),
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
