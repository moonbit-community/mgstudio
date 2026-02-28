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
/// A single "capability trait" that represents the world requirements of
/// `default_plugins()`.
///
/// Motivation:
/// - Each plugin (window/time/asset/...) requires a set of `Has_*` traits on `W`.
///   When composing plugins into a single bundle, the bounds become the union and
///   get very long.
/// - This trait gives that union a stable name, so public signatures and error
///   messages stay readable.
///
/// Note: This does not reduce the actual requirements; it only names them.
pub(open) trait DefaultPluginsWorld: @core.ChangeTickWorld + @core.SystemContextWorld + @scene.ScenePluginWorld + @animation.AnimationPluginWorld + @transform.TransformPropagationWorld + @visibility.VisibilityPropagationWorld + @picking.PickingPluginWorld + @a11y.HasRes_A11yState + @ui.UiPluginWorld + @render2d.RenderExtractWorld + @render2d.CameraPostProcessWorld + @render3d.Render3dPluginWorld + @physics2d.Physics2dPluginWorld + @physics3d.Physics3dPluginWorld {
}

///|
/// `@ecs_world.World` already implements all the capability traits required by
/// `DefaultPluginsWorld`, so we expose a marker impl here.
pub impl DefaultPluginsWorld for @ecs_world.World

///|
/// Default plugin bundle, aligned with Bevy's `DefaultPlugins` concept.
pub fn[W : DefaultPluginsWorld] default_plugins() -> Array[@app.Plugin[W]] {
  [
    fn(app : @app.App[W]) -> @app.App[W] { @app.log_plugin_default(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @window.window_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @time.time_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @asset.asset_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @scene.scene_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @animation.animation_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @transform.transform_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @visibility.visibility_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @input.input_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @picking.picking_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @a11y.a11y_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @ui.ui_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @text.text_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @render3d.render3d_plugin(app) },
    // Overlay producers (UI/text/gizmos) must run before render2d extract,
    // otherwise their overlay sprites will miss the current frame.
    fn(app : @app.App[W]) -> @app.App[W] { @render2d.render2d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @physics2d.physics2d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @physics3d.physics3d_plugin(app) },
  ]
}

///|
/// Default plugin bundle with "nearest" sampling for textures (useful for pixel art).
pub fn[W : DefaultPluginsWorld] default_plugins_nearest() -> Array[
  @app.Plugin[W],
] {
  [
    fn(app : @app.App[W]) -> @app.App[W] { @app.log_plugin_default(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @window.window_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @time.time_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @asset.asset_plugin_nearest(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @scene.scene_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @animation.animation_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @transform.transform_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @visibility.visibility_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @input.input_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @picking.picking_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @a11y.a11y_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @ui.ui_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @text.text_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @render3d.render3d_plugin(app) },
    // Overlay producers (UI/text/gizmos) must run before render2d extract,
    // otherwise their overlay sprites will miss the current frame.
    fn(app : @app.App[W]) -> @app.App[W] { @render2d.render2d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @physics2d.physics2d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @physics3d.physics3d_plugin(app) },
  ]
}
