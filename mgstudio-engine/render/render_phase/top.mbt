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

/// Render pass trace helpers for the outer frame timeline.

///|
priv struct RenderPassTraceActiveSpan {
  name : String
  ts_us : Int64
}

///|
priv struct RenderPassTraceRuntimeState {
  mut active_span : RenderPassTraceActiveSpan?
}

///|
fn render_pass_trace_runtime_state_default() -> RenderPassTraceRuntimeState {
  RenderPassTraceRuntimeState::{ active_span: None }
}

///|
let ecs_key_render_pass_trace_runtime_state : @ecs.ResourceKey[
  RenderPassTraceRuntimeState,
] = @ecs.register_resource(
  debug_name="mgstudio_render.render_phase.RenderPassTraceRuntimeState",
)

///|
let render_pass_trace_fallback_state_ref : Ref[RenderPassTraceRuntimeState] = Ref::new(
  render_pass_trace_runtime_state_default(),
)

///|
fn render_pass_trace_runtime_state() -> RenderPassTraceRuntimeState {
  match @app.current_world() {
    Some(world) => {
      if (try! world.get_resource(ecs_key_render_pass_trace_runtime_state))
        is None {
        world.insert_resource(
          ecs_key_render_pass_trace_runtime_state,
          render_pass_trace_runtime_state_default(),
        )
      }
      match (try! world.get_resource(ecs_key_render_pass_trace_runtime_state)) {
        Some(state) => state
        None => render_pass_trace_fallback_state_ref.val
      }
    }
    None => render_pass_trace_fallback_state_ref.val
  }
}

///|
pub fn render_pass_trace_end_active_span() -> Unit {
  let state = render_pass_trace_runtime_state()
  if state.active_span is Some(active_pass) {
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderPass,
      active_pass.name,
      active_pass.ts_us,
    )
  }
  state.active_span = None
}

///|
pub fn render_pass_trace_begin_span(name : String) -> Unit {
  let state = render_pass_trace_runtime_state()
  render_pass_trace_end_active_span()
  let ts_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderPass,
    name,
  )
  if ts_us >= 0L {
    state.active_span = Some(RenderPassTraceActiveSpan::{ name, ts_us })
  }
}

///|
pub fn host_gpu_begin_pass(
  target_id~ : Int,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_x~ : Float,
  camera_y~ : Float,
  camera_rotation~ : Float,
  camera_scale~ : Float,
  viewport_x~ : Int,
  viewport_y~ : Int,
  viewport_width~ : Int,
  viewport_height~ : Int,
  viewport_depth_min~ : Float,
  viewport_depth_max~ : Float,
  clear_enabled~ : Int,
) -> Unit {
  render_pass_trace_begin_span("pass_2d")
  @renderer.begin_pass(
    target_id~,
    width~,
    height~,
    clear_r~,
    clear_g~,
    clear_b~,
    clear_a~,
    camera_x~,
    camera_y~,
    camera_rotation~,
    camera_scale~,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    viewport_depth_min~,
    viewport_depth_max~,
    clear_enabled~,
  )
}

///|
pub fn host_gpu_begin_pass_with_depth(
  target_id~ : Int,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_x~ : Float,
  camera_y~ : Float,
  camera_rotation~ : Float,
  camera_scale~ : Float,
  viewport_x~ : Int,
  viewport_y~ : Int,
  viewport_width~ : Int,
  viewport_height~ : Int,
  viewport_depth_min~ : Float,
  viewport_depth_max~ : Float,
  clear_enabled~ : Int,
) -> Unit {
  render_pass_trace_begin_span("pass_2d_depth")
  @renderer.begin_pass_with_depth(
    target_id~,
    width~,
    height~,
    clear_r~,
    clear_g~,
    clear_b~,
    clear_a~,
    camera_x~,
    camera_y~,
    camera_rotation~,
    camera_scale~,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    viewport_depth_min~,
    viewport_depth_max~,
    clear_enabled~,
  )
}

///|
pub fn host_gpu_begin_pass_3d(
  target_id~ : Int,
  target_layer? : Int = -1,
  secondary_target_id? : Int = -1,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_x~ : Float,
  camera_y~ : Float,
  camera_z~ : Float,
  camera_exposure~ : Float,
  camera_rot_x~ : Float,
  camera_rot_y~ : Float,
  camera_rot_z~ : Float,
  camera_rot_w~ : Float,
  clip_from_world_x_axis_x~ : Float,
  clip_from_world_x_axis_y~ : Float,
  clip_from_world_x_axis_z~ : Float,
  clip_from_world_x_axis_w~ : Float,
  clip_from_world_y_axis_x~ : Float,
  clip_from_world_y_axis_y~ : Float,
  clip_from_world_y_axis_z~ : Float,
  clip_from_world_y_axis_w~ : Float,
  clip_from_world_z_axis_x~ : Float,
  clip_from_world_z_axis_y~ : Float,
  clip_from_world_z_axis_z~ : Float,
  clip_from_world_z_axis_w~ : Float,
  clip_from_world_w_axis_x~ : Float,
  clip_from_world_w_axis_y~ : Float,
  clip_from_world_w_axis_z~ : Float,
  clip_from_world_w_axis_w~ : Float,
  unjittered_clip_from_world_x_axis_x~ : Float,
  unjittered_clip_from_world_x_axis_y~ : Float,
  unjittered_clip_from_world_x_axis_z~ : Float,
  unjittered_clip_from_world_x_axis_w~ : Float,
  unjittered_clip_from_world_y_axis_x~ : Float,
  unjittered_clip_from_world_y_axis_y~ : Float,
  unjittered_clip_from_world_y_axis_z~ : Float,
  unjittered_clip_from_world_y_axis_w~ : Float,
  unjittered_clip_from_world_z_axis_x~ : Float,
  unjittered_clip_from_world_z_axis_y~ : Float,
  unjittered_clip_from_world_z_axis_z~ : Float,
  unjittered_clip_from_world_z_axis_w~ : Float,
  unjittered_clip_from_world_w_axis_x~ : Float,
  unjittered_clip_from_world_w_axis_y~ : Float,
  unjittered_clip_from_world_w_axis_z~ : Float,
  unjittered_clip_from_world_w_axis_w~ : Float,
  previous_clip_from_world_x_axis_x~ : Float,
  previous_clip_from_world_x_axis_y~ : Float,
  previous_clip_from_world_x_axis_z~ : Float,
  previous_clip_from_world_x_axis_w~ : Float,
  previous_clip_from_world_y_axis_x~ : Float,
  previous_clip_from_world_y_axis_y~ : Float,
  previous_clip_from_world_y_axis_z~ : Float,
  previous_clip_from_world_y_axis_w~ : Float,
  previous_clip_from_world_z_axis_x~ : Float,
  previous_clip_from_world_z_axis_y~ : Float,
  previous_clip_from_world_z_axis_z~ : Float,
  previous_clip_from_world_z_axis_w~ : Float,
  previous_clip_from_world_w_axis_x~ : Float,
  previous_clip_from_world_w_axis_y~ : Float,
  previous_clip_from_world_w_axis_z~ : Float,
  previous_clip_from_world_w_axis_w~ : Float,
  viewport_x~ : Int,
  viewport_y~ : Int,
  viewport_width~ : Int,
  viewport_height~ : Int,
  ambient_r~ : Float,
  ambient_g~ : Float,
  ambient_b~ : Float,
  ambient_brightness~ : Float,
  directional_dir_x~ : Float,
  directional_dir_y~ : Float,
  directional_dir_z~ : Float,
  directional_color_r~ : Float,
  directional_color_g~ : Float,
  directional_color_b~ : Float,
  directional_illuminance~ : Float,
  point_pos_x~ : Float,
  point_pos_y~ : Float,
  point_pos_z~ : Float,
  point_color_r~ : Float,
  point_color_g~ : Float,
  point_color_b~ : Float,
  point_intensity~ : Float,
  point_range~ : Float,
  spot_pos_x~ : Float,
  spot_pos_y~ : Float,
  spot_pos_z~ : Float,
  spot_dir_x~ : Float,
  spot_dir_y~ : Float,
  spot_dir_z~ : Float,
  spot_color_r~ : Float,
  spot_color_g~ : Float,
  spot_color_b~ : Float,
  spot_intensity~ : Float,
  spot_range~ : Float,
  spot_inner_angle~ : Float,
  spot_outer_angle~ : Float,
  transmission_blur_taps? : Float = 0.0F,
  transmission_steps? : Float = 0.0F,
  point_shadow_texture_id? : Int = -1,
  point_shadow_enabled? : Float = 0.0F,
  point_shadow_depth_bias? : Float = 0.0F,
  transmission_source_texture_id? : Int = -1,
  environment_diffuse_texture_id? : Int = -1,
  environment_specular_texture_id? : Int = -1,
  environment_map_intensity? : Float = 0.0F,
  environment_map_rotation_x? : Float = 0.0F,
  environment_map_rotation_y? : Float = 0.0F,
  environment_map_rotation_z? : Float = 0.0F,
  environment_map_rotation_w? : Float = 1.0F,
  point_shadow_near~ : Float,
  pass_kind~ : Int,
  clear_enabled~ : Int,
) -> Unit {
  render_pass_trace_begin_span("pass_3d(kind=\{pass_kind})")
  @renderer.begin_pass_3d(
    target_id~,
    target_layer~,
    secondary_target_id~,
    width~,
    height~,
    clear_r~,
    clear_g~,
    clear_b~,
    clear_a~,
    camera_x~,
    camera_y~,
    camera_z~,
    camera_exposure~,
    camera_rot_x~,
    camera_rot_y~,
    camera_rot_z~,
    camera_rot_w~,
    clip_from_world_x_axis_x~,
    clip_from_world_x_axis_y~,
    clip_from_world_x_axis_z~,
    clip_from_world_x_axis_w~,
    clip_from_world_y_axis_x~,
    clip_from_world_y_axis_y~,
    clip_from_world_y_axis_z~,
    clip_from_world_y_axis_w~,
    clip_from_world_z_axis_x~,
    clip_from_world_z_axis_y~,
    clip_from_world_z_axis_z~,
    clip_from_world_z_axis_w~,
    clip_from_world_w_axis_x~,
    clip_from_world_w_axis_y~,
    clip_from_world_w_axis_z~,
    clip_from_world_w_axis_w~,
    unjittered_clip_from_world_x_axis_x~,
    unjittered_clip_from_world_x_axis_y~,
    unjittered_clip_from_world_x_axis_z~,
    unjittered_clip_from_world_x_axis_w~,
    unjittered_clip_from_world_y_axis_x~,
    unjittered_clip_from_world_y_axis_y~,
    unjittered_clip_from_world_y_axis_z~,
    unjittered_clip_from_world_y_axis_w~,
    unjittered_clip_from_world_z_axis_x~,
    unjittered_clip_from_world_z_axis_y~,
    unjittered_clip_from_world_z_axis_z~,
    unjittered_clip_from_world_z_axis_w~,
    unjittered_clip_from_world_w_axis_x~,
    unjittered_clip_from_world_w_axis_y~,
    unjittered_clip_from_world_w_axis_z~,
    unjittered_clip_from_world_w_axis_w~,
    previous_clip_from_world_x_axis_x~,
    previous_clip_from_world_x_axis_y~,
    previous_clip_from_world_x_axis_z~,
    previous_clip_from_world_x_axis_w~,
    previous_clip_from_world_y_axis_x~,
    previous_clip_from_world_y_axis_y~,
    previous_clip_from_world_y_axis_z~,
    previous_clip_from_world_y_axis_w~,
    previous_clip_from_world_z_axis_x~,
    previous_clip_from_world_z_axis_y~,
    previous_clip_from_world_z_axis_z~,
    previous_clip_from_world_z_axis_w~,
    previous_clip_from_world_w_axis_x~,
    previous_clip_from_world_w_axis_y~,
    previous_clip_from_world_w_axis_z~,
    previous_clip_from_world_w_axis_w~,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    ambient_r~,
    ambient_g~,
    ambient_b~,
    ambient_brightness~,
    directional_dir_x~,
    directional_dir_y~,
    directional_dir_z~,
    directional_color_r~,
    directional_color_g~,
    directional_color_b~,
    directional_illuminance~,
    point_pos_x~,
    point_pos_y~,
    point_pos_z~,
    point_color_r~,
    point_color_g~,
    point_color_b~,
    point_intensity~,
    point_range~,
    spot_pos_x~,
    spot_pos_y~,
    spot_pos_z~,
    spot_dir_x~,
    spot_dir_y~,
    spot_dir_z~,
    spot_color_r~,
    spot_color_g~,
    spot_color_b~,
    spot_intensity~,
    spot_range~,
    spot_inner_angle~,
    spot_outer_angle~,
    transmission_blur_taps~,
    transmission_steps~,
    point_shadow_texture_id~,
    point_shadow_enabled~,
    point_shadow_depth_bias~,
    transmission_source_texture_id~,
    environment_diffuse_texture_id~,
    environment_specular_texture_id~,
    environment_map_intensity~,
    environment_map_rotation_x~,
    environment_map_rotation_y~,
    environment_map_rotation_z~,
    environment_map_rotation_w~,
    point_shadow_near~,
    pass_kind~,
    clear_enabled~,
  )
}

///|
pub fn host_gpu_end_pass() -> Unit {
  @renderer.end_pass()
  render_pass_trace_end_active_span()
}
