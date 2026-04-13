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
pub type Camera3d = @pbr.Camera3d

///|
pub type Camera3dBundle = @pbr.Camera3dBundle

///|
pub type CameraDecalConfig3d = @pbr.CameraDecalConfig3d

///|
pub type CameraDecalRenderMode3d = @pbr.DecalRenderMode3d

///|
pub type CameraDeferredConfig3d = @pbr.CameraDeferredConfig3d

///|
pub type CameraDeferredMode3d = @pbr.CameraDeferredMode3d

///|
pub type PhysicalCameraParameters = @pbr.PhysicalCameraParameters

///|
pub type Exposure = @pbr.Exposure

///|
pub type AutoExposure = @pbr.AutoExposure

///|
pub type DepthOfField = @pbr.DepthOfField

///|
pub type DepthOfFieldMode = @pbr.DepthOfFieldMode

///|
pub type MeshRayCastHit = @picking_mesh_ray_cast.MeshRayCastHit

///|
pub type MeshRayCastSettings = @picking_mesh_ray_cast.MeshRayCastSettings

///|
pub let ecs_key_camera3d : @ecs.ComponentKey[Camera3d] = @pbr.ecs_key_camera3d

///|
pub let ecs_key_projection : @ecs.ComponentKey[Projection] = @pbr.ecs_key_projection

///|
pub let ecs_key_sub_camera_view3d : @ecs.ComponentKey[SubCameraView3d] = @pbr.ecs_key_sub_camera_view3d

///|
pub fn camera_viewport_to_world_ray(
  viewport_position : @math.Vec2,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  viewport_size : @math.IVec2,
  render_scale : Float,
) -> (@math.Vec3, @math.Vec3)? {
  @pbr.render3d_camera_viewport_to_world_ray(
    viewport_position, camera, projection, camera_transform, viewport_size, render_scale,
  )
}

///|
pub fn camera_world_to_viewport(
  world_position : @math.Vec3,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  viewport_size : @math.IVec2,
  render_scale : Float,
) -> @math.Vec2? {
  @pbr.render3d_camera_world_to_viewport(
    world_position, camera, projection, camera_transform, viewport_size, render_scale,
  )
}

///|
pub fn mesh_ray_cast_from_camera(
  world : @ecs.World,
  viewport_position : @math.Vec2,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  viewport_size : @math.IVec2,
  render_scale : Float,
  settings : MeshRayCastSettings,
) -> Array[(@core.Entity, MeshRayCastHit)] {
  @picking_mesh_ray_cast.mesh_ray_cast_from_camera(
    world, viewport_position, camera, projection, camera_transform, viewport_size,
    render_scale, settings,
  )
}

///|
pub fn mesh_ray_cast_from_camera_first(
  world : @ecs.World,
  viewport_position : @math.Vec2,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  viewport_size : @math.IVec2,
  render_scale : Float,
  settings : MeshRayCastSettings,
) -> (@core.Entity, MeshRayCastHit)? {
  @picking_mesh_ray_cast.mesh_ray_cast_from_camera_first(
    world, viewport_position, camera, projection, camera_transform, viewport_size,
    render_scale, settings,
  )
}
