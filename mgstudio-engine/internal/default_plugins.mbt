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
pub struct DefaultPlugins {}

///|
pub fn DefaultPlugins::build() -> Array[@app.Plugin[@ecs.World]] {
  default_plugins()
}

///|
pub struct MinimalPlugins {}

///|
pub fn MinimalPlugins::build() -> Array[@app.Plugin[@ecs.World]] {
  minimal_plugins()
}

///|
/// Default plugin bundle, aligned with Bevy's `DefaultPlugins` concept.
pub fn default_plugins() -> Array[@app.Plugin[@ecs.World]] {
  [
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.log_plugin_default(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.task_pool_plugin(@app.TaskPoolPlugin::default())(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @window.window_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @diagnostics.frame_count_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.states_plugin(@app.StatesPlugin::default())(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @time.time_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @asset.asset_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @audio.audio_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @scene.scene_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @animation.animation_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @transform.transform_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @diagnostics.diagnostics_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @visibility.visibility_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @input.input_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @picking.picking_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @a11y.a11y_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @ui.ui_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @text.text_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @render3d.render3d_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @render2d.render2d_plugin_ecs(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @physics2d.physics2d_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @physics3d.physics3d_plugin(app)
    },
  ]
}

///|
/// Default plugin bundle with "nearest" sampling for textures (useful for pixel art).
pub fn default_plugins_nearest() -> Array[@app.Plugin[@ecs.World]] {
  [
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.log_plugin_default(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.task_pool_plugin(@app.TaskPoolPlugin::default())(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @window.window_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @diagnostics.frame_count_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.states_plugin(@app.StatesPlugin::default())(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @time.time_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @asset.asset_plugin_nearest(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @audio.audio_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @scene.scene_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @animation.animation_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @transform.transform_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @diagnostics.diagnostics_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @visibility.visibility_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @input.input_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @picking.picking_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @a11y.a11y_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @ui.ui_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @text.text_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @render3d.render3d_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @render2d.render2d_plugin_ecs(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @physics2d.physics2d_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @physics3d.physics3d_plugin(app)
    },
  ]
}

///|
/// Minimal plugin bundle, aligned with Bevy's `MinimalPlugins` concept.
pub fn minimal_plugins() -> Array[@app.Plugin[@ecs.World]] {
  [
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.task_pool_plugin(@app.TaskPoolPlugin::default())(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @diagnostics.frame_count_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.states_plugin(@app.StatesPlugin::default())(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @time.time_plugin(app)
    },
    fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.schedule_runner_plugin(@app.ScheduleRunnerPlugin::run_loop(0.0F))(
        app,
      )
    },
  ]
}
