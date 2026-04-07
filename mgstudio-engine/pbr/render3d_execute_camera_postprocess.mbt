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
fn render3d_execute_camera_postprocess(
  world : @ecs.World,
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  scene_target_id : Int,
  velocity_target_id : Int,
  motion_blur_active : Bool,
  bloom_enabled : Bool,
  tonemap_postprocess_enabled : Bool,
  auto_exposure_enabled : Bool,
  effect_stack_postprocess_enabled : Bool,
  custom_post_process_enabled : Bool,
  tonemapping_stage_enabled : Bool,
  fxaa_postprocess_enabled : Bool,
  effective_exposure : Exposure?,
  view_width : Int,
  view_height : Int,
  view_width_logical : Int,
  view_height_logical : Int,
  clear_color : @sprite.Color,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  viewport_depth_min : Float,
  viewport_depth_max : Float,
  clear_enabled : Bool,
  delta_seconds : Float,
  cleared_targets_this_frame : Array[Int],
) -> Unit {
  fn pass_viewport(target_id : Int) -> (Int, Int, Int, Int) {
    render3d_pass_viewport_for_target(
      target_id,
      camera.target_id,
      viewport_x,
      viewport_y,
      viewport_width,
      viewport_height,
    )
  }
  let mut final_source_texture_id = -1
  if motion_blur_active &&
    camera.motion_blur is Some(motion_blur) &&
    velocity_target_id >= 0 {
    if bloom_enabled || tonemap_postprocess_enabled {
      let post_motion_blur_target_id = render3d_transmission_source_target_get_or_create(
        camera_entity, view_width, view_height,
      )
      let (
        post_motion_blur_viewport_x,
        post_motion_blur_viewport_y,
        post_motion_blur_viewport_width,
        post_motion_blur_viewport_height,
      ) = pass_viewport(post_motion_blur_target_id)
      @render.host_gpu_begin_pass(
        target_id=post_motion_blur_target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=clear_color.r,
        clear_g=clear_color.g,
        clear_b=clear_color.b,
        clear_a=clear_color.a,
        camera_x=0.0F,
        camera_y=0.0F,
        camera_rotation=0.0F,
        camera_scale=1.0F,
        viewport_x=post_motion_blur_viewport_x,
        viewport_y=post_motion_blur_viewport_y,
        viewport_width=post_motion_blur_viewport_width,
        viewport_height=post_motion_blur_viewport_height,
        viewport_depth_min~,
        viewport_depth_max~,
        clear_enabled=render3d_pass_clear_enabled_for_target(
          cleared_targets_this_frame, post_motion_blur_target_id, clear_enabled,
        ),
      )
      @render.host_gpu_draw_motion_blur(
        scene_texture_id=scene_target_id,
        velocity_texture_id=velocity_target_id,
        shutter_angle=motion_blur.shutter_angle,
        samples=motion_blur.samples,
      )
      @render.host_gpu_end_pass()
      final_source_texture_id = post_motion_blur_target_id
    } else {
      let (
        motion_blur_present_viewport_x,
        motion_blur_present_viewport_y,
        motion_blur_present_viewport_width,
        motion_blur_present_viewport_height,
      ) = pass_viewport(camera.target_id)
      @render.host_gpu_begin_pass(
        target_id=camera.target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=clear_color.r,
        clear_g=clear_color.g,
        clear_b=clear_color.b,
        clear_a=clear_color.a,
        camera_x=0.0F,
        camera_y=0.0F,
        camera_rotation=0.0F,
        camera_scale=1.0F,
        viewport_x=motion_blur_present_viewport_x,
        viewport_y=motion_blur_present_viewport_y,
        viewport_width=motion_blur_present_viewport_width,
        viewport_height=motion_blur_present_viewport_height,
        viewport_depth_min~,
        viewport_depth_max~,
        clear_enabled=render3d_pass_clear_enabled_for_target(
          cleared_targets_this_frame,
          camera.target_id,
          clear_enabled,
        ),
      )
      @render.host_gpu_draw_motion_blur(
        scene_texture_id=scene_target_id,
        velocity_texture_id=velocity_target_id,
        shutter_angle=motion_blur.shutter_angle,
        samples=motion_blur.samples,
      )
      @render.host_gpu_end_pass()
    }
  } else if scene_target_id != camera.target_id {
    final_source_texture_id = scene_target_id
  }
  if bloom_enabled || tonemap_postprocess_enabled || auto_exposure_enabled {
    let postprocess_source_texture_id = if final_source_texture_id >= 0 {
      final_source_texture_id
    } else {
      scene_target_id
    }
    if postprocess_source_texture_id >= 0 {
      if camera.camera3d.auto_exposure is Some(auto_exposure_settings) {
        let (
          auto_exposure_viewport_x,
          auto_exposure_viewport_y,
          auto_exposure_viewport_width,
          auto_exposure_viewport_height,
        ) = pass_viewport(camera.target_id)
        @render.host_gpu_begin_pass(
          target_id=camera.target_id,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear_color.r,
          clear_g=clear_color.g,
          clear_b=clear_color.b,
          clear_a=clear_color.a,
          camera_x=0.0F,
          camera_y=0.0F,
          camera_rotation=0.0F,
          camera_scale=1.0F,
          viewport_x=auto_exposure_viewport_x,
          viewport_y=auto_exposure_viewport_y,
          viewport_width=auto_exposure_viewport_width,
          viewport_height=auto_exposure_viewport_height,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=render3d_pass_clear_enabled_for_target(
            cleared_targets_this_frame,
            camera.target_id,
            clear_enabled,
          ),
        )
        render3d_apply_camera_auto_exposure(
          world,
          camera_entity,
          auto_exposure_settings,
          camera.color_grading,
          postprocess_source_texture_id,
          view_width_logical,
          view_height_logical,
          delta_seconds,
        )
        @render.host_gpu_end_pass()
      }
      if bloom_enabled && camera.bloom is Some(bloom) {
        let (
          bloom_viewport_x,
          bloom_viewport_y,
          bloom_viewport_width,
          bloom_viewport_height,
        ) = pass_viewport(camera.target_id)
        @render.host_gpu_begin_pass(
          target_id=camera.target_id,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear_color.r,
          clear_g=clear_color.g,
          clear_b=clear_color.b,
          clear_a=clear_color.a,
          camera_x=0.0F,
          camera_y=0.0F,
          camera_rotation=0.0F,
          camera_scale=1.0F,
          viewport_x=bloom_viewport_x,
          viewport_y=bloom_viewport_y,
          viewport_width=bloom_viewport_width,
          viewport_height=bloom_viewport_height,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=render3d_pass_clear_enabled_for_target(
            cleared_targets_this_frame,
            camera.target_id,
            clear_enabled,
          ),
        )
        render3d_draw_camera_bloom_stage(
          postprocess_source_texture_id, bloom, view_width_logical, view_height_logical,
        )
        @render.host_gpu_end_pass()
      }
      let postprocess_stage_count = (if effect_stack_postprocess_enabled {
          1
        } else {
          0
        }) +
        (if custom_post_process_enabled { 1 } else { 0 }) +
        (if tonemapping_stage_enabled { 1 } else { 0 }) +
        (if fxaa_postprocess_enabled { 1 } else { 0 })
      if postprocess_stage_count > 0 {
        let stage_ping_target_id = render3d_transmission_source_target_get_or_create(
          camera_entity, view_width, view_height,
        )
        let mut current_source_texture_id = postprocess_source_texture_id
        let mut stage_index = 0
        if effect_stack_postprocess_enabled {
          let stage_target_id = render3d_postprocess_stage_target(
            current_source_texture_id,
            scene_target_id,
            stage_ping_target_id,
            camera.target_id,
            stage_index,
            postprocess_stage_count,
          )
          let (
            effect_stack_viewport_x,
            effect_stack_viewport_y,
            effect_stack_viewport_width,
            effect_stack_viewport_height,
          ) = pass_viewport(stage_target_id)
          @render.host_gpu_begin_pass(
            target_id=stage_target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear_color.r,
            clear_g=clear_color.g,
            clear_b=clear_color.b,
            clear_a=clear_color.a,
            camera_x=0.0F,
            camera_y=0.0F,
            camera_rotation=0.0F,
            camera_scale=1.0F,
            viewport_x=effect_stack_viewport_x,
            viewport_y=effect_stack_viewport_y,
            viewport_width=effect_stack_viewport_width,
            viewport_height=effect_stack_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=render3d_pass_clear_enabled_for_target(
              cleared_targets_this_frame, stage_target_id, clear_enabled,
            ),
          )
          render3d_draw_camera_effect_stack_stage(
            current_source_texture_id,
            camera.chromatic_aberration,
            camera.vignette,
            view_width_logical,
            view_height_logical,
          )
          @render.host_gpu_end_pass()
          current_source_texture_id = stage_target_id
          stage_index = stage_index + 1
        }
        if custom_post_process_enabled {
          let stage_target_id = render3d_postprocess_stage_target(
            current_source_texture_id,
            scene_target_id,
            stage_ping_target_id,
            camera.target_id,
            stage_index,
            postprocess_stage_count,
          )
          let (
            custom_postprocess_viewport_x,
            custom_postprocess_viewport_y,
            custom_postprocess_viewport_width,
            custom_postprocess_viewport_height,
          ) = pass_viewport(stage_target_id)
          @render.host_gpu_begin_pass(
            target_id=stage_target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear_color.r,
            clear_g=clear_color.g,
            clear_b=clear_color.b,
            clear_a=clear_color.a,
            camera_x=0.0F,
            camera_y=0.0F,
            camera_rotation=0.0F,
            camera_scale=1.0F,
            viewport_x=custom_postprocess_viewport_x,
            viewport_y=custom_postprocess_viewport_y,
            viewport_width=custom_postprocess_viewport_width,
            viewport_height=custom_postprocess_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=render3d_pass_clear_enabled_for_target(
              cleared_targets_this_frame, stage_target_id, clear_enabled,
            ),
          )
          render3d_draw_camera_custom_post_process_stage(
            current_source_texture_id,
            camera.custom_post_process3d,
            view_width_logical,
            view_height_logical,
          )
          @render.host_gpu_end_pass()
          current_source_texture_id = stage_target_id
          stage_index = stage_index + 1
        }
        if tonemapping_stage_enabled {
          let stage_target_id = render3d_postprocess_stage_target(
            current_source_texture_id,
            scene_target_id,
            stage_ping_target_id,
            camera.target_id,
            stage_index,
            postprocess_stage_count,
          )
          let (
            tonemapping_viewport_x,
            tonemapping_viewport_y,
            tonemapping_viewport_width,
            tonemapping_viewport_height,
          ) = pass_viewport(stage_target_id)
          @render.host_gpu_begin_pass(
            target_id=stage_target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear_color.r,
            clear_g=clear_color.g,
            clear_b=clear_color.b,
            clear_a=clear_color.a,
            camera_x=0.0F,
            camera_y=0.0F,
            camera_rotation=0.0F,
            camera_scale=1.0F,
            viewport_x=tonemapping_viewport_x,
            viewport_y=tonemapping_viewport_y,
            viewport_width=tonemapping_viewport_width,
            viewport_height=tonemapping_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=render3d_pass_clear_enabled_for_target(
              cleared_targets_this_frame, stage_target_id, clear_enabled,
            ),
          )
          if camera.camera3d.auto_exposure is Some(_) {
            @render.host_gpu_activate_auto_exposure_view_state(
              view_key_hi=camera_entity.id,
              view_key_lo=camera_entity.generation,
            )
          }
          render3d_draw_camera_tonemapping_stage(
            world,
            current_source_texture_id,
            effective_exposure,
            camera.tonemapping,
            camera.deband_dither,
            camera.color_grading,
            camera.hdr_enabled,
            view_width_logical,
            view_height_logical,
          )
          @render.host_gpu_end_pass()
          current_source_texture_id = stage_target_id
          stage_index = stage_index + 1
        }
        if fxaa_postprocess_enabled {
          let stage_target_id = render3d_postprocess_stage_target(
            current_source_texture_id,
            scene_target_id,
            stage_ping_target_id,
            camera.target_id,
            stage_index,
            postprocess_stage_count,
          )
          let (
            fxaa_viewport_x,
            fxaa_viewport_y,
            fxaa_viewport_width,
            fxaa_viewport_height,
          ) = pass_viewport(stage_target_id)
          @render.host_gpu_begin_pass(
            target_id=stage_target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear_color.r,
            clear_g=clear_color.g,
            clear_b=clear_color.b,
            clear_a=clear_color.a,
            camera_x=0.0F,
            camera_y=0.0F,
            camera_rotation=0.0F,
            camera_scale=1.0F,
            viewport_x=fxaa_viewport_x,
            viewport_y=fxaa_viewport_y,
            viewport_width=fxaa_viewport_width,
            viewport_height=fxaa_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=render3d_pass_clear_enabled_for_target(
              cleared_targets_this_frame, stage_target_id, clear_enabled,
            ),
          )
          render3d_draw_camera_fxaa_stage(
            current_source_texture_id,
            camera.fxaa,
            view_width_logical,
            view_height_logical,
          )
          @render.host_gpu_end_pass()
        }
      } else if postprocess_source_texture_id != camera.target_id {
        let (
          postprocess_present_viewport_x,
          postprocess_present_viewport_y,
          postprocess_present_viewport_width,
          postprocess_present_viewport_height,
        ) = pass_viewport(camera.target_id)
        @render.host_gpu_begin_pass(
          target_id=camera.target_id,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear_color.r,
          clear_g=clear_color.g,
          clear_b=clear_color.b,
          clear_a=clear_color.a,
          camera_x=0.0F,
          camera_y=0.0F,
          camera_rotation=0.0F,
          camera_scale=1.0F,
          viewport_x=postprocess_present_viewport_x,
          viewport_y=postprocess_present_viewport_y,
          viewport_width=postprocess_present_viewport_width,
          viewport_height=postprocess_present_viewport_height,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=render3d_pass_clear_enabled_for_target(
            cleared_targets_this_frame,
            camera.target_id,
            clear_enabled,
          ),
        )
        if bloom_enabled {
          // Bloom can render through an fp16 intermediate even when camera
          // HDR is disabled. Resolve through the postprocess fullscreen
          // shader to avoid dark fp16->surface blits on this path.
          render3d_draw_camera_tonemapping_stage(
            world,
            postprocess_source_texture_id,
            Some(Exposure::new(0.0F)),
            None,
            None,
            None,
            true,
            view_width_logical,
            view_height_logical,
          )
        } else {
          @render.host_gpu_draw_sprite_uv(
            texture_id=postprocess_source_texture_id,
            x=0.0F,
            y=0.0F,
            rotation=0.0F,
            scale_x=Float::from_double(view_width_logical.to_double()) / 128.0F,
            scale_y=Float::from_double(view_height_logical.to_double()) / 128.0F,
            color_r=1.0F,
            color_g=1.0F,
            color_b=1.0F,
            color_a=1.0F,
            uv_min_x=0.0F,
            uv_min_y=0.0F,
            uv_max_x=1.0F,
            uv_max_y=1.0F,
          )
        }
        @render.host_gpu_end_pass()
      }
    }
  } else if final_source_texture_id >= 0 {
    let (
      final_present_viewport_x,
      final_present_viewport_y,
      final_present_viewport_width,
      final_present_viewport_height,
    ) = pass_viewport(camera.target_id)
    @render.host_gpu_begin_pass(
      target_id=camera.target_id,
      width=view_width_logical,
      height=view_height_logical,
      clear_r=clear_color.r,
      clear_g=clear_color.g,
      clear_b=clear_color.b,
      clear_a=clear_color.a,
      camera_x=0.0F,
      camera_y=0.0F,
      camera_rotation=0.0F,
      camera_scale=1.0F,
      viewport_x=final_present_viewport_x,
      viewport_y=final_present_viewport_y,
      viewport_width=final_present_viewport_width,
      viewport_height=final_present_viewport_height,
      viewport_depth_min~,
      viewport_depth_max~,
      clear_enabled=render3d_pass_clear_enabled_for_target(
        cleared_targets_this_frame,
        camera.target_id,
        clear_enabled,
      ),
    )
    @render.host_gpu_draw_sprite_uv(
      texture_id=final_source_texture_id,
      x=0.0F,
      y=0.0F,
      rotation=0.0F,
      scale_x=Float::from_double(view_width_logical.to_double()) / 128.0F,
      scale_y=Float::from_double(view_height_logical.to_double()) / 128.0F,
      color_r=1.0F,
      color_g=1.0F,
      color_b=1.0F,
      color_a=1.0F,
      uv_min_x=0.0F,
      uv_min_y=0.0F,
      uv_max_x=1.0F,
      uv_max_y=1.0F,
    )
    @render.host_gpu_end_pass()
  }
}
