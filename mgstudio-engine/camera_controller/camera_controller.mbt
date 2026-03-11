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
/// Camera-controller API boundary aligned with Bevy-style controller responsibilities.
/// Runtime implementation currently lives in `Milky2018/mgstudio/pbr`.

///|
pub type FreeCamera = @pbr.FreeCamera

///|
pub type FreeCameraState = @pbr.FreeCameraState

///|
pub let ecs_key_free_camera : @ecs.ComponentKey[FreeCamera] = @pbr.ecs_key_free_camera

///|
pub let ecs_key_free_camera_state : @ecs.ComponentKey[FreeCameraState] = @pbr.ecs_key_free_camera_state

///|
pub fn free_camera_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @pbr.free_camera_plugin(app)
}

///|
pub fn run_free_camera_controller(world : @ecs.World) -> Unit {
  @pbr.run_freecamera_controller(world)
}

///|
pub fn get_free_camera_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[FreeCamera] {
  @pbr.get_free_camera_store(world)
}

///|
pub fn get_free_camera_state_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[FreeCameraState] {
  @pbr.get_free_camera_state_store(world)
}
