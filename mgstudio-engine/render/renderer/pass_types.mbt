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
pub struct GpuPassState {
  target_id : Int
  target_layer : Int
  secondary_target_id : Int
  width_logical : Float
  height_logical : Float
  is_3d : Bool
  camera_x : Float
  camera_y : Float
  camera_rot : Float
  camera_scale : Float
  camera_z : Float
  camera_exposure : Float
  camera_rot_x : Float
  camera_rot_y : Float
  camera_rot_z : Float
  camera_rot_w : Float
  clip_from_world : GpuClipMatrix
  unjittered_clip_from_world : GpuClipMatrix
  previous_clip_from_world : GpuClipMatrix
  pass_kind : Int
  viewport_x : UInt
  viewport_y : UInt
  viewport_w : UInt
  viewport_h : UInt
  viewport_depth_min : Float
  viewport_depth_max : Float
  ambient_r : Float
  ambient_g : Float
  ambient_b : Float
  ambient_brightness : Float
  directional_dir_x : Float
  directional_dir_y : Float
  directional_dir_z : Float
  directional_color_r : Float
  directional_color_g : Float
  directional_color_b : Float
  directional_illuminance : Float
  point_pos_x : Float
  point_pos_y : Float
  point_pos_z : Float
  point_color_r : Float
  point_color_g : Float
  point_color_b : Float
  point_intensity : Float
  point_range : Float
  spot_pos_x : Float
  spot_pos_y : Float
  spot_pos_z : Float
  spot_dir_x : Float
  spot_dir_y : Float
  spot_dir_z : Float
  spot_color_r : Float
  spot_color_g : Float
  spot_color_b : Float
  spot_intensity : Float
  spot_range : Float
  spot_inner_angle : Float
  spot_outer_angle : Float
  transmission_blur_taps : Float
  transmission_steps : Float
  point_shadow_texture_id : Int
  point_shadow_enabled : Float
  point_shadow_depth_bias : Float
  transmission_source_texture_id : Int
  environment_diffuse_texture_id : Int
  environment_specular_texture_id : Int
  environment_map_intensity : Float
  environment_map_rotation_x : Float
  environment_map_rotation_y : Float
  environment_map_rotation_z : Float
  environment_map_rotation_w : Float
  point_shadow_near : Float
}

///|
pub struct GpuFrameState {
  surface_tex : @wgpu.SurfaceTexture
  surface_texture : @wgpu.Texture
  surface_view : @wgpu.TextureView
  encoder : @wgpu.CommandEncoder
  mut pass : @wgpu.RenderPass?
}

///|
pub struct GpuSurfaceState {
  surface_id : Int
  target_id : Int
  surface : @wgpu.Surface
  mut surface_format : @wgpu.TextureFormat?
  mut configured_width : Int
  mut configured_height : Int
  mut configured_present_mode : UInt
  mut configured_alpha_mode : UInt
  mut configured_desired_maximum_frame_latency : UInt
  mut frame : GpuFrameState?
  mut cleared_this_frame : Bool
}
