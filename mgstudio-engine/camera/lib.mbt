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
// Bevy source: `bevy/crates/bevy_camera/src/lib.rs`.

///|
const CAMERA_PROJECTION_PLUGIN_NAME : String = "mgstudio.camera.CameraProjectionPlugin"

///|
const CAMERA_PLUGIN_NAME : String = "mgstudio.camera.CameraPlugin"

///|
pub let camera_update_systems : @app.SystemSet = @app.system_set(
  "mgstudio.camera.update",
)

///|
pub struct CameraProjectionPlugin {}

///|
pub fn CameraProjectionPlugin::CameraProjectionPlugin() -> CameraProjectionPlugin {
  CameraProjectionPlugin::{  }
}

///|
pub impl @app.Plugin for CameraProjectionPlugin with fn name(_self) {
  CAMERA_PROJECTION_PLUGIN_NAME
}

///|
pub impl @app.Plugin for CameraProjectionPlugin with fn build(_self, app) {
  camera_projection_plugin(app)
}

///|
pub struct CameraPlugin {}

///|
pub fn CameraPlugin::CameraPlugin() -> CameraPlugin {
  CameraPlugin::{  }
}

///|
pub impl @app.Plugin for CameraPlugin with fn name(_self) {
  CAMERA_PLUGIN_NAME
}

///|
pub impl @app.Plugin for CameraPlugin with fn build(_self, app) {
  camera_plugin(app)
}

///|
pub fn camera_projection_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .add_post_update_system_config(
    @app.system(@pbr.render3d_camera_system)
    .named("mgstudio.pbr.render3d_camera_system")
    .in_set(camera_update_systems)
    .after(@transform.transform_set_propagate),
  )
  .add_post_update_system_config(
    @app.system(@pbr.render3d_update_frusta_system)
    .named("mgstudio.pbr.render3d_update_frusta")
    .in_set(camera_update_systems)
    .after("mgstudio.pbr.render3d_camera_system")
    .after(@transform.transform_set_propagate),
  )
}

///|
pub fn camera_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let world = app.world()
  @camera_camera.ensure_camera_required_components(world)
  @camera_components2d.ensure_camera2d_required_components(world)
  world.register_required_components_with(
    ecs_key_camera3d,
    @post_process.ecs_key_color_grading,
    fn() { @post_process.ColorGrading::ColorGrading() },
  ) catch {
    @ecs.RequiredComponentsError::DuplicateRegistration(_, _) => ()
    @ecs.RequiredComponentsError::ArchetypeExists(component_id) =>
      abort(
        "CameraPlugin required-component registration ran too late for component \{component_id}",
      )
    @ecs.RequiredComponentsError::CyclicRequirement(requiree, required) =>
      abort(
        "CameraPlugin required-component cycle detected: \{requiree} -> \{required}",
      )
  }
  world.register_required_components_with(
    ecs_key_camera3d,
    @camera_camera.ecs_key_exposure,
    fn() { @camera_camera.Exposure::Exposure() },
  ) catch {
    @ecs.RequiredComponentsError::DuplicateRegistration(_, _) => ()
    @ecs.RequiredComponentsError::ArchetypeExists(component_id) =>
      abort(
        "CameraPlugin required-component registration ran too late for component \{component_id}",
      )
    @ecs.RequiredComponentsError::CyclicRequirement(requiree, required) =>
      abort(
        "CameraPlugin required-component cycle detected: \{requiree} -> \{required}",
      )
  }
  app
  .init_resource(fn() { @camera_clear_color.ClearColor::ClearColor() })
  .add_plugins(CameraProjectionPlugin::CameraProjectionPlugin())
  .add_plugins(@camera_visibility.VisibilityPlugin::VisibilityPlugin())
  .add_plugins(
    @camera_visibility.VisibilityRangePlugin::VisibilityRangePlugin(),
  )
}
