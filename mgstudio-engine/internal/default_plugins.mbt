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
#warnings("-unnecessary_annotation")
fn default_plugins_marker() -> DefaultPlugins {
  DefaultPlugins::{  }
}

///|
const DEFAULT_PLUGINS_NAME : String = "DefaultPlugins"

///|
const MINIMAL_PLUGINS_NAME : String = "MinimalPlugins"

///|
fn default_plugins_env_present(key : String) -> Bool {
  match @sys.get_env_var(key) {
    Some(value) => value.trim().to_owned() != ""
    None => false
  }
}

///|
fn default_plugins_ci_testing_enabled() -> Bool {
  default_plugins_env_present("CI_TESTING_CONFIG") ||
  default_plugins_env_present("CI_TESTING_SCREENSHOT_FRAME") ||
  default_plugins_env_present("CI_TESTING_SCREENSHOT_AND_EXIT_FRAME") ||
  default_plugins_env_present("CI_TESTING_EXIT_FRAME") ||
  default_plugins_env_present("CI_TESTING_FIXED_FRAME_TIME_MS") ||
  default_plugins_env_present("CI_TESTING_FIXED_FRAME_TIME_US") ||
  default_plugins_env_present("MGSTUDIO_PARITY_CAPTURE_RGBA8_BLOB") ||
  default_plugins_env_present("MGSTUDIO_SCREENSHOT_PATH")
}

///|
fn default_plugins_add_ci_testing_if_enabled(
  builder : @app.PluginGroupBuilder[@ecs.World],
) -> @app.PluginGroupBuilder[@ecs.World] {
  if default_plugins_ci_testing_enabled() {
    builder.add(@dev_tools_ci_testing.CiTestingPlugin::CiTestingPlugin())
  } else {
    builder
  }
}

///|
fn default_plugins_builder(
  asset_plugin : @asset.AssetPlugin,
) -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named(DEFAULT_PLUGINS_NAME)
  .add(@app.LogPlugin::LogPlugin())
  .add(@diagnostic.FrameCountPlugin::FrameCountPlugin())
  .add(@time.TimePlugin::TimePlugin())
  .add(@transform.TransformPlugin::TransformPlugin())
  .add(@diagnostic.DiagnosticsPlugin::DiagnosticsPlugin())
  .add(@input.InputPlugin::InputPlugin())
  .add(@input_focus.InputDispatchPlugin::InputDispatchPlugin())
  .add(@window.WindowPlugin::WindowPlugin())
  .add(@a11y.AccessibilityPlugin::AccessibilityPlugin())
  .add(
    @asset.WebAssetPlugin::WebAssetPlugin().with_silence_startup_warning(true),
  )
  .add(asset_plugin)
  .add(@shader.ShaderPlugin::ShaderPlugin())
  .add(@scene.ScenePlugin::ScenePlugin())
  .add(@winit.WinitPlugin::WinitPlugin())
  .add(@render.RenderPlugin::RenderPlugin())
  .add(@mesh.MeshPlugin::MeshPlugin())
  .add(@camera.CameraPlugin::CameraPlugin())
  .add(@light.LightPlugin::LightPlugin())
  .add(@light_cluster.ClusterLightPlugin::ClusterLightPlugin())
  .add(@core_pipeline.CorePipelinePlugin::CorePipelinePlugin())
  .add(@post_process.PostProcessPlugin::PostProcessPlugin())
  .add(@anti_alias.AntiAliasPlugin::AntiAliasPlugin())
  .add(@sprite.SpritePlugin::SpritePlugin())
  .add(@sprite_render.SpriteRenderPlugin::SpriteRenderPlugin())
  .add(@text.TextPlugin::TextPlugin())
  .add(@sprite_render_text2d.Text2dRenderPlugin::Text2dRenderPlugin())
  .add(@ui.UiPlugin::UiPlugin())
  .add(@ui_render.UiRenderPlugin::UiRenderPlugin())
  .add(@gltf_loader.GltfPlugin::GltfPlugin())
  .add(@pbr.PbrPlugin::PbrPlugin())
  .add(@audio.AudioPlugin::AudioPlugin())
  .add(@animation.AnimationPlugin::AnimationPlugin())
  .add(@gizmos.GizmoPlugin::GizmoPlugin())
  .add(@gizmos_render.GizmoRenderPlugin::GizmoRenderPlugin())
  .add(@app.StatesPlugin::StatesPlugin())
  .add(@ui_widgets.UiWidgetsPlugins::UiWidgetsPlugins())
  .add(@picking.PointerInputPlugin::PointerInputPlugin())
  .add(@picking.PickingPlugin::PickingPlugin())
  .add(@picking.InteractionPlugin::InteractionPlugin())
  .add(@physics2d.Physics2dPlugin::Physics2dPlugin())
  .add(@physics3d.Physics3dPlugin::Physics3dPlugin())
  |> default_plugins_add_ci_testing_if_enabled
}

///|
pub fn DefaultPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  default_plugins_marker() |> ignore
  default_plugins_builder(AssetPlugin())
}

///|
pub fn[P : @app.Plugin] DefaultPlugins::set(
  replacement : P,
) -> @app.PluginGroupBuilder[@ecs.World] {
  default_plugins_marker() |> ignore
  DefaultPlugins::build().set(replacement)
}

///|
pub struct MinimalPlugins {}

///|
#warnings("-unnecessary_annotation")
fn minimal_plugins_marker() -> MinimalPlugins {
  MinimalPlugins::{  }
}

///|
fn minimal_plugins_builder() -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named(MINIMAL_PLUGINS_NAME)
  .add(@diagnostic.FrameCountPlugin::FrameCountPlugin())
  .add(@app.StatesPlugin::StatesPlugin())
  .add(@time.TimePlugin::TimePlugin())
  .add(@app.ScheduleRunnerPlugin::run_loop(0.0F))
  |> default_plugins_add_ci_testing_if_enabled
}

///|
pub fn MinimalPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  minimal_plugins_marker() |> ignore
  minimal_plugins_builder()
}
