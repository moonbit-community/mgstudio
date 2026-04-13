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
fn render3d_execute_camera_motion_vector_pass(
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  draw_queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
  meshes : Array[ExtractedMesh3d],
  opaque_alpha_draw_item_indices : Array[Int],
  indexed_indirect_parameter_indices : Array[Int],
  non_indexed_indirect_parameter_indices : Array[Int],
  motion_vector_prepass_enabled : Bool,
  motion_blur_active : Bool,
  scene_target_id : Int,
  velocity_target_id : Int,
  view_width : Int,
  view_height : Int,
  view_width_logical : Int,
  view_height_logical : Int,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_pass_projection : @pbr_render.Render3dPassProjection,
  pass_lighting : Render3dLightingState,
  camera_exposure_value : Float,
  point_shadow_near : Float,
  motion_vector_pass_kind : Int,
) -> (Int, Int) {
  if !motion_vector_prepass_enabled {
    return (scene_target_id, velocity_target_id)
  }
  let mut next_scene_target_id = scene_target_id
  let mut next_velocity_target_id = velocity_target_id
  let (shared_scene_id, shared_velocity_id) = render3d_motion_blur_targets_get_or_create(
    camera_entity, view_width, view_height,
  )
  if motion_blur_active {
    next_scene_target_id = shared_scene_id
  }
  next_velocity_target_id = shared_velocity_id
  let (
    motion_viewport_x,
    motion_viewport_y,
    motion_viewport_width,
    motion_viewport_height,
  ) = @pbr_render.render3d_pass_viewport_for_target(
    shared_scene_id,
    camera.target_id,
    viewport_x,
    viewport_y,
    viewport_width,
    viewport_height,
  )
  @pbr_render.render3d_begin_pass_3d(
    target_id=shared_scene_id,
    secondary_target_id=next_velocity_target_id,
    width=view_width_logical,
    height=view_height_logical,
    clear_r=0.0F,
    clear_g=0.0F,
    clear_b=0.0F,
    clear_a=0.0F,
    camera.transform,
    camera_pass_projection,
    viewport_x=motion_viewport_x,
    viewport_y=motion_viewport_y,
    viewport_width=motion_viewport_width,
    viewport_height=motion_viewport_height,
    pass_lighting,
    camera_exposure=camera_exposure_value,
    previous_clip_from_world=camera.previous_clip_from_world,
    point_shadow_near~,
    pass_kind=motion_vector_pass_kind,
    clear_enabled=1,
  )
  let draw_items = draw_queue_entry.draw_items
  for draw_item_index in opaque_alpha_draw_item_indices {
    let draw_item = draw_items[draw_item_index]
    if draw_item.phase != RENDER3D_PHASE_OPAQUE &&
      draw_item.phase != RENDER3D_PHASE_ALPHA_MASK {
      continue
    }
    let extracted_mesh = meshes[draw_item.extracted_index]
    let mesh = extracted_mesh.payload
    if !mesh.motion_vector_enabled {
      continue
    }
    let motion_vector_indexed = mesh.mesh_is_indexed
    let motion_vector_indirect_parameters_index = if motion_vector_indexed {
      indexed_indirect_parameter_indices[draw_item_index]
    } else {
      non_indexed_indirect_parameter_indices[draw_item_index]
    }
    @pbr_render.render3d_draw_mesh_gpu_payload(
      @pbr_render.render3d_build_mesh_gpu_draw_payload(
        mesh.mesh_id,
        camera_entity.id,
        camera_entity.generation,
        draw_item_index,
        if motion_vector_indirect_parameters_index >= 0 {
          if motion_vector_indexed {
            MESH3D_DRAW_INDIRECT_KIND_INDEXED
          } else {
            MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED
          }
        } else {
          MESH3D_DRAW_INDIRECT_KIND_NONE
        },
        motion_vector_indirect_parameters_index,
        mesh.material,
        mesh.transform,
        mesh.previous_transform,
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
        render3d_mesh_draw_flags(extracted_mesh),
        skinning_key_hi=mesh.skinning_key_hi,
        skinning_key_lo=if mesh.skinning_key_hi >= 0 {
          mesh.skinning_key_lo + 1
        } else {
          -1
        },
      ),
    )
  }
  @render.host_gpu_end_pass()
  (next_scene_target_id, next_velocity_target_id)
}
