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
fn test_mesh_ray_cast_2d_mesh_handle(
  world : @ecs.World,
) -> @asset.Handle[@mesh.Mesh] {
  let assets = @asset.Assets::new()
  let handle = assets.add(
    @mesh.Mesh::from_2d_geometry(
      @mesh.Mesh2dGeometry::new(
        [
          @math.Vec2::new(-1.0F, -1.0F),
          @math.Vec2::new(1.0F, -1.0F),
          @math.Vec2::new(1.0F, 1.0F),
          @math.Vec2::new(-1.0F, 1.0F),
        ],
        [
          @math.Vec2::new(0.0F, 0.0F),
          @math.Vec2::new(1.0F, 0.0F),
          @math.Vec2::new(1.0F, 1.0F),
          @math.Vec2::new(0.0F, 1.0F),
        ],
        Some([0, 1, 2, 0, 2, 3]),
      ),
    ),
  )
  world.insert_resource(@asset.assets_resource_key(), assets)
  handle
}

///|
test "mesh ray cast includes Mesh2d front and back faces" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()
  let handle = test_mesh_ray_cast_2d_mesh_handle(world)
  try! world.set_by_key(entity, @mesh.ecs_key_mesh2d, @mesh.Mesh2d::new(handle))
  let front_hits = mesh_ray_cast_intersections(
    world,
    @math.Vec3::new(0.0F, 0.0F, 10.0F),
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    MeshRayCastIntersectionSettings::default(),
  )
  guard front_hits.length() == 1 && front_hits[0].0.id == entity.id else {
    fail("expected one front-face Mesh2d hit")
  }
  assert_eq(front_hits[0].1.distance, 10.0F)
  let back_hits = mesh_ray_cast_intersections(
    world,
    @math.Vec3::new(0.0F, 0.0F, -10.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    MeshRayCastIntersectionSettings::default(),
  )
  guard back_hits.length() == 1 && back_hits[0].0.id == entity.id else {
    fail("expected one back-face Mesh2d hit")
  }
  assert_eq(back_hits[0].1.distance, 10.0F)
}

///|
test "mesh ray cast filters invisible Mesh2d unless configured" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()
  let handle = test_mesh_ray_cast_2d_mesh_handle(world)
  try! world.set_by_key(entity, @mesh.ecs_key_mesh2d, @mesh.Mesh2d::new(handle))
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::hidden(),
  )
  let hidden_hits = mesh_ray_cast_intersections(
    world,
    @math.Vec3::new(0.0F, 0.0F, 10.0F),
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    MeshRayCastIntersectionSettings::default(),
  )
  assert_eq(hidden_hits.length(), 0)
  let included_hits = mesh_ray_cast_intersections(
    world,
    @math.Vec3::new(0.0F, 0.0F, 10.0F),
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    MeshRayCastIntersectionSettings::default().with_include_invisible(true),
  )
  assert_eq(included_hits.length(), 1)
}
