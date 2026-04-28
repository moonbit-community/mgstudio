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
pub fn render3d_camera_viewport_rect_logical(
  camera : @sprite.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (Float, Float, Float, Float)? {
  let target_width = target_size.x
  let target_height = target_size.y
  if target_width <= 0 || target_height <= 0 {
    return None
  }
  let mut viewport_x = 0
  let mut viewport_y = 0
  let mut viewport_width = target_width
  let mut viewport_height = target_height
  if camera.viewport is Some(viewport) {
    viewport_x = if viewport.physical_position.x < 0 {
      0
    } else {
      viewport.physical_position.x
    }
    viewport_y = if viewport.physical_position.y < 0 {
      0
    } else {
      viewport.physical_position.y
    }
    viewport_width = if viewport.physical_size.x < 0 {
      0
    } else {
      viewport.physical_size.x
    }
    viewport_height = if viewport.physical_size.y < 0 {
      0
    } else {
      viewport.physical_size.y
    }
    let max_width = if target_width - viewport_x < 0 {
      0
    } else {
      target_width - viewport_x
    }
    let max_height = if target_height - viewport_y < 0 {
      0
    } else {
      target_height - viewport_y
    }
    if viewport_width > max_width {
      viewport_width = max_width
    }
    if viewport_height > max_height {
      viewport_height = max_height
    }
  }
  if viewport_width <= 0 || viewport_height <= 0 {
    return None
  }
  let sf = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
  let logical_x = Float::from_double(viewport_x.to_double()) / sf
  let logical_y = Float::from_double(viewport_y.to_double()) / sf
  let logical_width = Float::from_double(viewport_width.to_double()) / sf
  let logical_height = Float::from_double(viewport_height.to_double()) / sf
  if logical_width <= 0.0F || logical_height <= 0.0F {
    return None
  }
  Some((logical_x, logical_y, logical_width, logical_height))
}

///|
pub fn render3d_view_from_world_matrix(
  transform : @transform.Transform,
) -> ProjectionMatrix3d {
  let inverse_rotation = render3d_quat_conjugate(transform.rotation.normalize())
  let x_axis = quat_rotate_vec3(
    inverse_rotation,
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
  )
  let y_axis = quat_rotate_vec3(
    inverse_rotation,
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let z_axis = quat_rotate_vec3(
    inverse_rotation,
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
  )
  let translation = transform.translation
  let offset_x = -(x_axis.x * translation.x +
    y_axis.x * translation.y +
    z_axis.x * translation.z)
  let offset_y = -(x_axis.y * translation.x +
    y_axis.y * translation.y +
    z_axis.y * translation.z)
  let offset_z = -(x_axis.z * translation.x +
    y_axis.z * translation.y +
    z_axis.z * translation.z)
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(x_axis.x, x_axis.y, x_axis.z, 0.0F),
    @math.Vec4::new(y_axis.x, y_axis.y, y_axis.z, 0.0F),
    @math.Vec4::new(z_axis.x, z_axis.y, z_axis.z, 0.0F),
    @math.Vec4::new(offset_x, offset_y, offset_z, 1.0F),
  )
}

///|
pub fn render3d_begin_pass_3d(
  target_id~ : Int,
  target_layer? : Int = -1,
  secondary_target_id? : Int = -1,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_transform : @transform.Transform,
  pass_projection : Render3dPassProjection,
  viewport_x~ : Int,
  viewport_y~ : Int,
  viewport_width~ : Int,
  viewport_height~ : Int,
  lighting : Render3dLightingState,
  camera_exposure? : Float = 1.0F,
  previous_clip_from_world~ : ProjectionMatrix3d?,
  transmission_blur_taps? : Float = 0.0F,
  transmission_steps? : Float = 0.0F,
  point_shadow_texture_id? : Int = -1,
  point_shadow_enabled? : Float = 0.0F,
  point_shadow_depth_bias? : Float = 0.0F,
  transmission_source_texture_id? : Int = -1,
  environment_diffuse_texture_id? : Int = -1,
  environment_specular_texture_id? : Int = -1,
  environment_map_intensity? : Float = 0.0F,
  environment_map_rotation? : @math.Quat = @math.Quat::identity(),
  point_shadow_near~ : Float,
  directional_shadow_texture_id? : Int = -1,
  directional_shadow_enabled? : Float = 0.0F,
  directional_shadow_depth_bias? : Float = 0.0F,
  directional_shadow_normal_bias? : Float = 0.0F,
  directional_shadow_soft_size? : Float = 0.0F,
  directional_shadow_cascade_count? : Int = 0,
  directional_shadow_cascade_overlap? : Float = 0.0F,
  directional_shadow_cascade_data? : Array[Float] = [],
  clip_from_world_override? : ProjectionMatrix3d? = None,
  pass_kind~ : Int,
  clear_enabled~ : Int,
) -> Unit {
  let clip_from_world = match clip_from_world_override {
    Some(value) => value
    None =>
      render3d_pass_projection_clip_from_world(
        pass_projection, camera_transform,
      )
  }
  let unjittered_clip_from_world = match clip_from_world_override {
    Some(value) => value
    None =>
      render3d_pass_projection_unjittered_clip_from_world(
        pass_projection, camera_transform,
      )
  }
  let resolved_previous_clip_from_world = match previous_clip_from_world {
    Some(value) => value
    None => clip_from_world
  }
  @render_gpu.host_gpu_begin_pass_3d(
    target_id~,
    target_layer~,
    secondary_target_id~,
    width~,
    height~,
    clear_r~,
    clear_g~,
    clear_b~,
    clear_a~,
    camera_x=camera_transform.translation.x,
    camera_y=camera_transform.translation.y,
    camera_z=camera_transform.translation.z,
    camera_exposure~,
    camera_rot_x=camera_transform.rotation.x,
    camera_rot_y=camera_transform.rotation.y,
    camera_rot_z=camera_transform.rotation.z,
    camera_rot_w=camera_transform.rotation.w,
    clip_from_world_x_axis_x=clip_from_world.x_axis.x,
    clip_from_world_x_axis_y=clip_from_world.x_axis.y,
    clip_from_world_x_axis_z=clip_from_world.x_axis.z,
    clip_from_world_x_axis_w=clip_from_world.x_axis.w,
    clip_from_world_y_axis_x=clip_from_world.y_axis.x,
    clip_from_world_y_axis_y=clip_from_world.y_axis.y,
    clip_from_world_y_axis_z=clip_from_world.y_axis.z,
    clip_from_world_y_axis_w=clip_from_world.y_axis.w,
    clip_from_world_z_axis_x=clip_from_world.z_axis.x,
    clip_from_world_z_axis_y=clip_from_world.z_axis.y,
    clip_from_world_z_axis_z=clip_from_world.z_axis.z,
    clip_from_world_z_axis_w=clip_from_world.z_axis.w,
    clip_from_world_w_axis_x=clip_from_world.w_axis.x,
    clip_from_world_w_axis_y=clip_from_world.w_axis.y,
    clip_from_world_w_axis_z=clip_from_world.w_axis.z,
    clip_from_world_w_axis_w=clip_from_world.w_axis.w,
    unjittered_clip_from_world_x_axis_x=unjittered_clip_from_world.x_axis.x,
    unjittered_clip_from_world_x_axis_y=unjittered_clip_from_world.x_axis.y,
    unjittered_clip_from_world_x_axis_z=unjittered_clip_from_world.x_axis.z,
    unjittered_clip_from_world_x_axis_w=unjittered_clip_from_world.x_axis.w,
    unjittered_clip_from_world_y_axis_x=unjittered_clip_from_world.y_axis.x,
    unjittered_clip_from_world_y_axis_y=unjittered_clip_from_world.y_axis.y,
    unjittered_clip_from_world_y_axis_z=unjittered_clip_from_world.y_axis.z,
    unjittered_clip_from_world_y_axis_w=unjittered_clip_from_world.y_axis.w,
    unjittered_clip_from_world_z_axis_x=unjittered_clip_from_world.z_axis.x,
    unjittered_clip_from_world_z_axis_y=unjittered_clip_from_world.z_axis.y,
    unjittered_clip_from_world_z_axis_z=unjittered_clip_from_world.z_axis.z,
    unjittered_clip_from_world_z_axis_w=unjittered_clip_from_world.z_axis.w,
    unjittered_clip_from_world_w_axis_x=unjittered_clip_from_world.w_axis.x,
    unjittered_clip_from_world_w_axis_y=unjittered_clip_from_world.w_axis.y,
    unjittered_clip_from_world_w_axis_z=unjittered_clip_from_world.w_axis.z,
    unjittered_clip_from_world_w_axis_w=unjittered_clip_from_world.w_axis.w,
    previous_clip_from_world_x_axis_x=resolved_previous_clip_from_world.x_axis.x,
    previous_clip_from_world_x_axis_y=resolved_previous_clip_from_world.x_axis.y,
    previous_clip_from_world_x_axis_z=resolved_previous_clip_from_world.x_axis.z,
    previous_clip_from_world_x_axis_w=resolved_previous_clip_from_world.x_axis.w,
    previous_clip_from_world_y_axis_x=resolved_previous_clip_from_world.y_axis.x,
    previous_clip_from_world_y_axis_y=resolved_previous_clip_from_world.y_axis.y,
    previous_clip_from_world_y_axis_z=resolved_previous_clip_from_world.y_axis.z,
    previous_clip_from_world_y_axis_w=resolved_previous_clip_from_world.y_axis.w,
    previous_clip_from_world_z_axis_x=resolved_previous_clip_from_world.z_axis.x,
    previous_clip_from_world_z_axis_y=resolved_previous_clip_from_world.z_axis.y,
    previous_clip_from_world_z_axis_z=resolved_previous_clip_from_world.z_axis.z,
    previous_clip_from_world_z_axis_w=resolved_previous_clip_from_world.z_axis.w,
    previous_clip_from_world_w_axis_x=resolved_previous_clip_from_world.w_axis.x,
    previous_clip_from_world_w_axis_y=resolved_previous_clip_from_world.w_axis.y,
    previous_clip_from_world_w_axis_z=resolved_previous_clip_from_world.w_axis.z,
    previous_clip_from_world_w_axis_w=resolved_previous_clip_from_world.w_axis.w,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    ambient_r=lighting.ambient_color.r,
    ambient_g=lighting.ambient_color.g,
    ambient_b=lighting.ambient_color.b,
    ambient_brightness=lighting.ambient_brightness,
    directional_dir_x=lighting.directional_dir.x,
    directional_dir_y=lighting.directional_dir.y,
    directional_dir_z=lighting.directional_dir.z,
    directional_color_r=lighting.directional_color.r,
    directional_color_g=lighting.directional_color.g,
    directional_color_b=lighting.directional_color.b,
    directional_illuminance=lighting.directional_illuminance,
    point_pos_x=lighting.point_pos.x,
    point_pos_y=lighting.point_pos.y,
    point_pos_z=lighting.point_pos.z,
    point_color_r=lighting.point_color.r,
    point_color_g=lighting.point_color.g,
    point_color_b=lighting.point_color.b,
    point_intensity=lighting.point_intensity,
    point_range=lighting.point_range,
    spot_pos_x=lighting.spot_pos.x,
    spot_pos_y=lighting.spot_pos.y,
    spot_pos_z=lighting.spot_pos.z,
    spot_dir_x=lighting.spot_dir.x,
    spot_dir_y=lighting.spot_dir.y,
    spot_dir_z=lighting.spot_dir.z,
    spot_color_r=lighting.spot_color.r,
    spot_color_g=lighting.spot_color.g,
    spot_color_b=lighting.spot_color.b,
    spot_intensity=lighting.spot_intensity,
    spot_range=lighting.spot_range,
    spot_inner_angle=lighting.spot_inner_angle,
    spot_outer_angle=lighting.spot_outer_angle,
    transmission_blur_taps~,
    transmission_steps~,
    point_shadow_texture_id~,
    point_shadow_enabled~,
    point_shadow_depth_bias~,
    transmission_source_texture_id~,
    environment_diffuse_texture_id~,
    environment_specular_texture_id~,
    environment_map_intensity~,
    environment_map_rotation_x=environment_map_rotation.x,
    environment_map_rotation_y=environment_map_rotation.y,
    environment_map_rotation_z=environment_map_rotation.z,
    environment_map_rotation_w=environment_map_rotation.w,
    point_shadow_near~,
    directional_shadow_texture_id~,
    directional_shadow_enabled~,
    directional_shadow_depth_bias~,
    directional_shadow_normal_bias~,
    directional_shadow_soft_size~,
    directional_shadow_cascade_count~,
    directional_shadow_cascade_overlap~,
    directional_shadow_cascade_data~,
    pass_kind~,
    clear_enabled~,
  )
}
