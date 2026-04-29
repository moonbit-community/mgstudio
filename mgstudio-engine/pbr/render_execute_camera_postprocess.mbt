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
  cas_postprocess_enabled : Bool,
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
  let source_world = @render.render_source_world(world)
  fn pass_viewport(target_id : Int) -> (Int, Int, Int, Int) {
    @pbr_render.render3d_pass_viewport_for_target(
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
        world, camera_entity, view_width, view_height,
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
        clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
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
        clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
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
      if camera.auto_exposure is Some(auto_exposure_settings) {
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
          clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
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
          clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
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
        (if fxaa_postprocess_enabled { 1 } else { 0 }) +
        (if cas_postprocess_enabled { 1 } else { 0 })
      if postprocess_stage_count > 0 {
        let stage_ping_target_id = render3d_transmission_source_target_get_or_create(
          world, camera_entity, view_width, view_height,
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
            clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
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
            clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
              cleared_targets_this_frame, stage_target_id, clear_enabled,
            ),
          )
          render3d_draw_camera_custom_post_process_stage(
            source_world,
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
            clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
              cleared_targets_this_frame, stage_target_id, clear_enabled,
            ),
          )
          if camera.auto_exposure is Some(_) {
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
            clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
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
          current_source_texture_id = stage_target_id
          stage_index = stage_index + 1
        }
        if cas_postprocess_enabled {
          let stage_target_id = render3d_postprocess_stage_target(
            current_source_texture_id,
            scene_target_id,
            stage_ping_target_id,
            camera.target_id,
            stage_index,
            postprocess_stage_count,
          )
          let (
            cas_viewport_x,
            cas_viewport_y,
            cas_viewport_width,
            cas_viewport_height,
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
            viewport_x=cas_viewport_x,
            viewport_y=cas_viewport_y,
            viewport_width=cas_viewport_width,
            viewport_height=cas_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
              cleared_targets_this_frame, stage_target_id, clear_enabled,
            ),
          )
          render3d_draw_camera_cas_stage(
            current_source_texture_id,
            camera.contrast_adaptive_sharpening,
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
          clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
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
      clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
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

///|
fn render3d_fxaa_enabled(fxaa : Fxaa?) -> Bool {
  match fxaa {
    Some(value) => value.enabled
    None => false
  }
}

///|
fn render3d_cas_enabled(cas : @cas.ContrastAdaptiveSharpening?) -> Bool {
  match cas {
    Some(value) => value.enabled && value.sharpening_strength > 0.0F
    None => false
  }
}

///|
fn render3d_tonemapping_stage_enabled(
  tonemapping : Tonemapping?,
  deband_dither : DebandDither?,
  hdr_enabled : Bool,
  color_grading : ColorGrading?,
) -> Bool {
  deband_dither |> ignore
  let color_grading_enabled = color_grading is Some(_)
  if color_grading_enabled {
    return true
  }
  if !hdr_enabled {
    return false
  }
  match tonemapping {
    Some(None) => false
    Some(_) => true
    None => Tonemapping::default() != None
  }
}

///|
fn render3d_effect_stack_enabled(
  chromatic_aberration : ChromaticAberration?,
  vignette : Vignette?,
) -> Bool {
  render3d_chromatic_aberration_enabled(chromatic_aberration) ||
  render3d_vignette_enabled(vignette)
}

///|
fn render3d_custom_post_process_enabled(
  custom_post_process3d : CustomPostProcess3d?,
) -> Bool {
  match custom_post_process3d {
    Some(value) => value.enabled && value.shader_path.trim() != ""
    None => false
  }
}

///|
fn render3d_chromatic_aberration_enabled(
  chromatic_aberration : ChromaticAberration?,
) -> Bool {
  match chromatic_aberration {
    Some(value) => value.intensity > 0.0F && value.max_samples > 0
    None => false
  }
}

///|
fn render3d_vignette_enabled(vignette : Vignette?) -> Bool {
  match vignette {
    Some(value) => value.intensity > 0.0F
    None => false
  }
}

///|
fn render3d_tonemapping_lut_handles(
  world : @ecs.World,
) -> @core_pipeline.TonemappingLuts {
  @core_pipeline.tonemapping_luts_from_world_or_init(world)
}

///|
priv struct Render3dAutoExposureCurveGpuData {
  lut : Bytes
  min_log_lum : Float
  max_log_lum : Float
  min_compensation : Float
  max_compensation : Float
}

///|
fn render3d_default_auto_exposure_curve_gpu_data() -> Render3dAutoExposureCurveGpuData {
  Render3dAutoExposureCurveGpuData::{
    lut: Bytes::makei(256, _ => 0),
    min_log_lum: 0.0F,
    max_log_lum: 0.0F,
    min_compensation: 0.0F,
    max_compensation: 0.0F,
  }
}

///|
fn render3d_auto_exposure_curve_gpu_data(
  world : @ecs.World,
  curve_handle : @asset.Handle[AutoExposureCompensationCurve]?,
) -> Render3dAutoExposureCurveGpuData {
  let key : @ecs.ResourceKey[@asset.Assets[AutoExposureCompensationCurve]] = @asset.assets_resource_key()
  guard (try! world.get_resource(key)) is Some(curves) else {
    return render3d_default_auto_exposure_curve_gpu_data()
  }
  let resolved_handle = match curve_handle {
    Some(handle) => handle
    None => @asset.Handle::new(0)
  }
  match curves.get(resolved_handle) {
    Some(curve) =>
      Render3dAutoExposureCurveGpuData::{
        lut: curve.lut,
        min_log_lum: curve.min_log_lum,
        max_log_lum: curve.max_log_lum,
        min_compensation: curve.min_compensation,
        max_compensation: curve.max_compensation,
      }
    None => render3d_default_auto_exposure_curve_gpu_data()
  }
}

///|
fn render3d_apply_camera_auto_exposure(
  world : @ecs.World,
  camera_entity : @core.Entity,
  auto_exposure : AutoExposure,
  color_grading : @post_process.ColorGrading?,
  scene_texture_id : Int,
  view_width_logical : Int,
  view_height_logical : Int,
  delta_time : Float,
) -> Unit {
  if scene_texture_id < 0 || view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let curve = render3d_auto_exposure_curve_gpu_data(
    world,
    auto_exposure.compensation_curve,
  )
  let color_grading_uniform = @render.host_color_grading_from_post_process(
    color_grading,
  )
  @render.host_gpu_apply_auto_exposure(
    view_key_hi=camera_entity.id,
    view_key_lo=camera_entity.generation,
    scene_texture_id~,
    min_ev100=auto_exposure.min_ev100,
    max_ev100=auto_exposure.max_ev100,
    low_percent=auto_exposure.low_percent,
    high_percent=auto_exposure.high_percent,
    speed_brighten=auto_exposure.speed_brighten,
    speed_darken=auto_exposure.speed_darken,
    exponential_transition_distance=auto_exposure.exponential_transition_distance,
    delta_time~,
    color_grading=color_grading_uniform,
    metering_mask_texture_id=match auto_exposure.metering_mask {
      Some(mask) => mask.id()
      None => -1
    },
    compensation_curve_lut=curve.lut,
    compensation_curve_min_log_lum=curve.min_log_lum,
    compensation_curve_max_log_lum=curve.max_log_lum,
    compensation_curve_min_compensation=curve.min_compensation,
    compensation_curve_max_compensation=curve.max_compensation,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_bloom_clamp_unit(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_clamp_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_safe_max_mip_dimension(value : Int) -> Int {
  if value < 4 {
    4
  } else {
    value
  }
}

///|
fn render3d_bloom_safe_scale_axis(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_sanitize(bloom : Bloom) -> Bloom {
  let prefilter = BloomPrefilter::new(
    render3d_bloom_clamp_non_negative(bloom.prefilter.threshold),
    render3d_bloom_clamp_unit(bloom.prefilter.threshold_softness),
  )
  Bloom::new(render3d_bloom_clamp_non_negative(bloom.intensity))
  .with_low_frequency_boost(
    render3d_bloom_clamp_unit(bloom.low_frequency_boost),
  )
  .with_low_frequency_boost_curvature(
    render3d_bloom_clamp_unit(bloom.low_frequency_boost_curvature),
  )
  .with_high_pass_frequency(
    render3d_bloom_clamp_unit(bloom.high_pass_frequency),
  )
  .with_prefilter_settings(prefilter)
  .with_composite_mode(bloom.composite_mode)
  .with_max_mip_dimension(
    render3d_bloom_safe_max_mip_dimension(bloom.max_mip_dimension),
  )
  .with_scale(
    @math.Vec2::new(
      render3d_bloom_safe_scale_axis(bloom.scale.x),
      render3d_bloom_safe_scale_axis(bloom.scale.y),
    ),
  )
}

///|
fn render3d_tonemapping_mode_to_int(mode : Tonemapping) -> Int {
  match mode {
    None => 0
    Reinhard => 1
    ReinhardLuminance => 2
    AcesFitted => 3
    AgX => 4
    SomewhatBoringDisplayTransform => 5
    TonyMcMapface => 6
    BlenderFilmic => 7
  }
}

///|
fn render3d_fxaa_sensitivity_mode_int(sensitivity : FxaaSensitivity) -> Int {
  match sensitivity {
    Low => 0
    Medium => 1
    High => 2
    Ultra => 3
    Extreme => 4
  }
}

///|
fn render3d_fxaa_postprocess_values(fxaa : Fxaa?) -> (Int, Int, Int) {
  match fxaa {
    Some(value) =>
      (
        if value.enabled {
          1
        } else {
          0
        },
        render3d_fxaa_sensitivity_mode_int(value.edge_threshold),
        render3d_fxaa_sensitivity_mode_int(value.edge_threshold_min),
      )
    None =>
      (
        0,
        render3d_fxaa_sensitivity_mode_int(FxaaSensitivity::default()),
        render3d_fxaa_sensitivity_mode_int(FxaaSensitivity::default()),
      )
  }
}

///|
fn render3d_chromatic_aberration_postprocess_values(
  chromatic_aberration : ChromaticAberration?,
) -> (Float, Int) {
  match chromatic_aberration {
    Some(value) =>
      (
        if value.intensity < 0.0F {
          0.0F
        } else {
          value.intensity
        },
        if value.max_samples <= 0 {
          1
        } else {
          value.max_samples
        },
      )
    None => {
      let defaults = ChromaticAberration::default()
      (0.0F, defaults.max_samples)
    }
  }
}

///|
fn render3d_vignette_postprocess_values(
  vignette : Vignette?,
) -> (
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
) {
  match vignette {
    Some(value) => {
      let safe_edge_compensation = if value.edge_compensation < 0.0F {
        0.0F
      } else if value.edge_compensation > 1.0F {
        1.0F
      } else {
        value.edge_compensation
      }
      (
        if value.intensity < 0.0F {
          0.0F
        } else {
          value.intensity
        },
        if value.radius < 0.0F {
          0.0F
        } else {
          value.radius
        },
        if value.smoothness <= 0.01F {
          0.01F
        } else {
          value.smoothness
        },
        if value.roundness <= 0.01F {
          0.01F
        } else {
          value.roundness
        },
        value.center.x,
        value.center.y,
        safe_edge_compensation,
        value.color.r,
        value.color.g,
        value.color.b,
        value.color.a,
      )
    }
    None => {
      let defaults = Vignette::default()
      (
        0.0F,
        defaults.radius,
        defaults.smoothness,
        defaults.roundness,
        defaults.center.x,
        defaults.center.y,
        defaults.edge_compensation,
        defaults.color.r,
        defaults.color.g,
        defaults.color.b,
        defaults.color.a,
      )
    }
  }
}

///|
fn render3d_postprocess_stage_target(
  source_texture_id : Int,
  scene_texture_id : Int,
  ping_texture_id : Int,
  camera_target_id : Int,
  stage_index : Int,
  stage_count : Int,
) -> Int {
  if stage_index >= stage_count - 1 {
    camera_target_id
  } else if source_texture_id == ping_texture_id {
    scene_texture_id
  } else {
    ping_texture_id
  }
}

///|
fn render3d_draw_camera_effect_stack_stage(
  scene_texture_id : Int,
  chromatic_aberration : ChromaticAberration?,
  vignette : Vignette?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if !render3d_effect_stack_enabled(chromatic_aberration, vignette) {
    return
  }
  let (chromatic_aberration_intensity, chromatic_aberration_max_samples) = render3d_chromatic_aberration_postprocess_values(
    chromatic_aberration,
  )
  let (
    vignette_intensity,
    vignette_radius,
    vignette_smoothness,
    vignette_roundness,
    vignette_center_x,
    vignette_center_y,
    vignette_edge_compensation,
    vignette_color_r,
    vignette_color_g,
    vignette_color_b,
    vignette_color_a,
  ) = render3d_vignette_postprocess_values(vignette)
  @render.host_gpu_draw_effect_stack(
    scene_texture_id~,
    chromatic_aberration_intensity~,
    chromatic_aberration_max_samples~,
    vignette_intensity~,
    vignette_radius~,
    vignette_smoothness~,
    vignette_roundness~,
    vignette_center_x~,
    vignette_center_y~,
    vignette_edge_compensation~,
    vignette_color_r~,
    vignette_color_g~,
    vignette_color_b~,
    vignette_color_a~,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_draw_camera_custom_post_process_stage(
  source_world : @ecs.World,
  scene_texture_id : Int,
  custom_post_process3d : CustomPostProcess3d?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if !render3d_custom_post_process_enabled(custom_post_process3d) {
    return
  }
  guard custom_post_process3d is Some(custom_post_process) else { return }
  let shader_path = custom_post_process.shader_path.trim().to_owned()
  if @shader.shader_path_is_wesl(shader_path) {
    @shader.shader_register_wesl_runtime_source(source_world, shader_path, []) catch {
      err =>
        abort(
          "failed to compile render3d wesl postprocess shader: \{shader_path}: \{err.message()}",
        )
    }
  } else {
    @shader.shader_register_wgsl_runtime_source(source_world, shader_path)
  }
  @render.host_gpu_draw_custom_postprocess3d(
    scene_texture_id~,
    shader_path~,
    fragment_entry=if custom_post_process.fragment_entry.trim().to_owned() == "" {
      "fragment_main"
    } else {
      custom_post_process.fragment_entry.trim().to_owned()
    },
    uniform_x=custom_post_process.uniform_x,
    uniform_y=custom_post_process.uniform_y,
    uniform_z=custom_post_process.uniform_z,
    uniform_w=custom_post_process.uniform_w,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_draw_camera_tonemapping_stage(
  world : @ecs.World,
  scene_texture_id : Int,
  exposure : Exposure?,
  tonemapping : Tonemapping?,
  deband_dither : DebandDither?,
  color_grading : ColorGrading?,
  hdr_enabled : Bool,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  exposure |> ignore
  if !render3d_tonemapping_stage_enabled(
      tonemapping, deband_dither, hdr_enabled, color_grading,
    ) {
    return
  }
  let exposure_value = match exposure {
    Some(value) => value.exposure()
    None => Exposure::default().exposure()
  }
  let luts = render3d_tonemapping_lut_handles(world)
  let color_grading_uniform = @render.host_color_grading_from_post_process(
    color_grading,
  )
  @render.host_gpu_draw_tonemapping3d(
    scene_texture_id~,
    exposure=exposure_value,
    tonemapping_mode=match tonemapping {
      Some(mode) => render3d_tonemapping_mode_to_int(mode)
      None => 0
    },
    deband_dither_enabled=match deband_dither {
      Some(Enabled) => 1
      _ => 0
    },
    view_width=view_width_logical,
    view_height=view_height_logical,
    agx_lut_texture_id=luts.agx.id(),
    tony_lut_texture_id=luts.tony_mc_mapface.id(),
    blender_lut_texture_id=luts.blender_filmic.id(),
    color_grading=color_grading_uniform,
  )
}

///|
fn render3d_draw_camera_fxaa_stage(
  scene_texture_id : Int,
  fxaa : Fxaa?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  let (fxaa_enabled, fxaa_edge_threshold_mode, fxaa_edge_threshold_min_mode) = render3d_fxaa_postprocess_values(
    fxaa,
  )
  if fxaa_enabled == 0 {
    return
  }
  @render.host_gpu_draw_fxaa(
    scene_texture_id~,
    fxaa_enabled~,
    fxaa_edge_threshold_mode~,
    fxaa_edge_threshold_min_mode~,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_draw_camera_cas_stage(
  scene_texture_id : Int,
  cas : @cas.ContrastAdaptiveSharpening?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  guard render3d_cas_enabled(cas) else { return }
  guard cas is Some(value) else { return }
  @render.host_gpu_draw_contrast_adaptive_sharpening(
    scene_texture_id~,
    sharpness=value.sharpening_strength,
    denoise=value.denoise,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_draw_camera_bloom_stage(
  scene_texture_id : Int,
  bloom : Bloom,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if scene_texture_id < 0 || view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let settings = render3d_bloom_sanitize(bloom)
  @render.host_gpu_apply_bloom(
    scene_texture_id~,
    intensity=settings.intensity,
    low_frequency_boost=settings.low_frequency_boost,
    low_frequency_boost_curvature=settings.low_frequency_boost_curvature,
    high_pass_frequency=settings.high_pass_frequency,
    threshold=settings.prefilter.threshold,
    threshold_softness=settings.prefilter.threshold_softness,
    composite_mode=match settings.composite_mode {
      EnergyConserving => 0
      Additive => 1
    },
    max_mip_dimension=settings.max_mip_dimension,
    scale_x=settings.scale.x,
    scale_y=settings.scale.y,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}
