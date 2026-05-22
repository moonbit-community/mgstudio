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
fn default_plugins_marker() -> DefaultPlugins {
  DefaultPlugins::{  }
}

///|
const DEFAULT_PLUGINS_NAME : String = "DefaultPlugins"

///|
const MINIMAL_PLUGINS_NAME : String = "MinimalPlugins"

///|
fn default_plugins_builder(
  asset_plugin : @asset.AssetPlugin,
) -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named(DEFAULT_PLUGINS_NAME)
  .add(@app.LogPlugin::LogPlugin())
  .add(@window.WindowPlugin::WindowPlugin())
  .add(@a11y.AccessibilityPlugin::AccessibilityPlugin())
  .add(@winit.WinitPlugin::WinitPlugin())
  .add(@diagnostic.FrameCountPlugin::FrameCountPlugin())
  .add(@app.StatesPlugin::StatesPlugin())
  .add(@time.TimePlugin::TimePlugin())
  .add(
    @asset.WebAssetPlugin::WebAssetPlugin().with_silence_startup_warning(true),
  )
  .add(asset_plugin)
  .add(@shader.ShaderPlugin::ShaderPlugin())
  .add(@audio.AudioPlugin::AudioPlugin())
  .add(@scene.ScenePlugin::ScenePlugin())
  .add(@animation.AnimationPlugin::AnimationPlugin())
  .add(@transform.TransformPlugin::TransformPlugin())
  .add(@diagnostic.DiagnosticsPlugin::DiagnosticsPlugin())
  .add(@render.RenderPlugin::RenderPlugin())
  .add(@mesh.MeshPlugin::MeshPlugin())
  .add(@camera.CameraPlugin::CameraPlugin())
  .add(@light.LightPlugin::LightPlugin())
  .add(@light_cluster.ClusterLightPlugin::ClusterLightPlugin())
  .add(@core_pipeline.CorePipelinePlugin::CorePipelinePlugin())
  .add(@input.InputPlugin::InputPlugin())
  .add(@picking.PointerInputPlugin::PointerInputPlugin())
  .add(@picking.PickingPlugin::PickingPlugin())
  .add(@picking.InteractionPlugin::InteractionPlugin())
  .add(@ui.UiPlugin::UiPlugin())
  .add(@ui_render.UiRenderPlugin::UiRenderPlugin())
  .add(@gltf_loader.GltfPlugin::GltfPlugin())
  .add(@text.TextPlugin::TextPlugin())
  .add(@pbr.PbrPlugin::PbrPlugin())
  .add(@anti_alias.AntiAliasPlugin::AntiAliasPlugin())
  .add(@sprite.SpritePlugin::SpritePlugin())
  .add(@sprite_render.SpriteRenderPlugin::SpriteRenderPlugin())
  .add(@gizmos.GizmoPlugin::GizmoPlugin())
  .add(@gizmos_render.GizmoRenderPlugin::GizmoRenderPlugin())
  .add(@physics2d.Physics2dPlugin::Physics2dPlugin())
  .add(@physics3d.Physics3dPlugin::Physics3dPlugin())
}

///|
pub fn DefaultPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  default_plugins_marker() |> ignore
  default_plugins_builder(@asset.AssetPlugin::AssetPlugin())
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
}

///|
pub fn MinimalPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  minimal_plugins_marker() |> ignore
  minimal_plugins_builder()
}
