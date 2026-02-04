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
pub(open) trait DefaultPluginsWorld: @core.ChangeTickWorld + @core.SystemContextWorld + @core.SpawnWorld + @math.Has_Transform + @hierarchy.Has_Parent + @hierarchy.Has_Children + @transform.Has_GlobalTransform + @visibility.Has_Visibility + @visibility.Has_InheritedVisibility + @visibility.Has_ViewVisibility + @render2d.HasRes_RenderState + @render2d.Has_RenderLayers + @render2d.Has_Sprite + @render2d.Has_Anchor + @render2d.Has_Camera2d + @render2d.Has_Camera + @render2d.Has_Projection + @render2d.Has_RenderTarget + @render2d.Has_Mesh2d + @render2d.Has_ColorMaterial + @render2d.Has_GpuMesh2d + @physics2d.Has_RigidBody2d + @physics2d.Has_Collider2d + @physics2d.Has_Velocity2d + @physics2d.Has_Damping2d + @physics2d.Has_GravityScale2d + @physics2d.Has_LockedAxes2d + @physics2d.Has_Ccd2d + @physics2d.Has_Dominance2d + @physics2d.Has_Sleeping2d + @physics2d.Has_ExternalForce2d + @physics2d.Has_ExternalImpulse2d + @physics2d.Has_ContactForceEventThreshold2d + @physics2d.Has_ColliderDensity2d + @physics2d.Has_Friction2d + @physics2d.Has_FrictionCombineRule2d + @physics2d.Has_Restitution2d + @physics2d.Has_RestitutionCombineRule2d + @physics2d.Has_CollisionGroups2d + @physics2d.Has_SolverGroups2d + @physics2d.Has_ImpulseJoint2d + @physics2d.Has_MultibodyJoint2d + @physics2d.Has_RapierBodyHandle2d + @physics2d.Has_RapierColliderHandle2d + @physics2d.Has_RapierImpulseJointHandle2d + @physics2d.Has_RapierMultibodyJointHandle2d + @physics2d.HasRes_Physics2dConfig + @physics2d.HasRes_Physics2dContext + @physics2d.HasRes_Physics2dEvents + @physics3d.Has_RigidBody3d + @physics3d.Has_Collider3d + @physics3d.Has_Velocity3d + @physics3d.Has_RapierBodyHandle3d + @physics3d.Has_RapierColliderHandle3d + @physics3d.HasRes_Physics3dConfig + @physics3d.HasRes_Physics3dContext + @physics3d.HasRes_Physics3dEvents + @ui.HasRes_UiContext + @ui.Has_UiRoot + @ui.Has_Style + @ui.Has_UiLayout + @ui.Has_BackgroundColor + @ui.Has_UiImage + @ui.Has_ButtonColors + @ui.Has_Button + @ui.Has_Interaction + @ui.Has_UiText {
}

///|
/// `@ecs_world.World` already implements all the capability traits required by
/// `DefaultPluginsWorld`, so we expose a marker impl here.
pub impl DefaultPluginsWorld for @ecs_world.World

///|
/// Default plugin bundle, aligned with Bevy's `DefaultPlugins` concept.
pub fn[W : DefaultPluginsWorld] default_plugins() -> Array[@app.Plugin[W]] {
  [
    fn(app : @app.App[W]) -> @app.App[W] { @window.window_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @time.time_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @asset.asset_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @transform.transform_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @physics2d.physics2d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @physics3d.physics3d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @visibility.visibility_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @ui.ui_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @render2d.render2d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @text.text_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @input.input_plugin(app) },
  ]
}

///|
/// Default plugin bundle with "nearest" sampling for textures (useful for pixel art).
pub fn[W : DefaultPluginsWorld] default_plugins_nearest() -> Array[
  @app.Plugin[W],
] {
  [
    fn(app : @app.App[W]) -> @app.App[W] { @window.window_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @time.time_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @asset.asset_plugin_nearest(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @transform.transform_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @physics2d.physics2d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @physics3d.physics3d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @visibility.visibility_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @ui.ui_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @render2d.render2d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @text.text_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @input.input_plugin(app) },
  ]
}
