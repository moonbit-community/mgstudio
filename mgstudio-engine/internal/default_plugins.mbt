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
  .add(@app.LogPlugin::default())
  .add(@window.WindowPlugin::default())
  .add(@a11y.AccessibilityPlugin::default())
  .add(@winit.WinitPlugin::default())
  .add(@diagnostic.FrameCountPlugin::default())
  .add(@app.StatesPlugin::default())
  .add(@time.TimePlugin::default())
  .add(@asset.WebAssetPlugin::default().with_silence_startup_warning(true))
  .add(asset_plugin)
  .add(@shader.ShaderPlugin::default())
  .add(@audio.AudioPlugin::default())
  .add(@scene.ScenePlugin::default())
  .add(@animation.AnimationPlugin::default())
  .add(@transform.TransformPlugin::default())
  .add(@diagnostic.DiagnosticsPlugin::default())
  .add(@render.RenderPlugin::default())
  .add(@mesh.MeshPlugin::default())
  .add(@camera.CameraPlugin::default())
  .add(@light.LightPlugin::default())
  .add(@light_cluster.ClusterLightPlugin::default())
  .add(@core_pipeline.CorePipelinePlugin::default())
  .add(@input.InputPlugin::default())
  .add(@picking.PointerInputPlugin::default())
  .add(@picking.PickingPlugin::default())
  .add(@picking.InteractionPlugin::default())
  .add(@ui.UiPlugin::default())
  .add(@ui_render.UiRenderPlugin::default())
  .add(@gltf_loader.GltfPlugin::default())
  .add(@text.TextPlugin::default())
  .add(@pbr.PbrPlugin::default())
  .add(@anti_alias.AntiAliasPlugin::default())
  .add(@sprite.SpritePlugin::default())
  .add(@sprite_render.SpriteRenderPlugin::default())
  .add(@gizmos.GizmoPlugin::default())
  .add(@gizmos_render.GizmoRenderPlugin::default())
  .add(@physics2d.Physics2dPlugin::default())
  .add(@physics3d.Physics3dPlugin::default())
}

///|
pub fn DefaultPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  default_plugins_marker() |> ignore
  default_plugins_builder(@asset.AssetPlugin::default())
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
  .add(@diagnostic.FrameCountPlugin::default())
  .add(@app.StatesPlugin::default())
  .add(@time.TimePlugin::default())
  .add(@app.ScheduleRunnerPlugin::run_loop(0.0F))
}

///|
pub fn MinimalPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  minimal_plugins_marker() |> ignore
  minimal_plugins_builder()
}
