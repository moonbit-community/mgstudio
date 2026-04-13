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
  pass_lighting : Render3dLightingState,
  point_light_shadow_map_size : Int,
  camera_entity : @core.Entity,
  draw_queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
  meshes : Array[ExtractedMesh3d],
  opaque_alpha_draw_item_indices : Array[Int],
  indexed_indirect_parameter_indices : Array[Int],
  non_indexed_indirect_parameter_indices : Array[Int],
  point_shadow_pass_kind : Int,
) -> (Int, Float, Float) {
  let draw_items = draw_queue_entry.draw_items
  if !pass_lighting.point_shadow_maps_enabled ||
    pass_lighting.point_entity.is_placeholder() ||
    pass_lighting.point_range <= 0.0F ||
    point_light_shadow_map_size <= 0 {
    return (-1, 0.0F, 0.0F)
  }
  let shadow_target_id = render3d_point_light_shadow_target_get_or_create(
    pass_lighting.point_entity,
    point_light_shadow_map_size,
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
  for face_index in 0..<6 {
    let shadow_camera_transform = @pbr_render.render3d_point_shadow_face_transform(
      pass_lighting.point_pos,
      face_index,
    )
    @pbr_render.render3d_begin_pass_3d(
      target_id=shadow_target_id,
      target_layer=face_index,
      width=shadow_view_size,
      height=shadow_view_size,
      clear_r=1.0F,
      clear_g=1.0F,
      clear_b=1.0F,
      clear_a=1.0F,
      shadow_camera_transform,
      point_shadow_pass_projection,
      viewport_x=0,
      viewport_y=0,
      viewport_width=shadow_view_size,
      viewport_height=shadow_view_size,
      pass_lighting,
      previous_clip_from_world=None,
      point_shadow_near=shadow_camera_near,
      pass_kind=point_shadow_pass_kind,
      clear_enabled=1,
    )
    for draw_item_index in opaque_alpha_draw_item_indices {
      let shadow_draw_item = draw_items[draw_item_index]
      if shadow_draw_item.phase != RENDER3D_PHASE_OPAQUE &&
        shadow_draw_item.phase != RENDER3D_PHASE_ALPHA_MASK {
        continue
      }
      let extracted_shadow_mesh = meshes[shadow_draw_item.extracted_index]
      let shadow_mesh = extracted_shadow_mesh.payload
      if shadow_mesh.has_not_shadow_caster {
        continue
      }
      if shadow_mesh.is_forward_decal || shadow_mesh.clustered_decal is Some(_) {
        continue
      }
      guard render3d_mesh_draw_alpha(
          shadow_mesh.material.alpha_mode,
          shadow_mesh.material.base_color.a,
        )
        is Some(shadow_alpha) else {
        continue
      }
      if shadow_alpha < 0.999F {
        continue
      }
      let shadow_indexed = shadow_mesh.mesh_is_indexed
      let shadow_indirect_parameters_index = if shadow_indexed {
        indexed_indirect_parameter_indices[draw_item_index]
      } else {
        non_indexed_indirect_parameter_indices[draw_item_index]
      }
      @pbr_render.render3d_draw_mesh_gpu_payload(
        @pbr_render.render3d_build_mesh_gpu_draw_payload(
          shadow_mesh.mesh_id,
          camera_entity.id,
          camera_entity.generation,
          draw_item_index,
          if shadow_indirect_parameters_index >= 0 {
            if shadow_indexed {
              MESH3D_DRAW_INDIRECT_KIND_INDEXED
            } else {
              MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED
            }
          } else {
            MESH3D_DRAW_INDIRECT_KIND_NONE
          },
          shadow_indirect_parameters_index,
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
        ),
      )
    }
    @render.host_gpu_end_pass()
  }
  (point_shadow_texture_id, point_shadow_enabled, point_shadow_depth_bias)
}

///|
priv struct PointLightShadowTargetsEntry {
  entity : @core.Entity
  size : Int
  target_id : Int
}

///|
let point_light_shadow_targets : Ref[Array[PointLightShadowTargetsEntry]] = Ref::new([],
)

///|
fn render3d_point_light_shadow_target_get_or_create(
  entity : @core.Entity,
  size : Int,
) -> Int {
  let safe_size = if size <= 0 { 1 } else { size }
  for item in point_light_shadow_targets.val {
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
  for item in point_light_shadow_targets.val {
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
  point_light_shadow_targets.val = next
  target_id
}
