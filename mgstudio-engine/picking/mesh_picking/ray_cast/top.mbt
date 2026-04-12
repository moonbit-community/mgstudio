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
// Bevy source: `bevy/crates/bevy_picking/src/mesh_picking/ray_cast/mod.rs`.

///|
pub type MeshRayCastHit = @pbr.MeshRayCastHit

///|
pub type MeshRayCastSettings = @pbr.MeshRayCastSettings

///|
pub fn mesh_ray_cast(
  world : @ecs.World,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastSettings,
) -> Array[(@core.Entity, MeshRayCastHit)] {
  @pbr.mesh_ray_cast(world, origin, direction, settings)
}

///|
pub fn mesh_ray_cast_first(
  world : @ecs.World,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastSettings,
) -> (@core.Entity, MeshRayCastHit)? {
  @pbr.mesh_ray_cast_first(world, origin, direction, settings)
}

///|
pub fn mesh_ray_cast_from_camera(
  world : @ecs.World,
  screen : @math.Vec2,
  camera : @sprite.Camera,
  projection : @pbr.Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
  settings : MeshRayCastSettings,
) -> Array[(@core.Entity, MeshRayCastHit)] {
  @pbr.mesh_ray_cast_from_camera(
    world,
    screen,
    camera,
    projection,
    camera_transform,
    target_size,
    scale_factor,
    settings,
  )
}

///|
pub fn mesh_ray_cast_from_camera_first(
  world : @ecs.World,
  screen : @math.Vec2,
  camera : @sprite.Camera,
  projection : @pbr.Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
  settings : MeshRayCastSettings,
) -> (@core.Entity, MeshRayCastHit)? {
  @pbr.mesh_ray_cast_from_camera_first(
    world,
    screen,
    camera,
    projection,
    camera_transform,
    target_size,
    scale_factor,
    settings,
  )
}
