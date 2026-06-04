// Copyright 2026 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_dev_tools/src/easy_screenshot.rs`.

///|
const EASY_CAMERA_MOVEMENT_PLUGIN_NAME : String = "mgstudio.dev_tools.EasyCameraMovementPlugin"

///|
pub struct EasyCameraMovementPlugin {
  decay_rate : Float
}

///|
pub fn EasyCameraMovementPlugin::EasyCameraMovementPlugin() -> EasyCameraMovementPlugin {
  EasyCameraMovementPlugin::{ decay_rate: 1.0F }
}

///|
pub fn EasyCameraMovementPlugin::with_decay_rate(
  self : EasyCameraMovementPlugin,
  decay_rate : Float,
) -> EasyCameraMovementPlugin {
  self |> ignore
  EasyCameraMovementPlugin::{ decay_rate, }
}

///|
pub struct CameraMovement {
  translation : @math.Vec3
  rotation : @math.Quat
}

///|
pub fn CameraMovement::CameraMovement(
  translation : @math.Vec3,
  rotation : @math.Quat,
) -> CameraMovement {
  CameraMovement::{ translation, rotation }
}

///|
pub let ecs_key_camera_movement : @ecs.ComponentKey[CameraMovement] = @ecs.register_component(
  debug_name="mgstudio_dev_tools::CameraMovement",
)

///|
pub impl @ecs.Component for CameraMovement with fn component() {
  ecs_key_camera_movement
}

///|
pub impl @app.Plugin for EasyCameraMovementPlugin with fn name(_self) {
  EASY_CAMERA_MOVEMENT_PLUGIN_NAME
}

///|
pub impl @app.Plugin for EasyCameraMovementPlugin with fn build(self, app) {
  easy_camera_movement_plugin_with(app, self)
}

///|
fn easy_camera_movement_smooth_factor(
  decay_rate : Float,
  delta : Float,
) -> Float {
  if decay_rate <= 0.0F || delta <= 0.0F {
    return 0.0F
  }
  1.0F - @math.pow(2.718281828459045F, -decay_rate * delta)
}

///|
fn easy_camera_movement_system(
  decay_rate : Float,
  time : @app.Res[@time.Time[Unit]],
  cameras : @ecs.Query[
    (@ecs.Mut[@transform.Transform], @ecs.Comp[CameraMovement]),
    @ecs.With[@camera.Camera],
  ],
) -> Unit {
  guard (cameras.require_single() catch { _ => return })
    is (transform_mut, movement_comp) else {
    return
  }
  let movement = movement_comp.value()
  let delta = time.get().delta_secs()
  let factor = easy_camera_movement_smooth_factor(decay_rate, delta)
  if factor <= 0.0F {
    return
  }
  let transform = transform_mut.value()
  transform.translation.smooth_nudge(movement.translation, decay_rate, delta)
  transform.rotation = transform.rotation.lerp(movement.rotation, factor)
  transform_mut.set(transform)
}

///|
pub fn easy_camera_movement_plugin_with(
  app : @app.App[@ecs.World],
  plugin : EasyCameraMovementPlugin,
) -> @app.App[@ecs.World] {
  let decay_rate = plugin.decay_rate
  app.add_systems(
    @app.PostUpdate,
    @app.system_config_param2(fn(
      time : @app.Res[@time.Time[Unit]],
      cameras : @ecs.Query[
        (@ecs.Mut[@transform.Transform], @ecs.Comp[CameraMovement]),
        @ecs.With[@camera.Camera],
      ],
    ) {
      easy_camera_movement_system(decay_rate, time, cameras)
    }).before(@transform.transform_set_propagate),
  )
}

///|
pub fn easy_camera_movement_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  easy_camera_movement_plugin_with(
    app,
    EasyCameraMovementPlugin::EasyCameraMovementPlugin(),
  )
}
