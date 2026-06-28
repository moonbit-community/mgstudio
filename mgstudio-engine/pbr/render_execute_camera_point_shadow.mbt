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
fn render3d_execute_camera_point_shadow_pass(
  world : @ecs.World,
  camera : Camera3dViewPayload,
  pass_lighting : Render3dLightingState,
  point_light_shadow_map_size : Int,
  camera_entity : @core.Entity,
  meshes : Array[ExtractedMesh3d],
  point_shadow_pass_kind : Int,
) -> Render3dPointShadowBinding {
  if !pass_lighting.point_shadow_maps_enabled ||
    pass_lighting.point_entity is None ||
    pass_lighting.point_render_entity is None ||
    pass_lighting.point_range <= 0.0F ||
    point_light_shadow_map_size <= 0 {
    return render3d_point_shadow_binding_none()
  }
  guard pass_lighting.point_entity is Some(point_entity) else {
    return render3d_point_shadow_binding_none()
  }
  guard pass_lighting.point_render_entity is Some(point_render_entity) else {
    return render3d_point_shadow_binding_none()
  }
  let point_light_index = if pass_lighting.point_light_index < 0 {
    0
  } else {
    pass_lighting.point_light_index
  }
  let shadow_target_id = render3d_point_light_shadow_target_get_or_create(
    world,
    point_render_entity,
    point_light_shadow_map_size,
    point_light_index + 1,
  )
  let point_shadow_texture_id = shadow_target_id
  let point_shadow_enabled = 1.0F
  let point_shadow_depth_bias = @pbr_render.maxf(
    0.0F,
    pass_lighting.point_shadow_depth_bias,
  )
  let shadow_camera_near = if pass_lighting.point_shadow_map_near_z > 0.0001F {
    pass_lighting.point_shadow_map_near_z
  } else {
    0.0001F
  }
  let shadow_view_size = point_light_shadow_map_size
  let point_shadow_pass_projection = @pbr_render.render3d_point_shadow_pass_projection(
    shadow_camera_near,
    pass_lighting.point_range,
  )
  let shadow_phase_views : Array[Render3dShadowPhaseView] = []
  for face_index in 0..<6 {
    let shadow_camera_transform = @pbr_render.render3d_point_shadow_face_transform(
      pass_lighting.point_pos,
      face_index,
    )
    let shadow_frustum = @pbr_render.render3d_compute_frustum(
      point_shadow_pass_projection.clip_from_view,
      shadow_camera_transform,
      pass_lighting.point_range,
    )
    let shadow_phase_trace_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "render_3d_shadow_phase_construction",
    )
    let shadow_light_entity = Render3dLightEntity::Point(
      light_entity=point_render_entity,
      main_entity=point_entity,
      face_index~,
    )
    let retained_view_entity = shadow_light_entity.shadow_phase_retained_view(
      @render_view.RetainedViewEntity::new(camera_entity),
    )
    ignore(
      render3d_prepare_queued_shadow_phase_visible_view(
        world,
        shadow_light_entity,
        retained_view_entity,
        meshes,
        camera.layers,
        render3d_host_preprocess_frustum_planes_from_half_spaces(
          shadow_frustum.half_spaces,
        ),
      ),
    )
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "render_3d_shadow_phase_construction",
      shadow_phase_trace_start_us,
    )
    let shadow_view = Render3dShadowView::{
      target_id: shadow_target_id,
      target_layer: render3d_point_shadow_target_layer(
        point_light_index, face_index,
      ),
      width: shadow_view_size,
      height: shadow_view_size,
      transform: shadow_camera_transform,
      projection: point_shadow_pass_projection,
      clip_from_world: None,
      light_entity: shadow_light_entity,
      pass_name: render3d_point_shadow_pass_name(point_light_index, face_index),
      occlusion_culling_subview: None,
    }
    shadow_phase_views.push({ shadow_view, })
  }
  render3d_prepare_and_collect_shadow_phase_buffers_system(world)
  for phase_view in shadow_phase_views {
    render3d_execute_shadow_phase_view(
      world, camera_entity, pass_lighting, point_shadow_pass_kind, shadow_camera_near,
      meshes, phase_view,
    )
  }
  {
    texture_id: point_shadow_texture_id,
    enabled: point_shadow_enabled,
    depth_bias: point_shadow_depth_bias,
  }
}

///|
priv struct PointLightShadowTargetsEntry {
  entity : @core.Entity
  size : Int
  cubes : Int
  target_id : Int
}

///|
priv struct Render3dPointLightShadowTargets {
  mut entries : Array[PointLightShadowTargetsEntry]
}

///|
let render3d_point_light_shadow_targets_key : @ecs.ResourceKey[
  Render3dPointLightShadowTargets,
] = @ecs.register_resource(
  debug_name="mgstudio.render3d.point_light_shadow_targets",
)

///|
impl @app.Resource for Render3dPointLightShadowTargets with fn resource() {
  render3d_point_light_shadow_targets_key
}

///|
fn render3d_point_light_shadow_targets_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[Render3dPointLightShadowTargets] {
  if world.get_resource(Render3dPointLightShadowTargets::resource()) is None {
    world.insert_resource(Render3dPointLightShadowTargets::resource(), {
      entries: [],
    })
  }
  match world.get_resource_mut(Render3dPointLightShadowTargets::resource()) {
    Some(state) => state
    None => abort("Missing Render3dPointLightShadowTargets resource")
  }
}

///|
fn render3d_point_light_shadow_target_get_or_create(
  world : @ecs.World,
  entity : @core.Entity,
  size : Int,
  cubes : Int,
) -> Int {
  let shadow_targets_mut = render3d_point_light_shadow_targets_mut_or_init(
    world,
  )
  let shadow_targets = shadow_targets_mut.peek().entries
  let safe_size = if size <= 0 { 1 } else { size }
  let safe_cubes = if cubes <= 0 { 1 } else { cubes }
  for item in shadow_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.size == safe_size &&
      item.cubes == safe_cubes {
      return item.target_id
    }
  }
  let target_id = @render.host_gpu_create_point_light_shadow_target(
    size=safe_size,
    cubes=safe_cubes,
  )
  let next : Array[PointLightShadowTargetsEntry] = []
  let mut replaced = false
  for item in shadow_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, size: safe_size, cubes: safe_cubes, target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, size: safe_size, cubes: safe_cubes, target_id })
  }
  shadow_targets_mut.modify(fn(state) { state.entries = next })
  target_id
}

///|
fn render3d_point_shadow_target_layer(
  light_index : Int,
  face_index : Int,
) -> Int {
  let safe_light_index = if light_index < 0 { 0 } else { light_index }
  let safe_face_index = if face_index < 0 { 0 } else { face_index }
  safe_light_index * 6 + safe_face_index
}
