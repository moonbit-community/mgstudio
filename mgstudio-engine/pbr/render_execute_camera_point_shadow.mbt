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
  pass_lighting : Render3dLightingState,
  point_light_shadow_map_size : Int,
  camera_entity : @core.Entity,
  draw_queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
  meshes : Array[ExtractedMesh3d],
  opaque_alpha_draw_item_indices : Array[Int],
  indexed_indirect_parameter_indices : Array[Int],
  non_indexed_indirect_parameter_indices : Array[Int],
  point_shadow_pass_kind : Int,
) -> Render3dPointShadowBinding {
  let draw_items = draw_queue_entry.draw_items
  ignore(indexed_indirect_parameter_indices)
  ignore(non_indexed_indirect_parameter_indices)
  if !pass_lighting.point_shadow_maps_enabled ||
    pass_lighting.point_entity is None ||
    pass_lighting.point_range <= 0.0F ||
    point_light_shadow_map_size <= 0 {
    return render3d_point_shadow_binding_none()
  }
  guard pass_lighting.point_entity is Some(point_entity) else {
    return render3d_point_shadow_binding_none()
  }
  let shadow_target_id = render3d_point_light_shadow_target_get_or_create(
    world, point_entity, point_light_shadow_map_size,
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
  let shadow_phase_items = render3d_queue_shadow_phase_items(
    draw_items, meshes, opaque_alpha_draw_item_indices,
  )
  for face_index in 0..<6 {
    let shadow_camera_transform = @pbr_render.render3d_point_shadow_face_transform(
      pass_lighting.point_pos,
      face_index,
    )
    let shadow_view = Render3dShadowView::{
      target_id: shadow_target_id,
      target_layer: face_index,
      width: shadow_view_size,
      height: shadow_view_size,
      transform: shadow_camera_transform,
      projection: point_shadow_pass_projection,
      clip_from_world: None,
      light_entity: Render3dLightEntity::Point(
        light_entity=point_entity,
        face_index~,
      ),
      pass_name: "shadow_point_light_face",
    }
    render3d_shadow_view_begin_pass(
      shadow_view, pass_lighting, point_shadow_pass_kind, shadow_camera_near,
    )
    for shadow_phase_item in shadow_phase_items {
      ignore(render3d_shadow_phase_item_debug_key(shadow_phase_item))
      let extracted_shadow_mesh = meshes[shadow_phase_item.extracted_index]
      let shadow_mesh = extracted_shadow_mesh.payload
      @pbr_render.render3d_draw_mesh_gpu_payload(
        @pbr_render.render3d_build_mesh_gpu_draw_payload(
          shadow_mesh.mesh_id,
          camera_entity.id,
          camera_entity.generation,
          shadow_phase_item.draw_item_index,
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
          0,
          skinning_key_hi=shadow_mesh.skinning_key_hi,
          skinning_key_lo=if shadow_mesh.skinning_key_hi >= 0 { 0 } else { -1 },
        ),
      )
    }
    @render.host_gpu_end_pass()
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
impl @app.Resource for Render3dPointLightShadowTargets with resource() {
  render3d_point_light_shadow_targets_key
}

///|
fn render3d_point_light_shadow_targets_ref_or_init(
  world : @ecs.World,
) -> Ref[Render3dPointLightShadowTargets] {
  if (try! world.get_resource(Render3dPointLightShadowTargets::resource()))
    is None {
    world.insert_resource(Render3dPointLightShadowTargets::resource(), {
      entries: [],
    })
  }
  match
    (try! world.get_resource_mut(Render3dPointLightShadowTargets::resource())) {
    Some(state) => Ref::new(state.peek())
    None => abort("Missing Render3dPointLightShadowTargets resource")
  }
}

///|
fn render3d_point_light_shadow_target_get_or_create(
  world : @ecs.World,
  entity : @core.Entity,
  size : Int,
) -> Int {
  let shadow_targets_ref = render3d_point_light_shadow_targets_ref_or_init(
    world,
  )
  let shadow_targets = shadow_targets_ref.val.entries
  let safe_size = if size <= 0 { 1 } else { size }
  for item in shadow_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.size == safe_size {
      return item.target_id
    }
  }
  let target_id = @render.host_gpu_create_point_light_shadow_target(
    size=safe_size,
  )
  let next : Array[PointLightShadowTargetsEntry] = []
  let mut replaced = false
  for item in shadow_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, size: safe_size, target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, size: safe_size, target_id })
  }
  shadow_targets_ref.val.entries = next
  target_id
}
