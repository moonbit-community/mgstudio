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
/// Camera-facing API boundary aligned with Bevy-style camera responsibilities.
/// Runtime implementation currently lives in `Milky2018/mgstudio/pbr`.

///|
pub type Viewport = @camera_viewport.Viewport

///|
pub type RenderTarget = @camera_camera.RenderTarget

///|
pub type RenderTargetInfo = @camera_computed.RenderTargetInfo

///|
pub type ComputedCameraValues = @camera_computed.ComputedCameraValues

///|
pub type Camera3d = @camera_components3d.Camera3d

///|
pub type SubCameraView3d = @camera_camera.SubCameraView3d

///|
pub type PhysicalCameraParameters = @camera_camera.PhysicalCameraParameters

///|
pub type Exposure = @camera_camera.Exposure

///|
pub let ecs_key_camera3d : @ecs.ComponentKey[Camera3d] = @camera_components3d.ecs_key_camera3d

///|
pub let ecs_key_projection : @ecs.ComponentKey[Projection] = @camera_projection3d.ecs_key_projection

///|
pub fn camera_viewport_to_world_ray(
  viewport_position : @math.Vec2,
  camera : Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  viewport_size : @math.IVec2,
  render_scale : Float,
) -> (@math.Vec3, @math.Vec3)? {
  @camera_projection_math.camera_viewport_to_world_ray(
    viewport_position, camera, projection, camera_transform, viewport_size, render_scale,
  )
}

///|
pub fn camera_world_to_viewport(
  world_position : @math.Vec3,
  camera : Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  viewport_size : @math.IVec2,
  render_scale : Float,
) -> @math.Vec2? {
  @camera_projection_math.camera_world_to_viewport(
    world_position, camera, projection, camera_transform, viewport_size, render_scale,
  )
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs::Viewport::clamp_to_size`.
pub fn camera_viewport_clamp_to_size(
  viewport : Viewport,
  target_size : @math.IVec2,
) -> Viewport {
  viewport.clamp_to_size(target_size)
}
