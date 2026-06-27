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
// Bevy source: `bevy/crates/bevy_post_process/src/motion_blur/mod.rs`.

///|
const MOTION_BLUR_PLUGIN_NAME : String = "mgstudio.post_process.motion_blur.MotionBlurPlugin"

///|
pub struct MotionBlurPlugin {}

///|
pub fn MotionBlurPlugin::MotionBlurPlugin() -> MotionBlurPlugin {
  MotionBlurPlugin::{  }
}

///|
pub impl @app.Plugin for MotionBlurPlugin with fn name(_self) {
  MOTION_BLUR_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MotionBlurPlugin with fn build(self, app) {
  motion_blur_plugin_with(app, self)
}

///|
pub struct MotionBlur {
  shutter_angle : Float
  samples : Int
} derive(ToJson, FromJson)

///|
pub fn MotionBlur::MotionBlur() -> MotionBlur {
  MotionBlur::{ shutter_angle: 0.5F, samples: 1 }
}

///|
pub fn MotionBlur::new(shutter_angle : Float, samples : Int) -> MotionBlur {
  let safe_shutter_angle = if shutter_angle < 0.0F {
    0.0F
  } else {
    shutter_angle
  }
  let safe_samples = if samples < 0 { 0 } else { samples }
  MotionBlur::{ shutter_angle: safe_shutter_angle, samples: safe_samples }
}

///|
pub fn MotionBlur::with_shutter_angle(
  self : MotionBlur,
  shutter_angle : Float,
) -> MotionBlur {
  MotionBlur::new(shutter_angle, self.samples)
}

///|
pub fn MotionBlur::with_samples(self : MotionBlur, samples : Int) -> MotionBlur {
  MotionBlur::new(self.shutter_angle, samples)
}

///|
pub let ecs_key_motion_blur : @ecs.ComponentKey[MotionBlur] = @ecs.register_component(
  debug_name="render3d.motion_blur",
)

///|
pub impl @ecs.Component for MotionBlur with fn component() {
  ecs_key_motion_blur
}

///|
pub struct MotionBlurUniform {
  shutter_angle : Float
  samples : Int
}

///|
pub fn MotionBlurUniform::MotionBlurUniform() -> MotionBlurUniform {
  MotionBlurUniform::{ shutter_angle: 0.5F, samples: 1 }
}

///|
pub fn MotionBlurUniform::new(
  shutter_angle : Float,
  samples : Int,
) -> MotionBlurUniform {
  let settings = MotionBlur::new(shutter_angle, samples)
  MotionBlurUniform::{
    shutter_angle: settings.shutter_angle,
    samples: settings.samples,
  }
}

///|
pub let ecs_key_motion_blur_uniform : @ecs.ComponentKey[MotionBlurUniform] = @ecs.register_component(
  debug_name="render3d.motion_blur_uniform",
)

///|
pub impl @ecs.Component for MotionBlurUniform with fn component() {
  ecs_key_motion_blur_uniform
}

///|
pub fn MotionBlur::extract_uniform(self : MotionBlur) -> MotionBlurUniform {
  MotionBlurUniform::new(self.shutter_angle, self.samples)
}

///|
pub fn motion_blur_extract_uniform(settings : MotionBlur) -> MotionBlurUniform {
  settings.extract_uniform()
}

///|
pub fn motion_blur_uniform_is_active(uniform : MotionBlurUniform) -> Bool {
  uniform.samples > 0 && uniform.shutter_angle > 0.0F
}

///|
pub fn motion_blur_component_key() -> @ecs.ComponentKey[MotionBlur] {
  ecs_key_motion_blur
}

///|
pub fn motion_blur_uniform_component_key() -> @ecs.ComponentKey[
  MotionBlurUniform,
] {
  ecs_key_motion_blur_uniform
}

///|
fn remove_motion_blur_sync_target(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> @ecs.World {
  ignore(
    render_world.remove_by_key(render_entity, ecs_key_motion_blur_uniform) catch {
      _ => false
    },
  )
  render_world
}

///|
pub fn extract_motion_blur_uniforms(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  ignore(
    render_world
    .components_registrator()
    .register_component_by_key(ecs_key_motion_blur_uniform),
  )
  let extracted : Array[(@core.Entity, MotionBlurUniform)] = []
  let query : @ecs.Query[
    (
      @ecs.Read[@render.RenderEntity],
      @ecs.Read[@camera_camera.Camera],
      @ecs.Read[MotionBlur],
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! query.view(fn(_entity, data) {
    let (render_entity_comp, _camera_comp, motion_blur_comp) = data
    extracted.push(
      (
        render_entity_comp.value().id(),
        motion_blur_comp.value().extract_uniform(),
      ),
    )
  })
  for item in extracted {
    let (entity, uniform) = item
    render_world.set_by_key(entity, ecs_key_motion_blur_uniform, uniform) catch {
      _ =>
        abort(
          "motion_blur: failed to extract MotionBlurUniform to render world",
        )
    }
  }
}

///|
pub fn prepare_view_depth_texture_usages_for_motion_blur(
  render_world : @ecs.World,
) -> Unit {
  let query : @ecs.Query[
    (@ecs.Write[@camera_components3d.Camera3d], @ecs.Read[MotionBlurUniform]),
    @ecs.All,
  ] = @ecs.query(render_world)
  try! query.view(fn(_entity, data) {
    let (camera3d_write, _uniform_comp) = data
    let camera3d = camera3d_write.value()
    camera3d_write.set(
      camera3d.with_depth_texture_usages(
        camera3d.depth_texture_usages().with_texture_binding(),
      ),
    )
  })
}

///|
pub fn motion_blur_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(MotionBlurPlugin::MotionBlurPlugin())
}

///|
pub fn motion_blur_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : MotionBlurPlugin,
) -> @app.App[@ecs.World] {
  register_embedded_wgsl_sources()
  let sync_component : @render.SyncComponentPlugin[MotionBlur, MotionBlurPlugin] = @render.SyncComponentPlugin::SyncComponentPlugin()
  let next = @render.sync_component_plugin_with_target_removal(
    app, sync_component, remove_motion_blur_sync_target,
  )
  @render.try_with_render_app(next, fn(render_app) {
    render_app
    .add_systems(
      @render.render_startup_schedule_stage(),
      @app.system(init_motion_blur_pipeline).named(
        "mgstudio_post_process::init_motion_blur_pipeline",
      ),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(extract_motion_blur_uniforms)
      .named("mgstudio_post_process::extract_motion_blur_uniforms")
      .in_set(@render.render_system_set_extract_commands),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(prepare_motion_blur_pipelines)
      .named("mgstudio_post_process::prepare_motion_blur_pipelines")
      .in_set(@render.render_system_set_prepare),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(prepare_view_depth_texture_usages_for_motion_blur)
      .named(
        "mgstudio_post_process::prepare_view_depth_texture_usages_for_motion_blur",
      )
      .in_set(@render.render_system_set_prepare_views),
    )
  })
}

///|
pub fn motion_blur_generate_samples(
  settings : MotionBlur,
) -> Array[MotionBlurSample] {
  motion_blur_samples(settings)
}
