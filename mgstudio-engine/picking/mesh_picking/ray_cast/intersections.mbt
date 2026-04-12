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
// Bevy source: `bevy/crates/bevy_picking/src/mesh_picking/ray_cast/intersections.rs`.

///|
pub type MeshRayCastIntersectionSettings = @pbr.MeshRayCastSettings

///|
pub type MeshRayCastIntersectionHit = @pbr.MeshRayCastHit

///|
pub fn mesh_ray_cast_intersections(
  world : @ecs.World,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastIntersectionSettings,
) -> Array[(@core.Entity, MeshRayCastIntersectionHit)] {
  @pbr.mesh_ray_cast(world, origin, direction, settings)
}

///|
pub fn mesh_ray_cast_intersections_first(
  world : @ecs.World,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastIntersectionSettings,
) -> (@core.Entity, MeshRayCastIntersectionHit)? {
  @pbr.mesh_ray_cast_first(world, origin, direction, settings)
}
