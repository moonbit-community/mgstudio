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
  source_world : @ecs.World,
  phase_state_ref : Ref[@pbr_render.Render3dPhaseState],
  world_transform_cache_ref : Ref[@pbr_render.Render3dWorldTransformCache],
  needs_mesh_previous_transform : Bool,
) -> Array[ExtractedMesh3d] {
  let meshes : Array[ExtractedMesh3d] = []
  let motion_blur_frame_stamp = if needs_mesh_previous_transform {
    motion_blur_history_begin_frame()
  } else {
    0
  }
  let previous_motion_blur_frame_stamp = motion_blur_frame_stamp - 1
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
    let previous_transform = if needs_mesh_previous_transform {
      match motion_blur_history_get(entity, previous_motion_blur_frame_stamp) {
        Some(v) => v
        None => transform
      }
    } else {
      transform
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
      phase_state_ref, entity,
    )
    let mesh_id = @pbr_render.render3d_upload_mesh_handle_cached(
      phase_state_ref,
      mesh3d.mesh,
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
        mesh_handle: mesh3d.mesh,
        mesh_id,
        mesh_is_indexed: render3d_mesh_handle_is_indexed_cached(
          mesh3d.mesh,
          phase_state_ref.val.mesh_preprocess_static_cache,
        ),
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
        layers,
        has_wireframe,
        has_no_wireframe,
        wireframe_color,
        skinning_key_hi,
        skinning_key_lo,
      },
    })
  })
  if needs_mesh_previous_transform {
    motion_blur_history_sync(meshes, motion_blur_frame_stamp)
  }
  render3d_diagnostic_queued_visible_mesh_count_ref.val = meshes.length()
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_meshes",
    trace_collect_meshes_start_us,
  )
  render3d_update_mesh_preprocess_static_cache(
    phase_state_ref.val.mesh_preprocess_static_cache,
    meshes,
  )
  meshes
}
