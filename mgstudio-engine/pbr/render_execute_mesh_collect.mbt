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
fn render3d_execute_collect_meshes(
  world : @ecs.World,
  source_world : @ecs.World,
  mesh_runtime_state_ref : Ref[@pbr_render.Render3dMeshRuntimeState],
  morph_indices_ref : Ref[@pbr_render.MorphIndices],
  skin_uniforms_ref : Ref[@pbr_render.SkinUniforms],
  world_transform_cache_ref : Ref[@pbr_render.Render3dWorldTransformCache],
  needs_mesh_previous_transform : Bool,
) -> Array[ExtractedMesh3d] {
  let meshes : Array[ExtractedMesh3d] = []
  let trace_collect_meshes_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_meshes",
  )
  let standard_material_frame_cache : Map[Int, StandardMaterial] = {}
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
  let mesh_extract_query : @ecs.Query[
    (
      @ecs.Comp[Mesh3d],
      @ecs.Comp[MeshMaterial3d],
      @ecs.Comp[@visibility.ViewVisibility],
      @ecs.Comp[@transform.Transform],
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  fn mesh_entity_key(entity : @core.Entity) -> UInt64 {
    let hi = entity.id.reinterpret_as_uint().to_uint64()
    let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
    (hi << 32) | lo
  }
  try! mesh_extract_query.view(fn(entity, data) {
    let (
      mesh3d_comp,
      material_handle_comp,
      view_visibility_comp,
      local_transform_comp,
    ) = data
    let mesh3d = mesh3d_comp.value()
    let view_visibility = view_visibility_comp.value()
    if !view_visibility.is_visible() {
      return
    }
    let material_handle = material_handle_comp.value()
    let material_handle_id = material_handle.material.id()
    let base_material = match
      standard_material_frame_cache.get(material_handle_id) {
      Some(cached_material) => cached_material
      None =>
        match standard_material_get(material_handle.material) {
          Some(loaded_material) => {
            standard_material_frame_cache.set(
              material_handle_id, loaded_material,
            )
            loaded_material
          }
          None => return
        }
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
      source_world,
      entity,
      local_transform_comp.value(),
      world_transform_cache_ref,
    )
    let previous_global_transform = if needs_mesh_previous_transform {
      try! source_world.get_by_key(entity, ecs_key_previous_global_transform)
    } else {
      None
    }
    let entity_key = mesh_entity_key(entity)
    let has_previous_skin = skin_uniforms_ref.val.previous_skins.contains(
      entity_key,
    )
    let has_previous_morph = morph_indices_ref.val.prev.get(entity_key)
      is Some(_)
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
    let (skinning_key_hi, skinning_key_lo) = @pbr_render.render3d_prepared_skin_binding_keys(
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
      (try! source_world.get_by_key(entity, ecs_key_not_shadow_caster))
      is Some(_)
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
    meshes.push(ExtractedMesh3d::{
      entity: phase_entity_ref3d_for_main(entity),
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
        skinning_key_lo,
        motion_vector_enabled,
      },
    })
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
