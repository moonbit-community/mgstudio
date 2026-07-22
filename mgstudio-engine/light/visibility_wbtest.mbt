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
test "light visibility: point shadow caster becomes view visible" {
  let world = @ecs.World::new()
  defer world.close()
  let camera = world.spawn()
  let point = world.spawn()
  let mesh = world.spawn()
  let visible_lights = @camera_camera.VisibleEntities::VisibleEntities()
  visible_lights.push(point, cluster_visibility_class_id())
  try! world.set_by_key(
    camera, @camera_camera.ecs_key_visible_entities, visible_lights,
  )
  try! world.set_by_key(
    point,
    ecs_key_point_light,
    PointLight::PointLight().with_shadow_maps_enabled(true).with_range(10.0F),
  )
  try! world.set_by_key(
    point,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  try! world.set_by_key(
    point,
    @camera_primitives.ecs_key_cubemap_frusta,
    CubemapFrusta(),
  )
  try! world.set_by_key(
    point,
    @camera_visibility.ecs_key_cubemap_visible_entities,
    CubemapVisibleEntities(),
  )
  try! world.set_by_key(
    mesh,
    @mesh.ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(1)),
  )
  try! world.set_by_key(
    mesh,
    @visibility.ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::visible(),
  )
  try! world.set_by_key(
    mesh,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::hidden(),
  )
  try! world.set_by_key(
    mesh,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  try! world.set_by_key(
    mesh,
    @camera_primitives.ecs_key_aabb,
    @camera_primitives.Aabb::from_min_max(
      @math.Vec3::new(-0.5F, -0.5F, -0.5F),
      @math.Vec3::new(0.5F, 0.5F, 0.5F),
    ),
  )

  check_point_light_mesh_visibility(world)

  let visible = (try! world.get_by_key(
    point, @camera_visibility.ecs_key_cubemap_visible_entities,
  )).unwrap()
  debug_inspect(visible.get(0).unwrap().len(), content="1")
  debug_inspect(
    (try! world.get_by_key(mesh, @visibility.ecs_key_view_visibility))
    .unwrap()
    .get(),
    content="true",
  )
}

///|
test "light visibility: spot shadow caster becomes view visible" {
  let world = @ecs.World::new()
  defer world.close()
  let camera = world.spawn()
  let spot = world.spawn()
  let mesh = world.spawn()
  let visible_lights = @camera_camera.VisibleEntities::VisibleEntities()
  visible_lights.push(spot, cluster_visibility_class_id())
  try! world.set_by_key(
    camera, @camera_camera.ecs_key_visible_entities, visible_lights,
  )
  try! world.set_by_key(
    spot,
    ecs_key_spot_light,
    SpotLight::SpotLight().with_shadow_maps_enabled(true),
  )
  try! world.set_by_key(
    spot,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  try! world.set_by_key(spot, @camera_primitives.ecs_key_frustum, Frustum())
  try! world.set_by_key(
    spot,
    @camera_visibility.ecs_key_visible_mesh_entities,
    VisibleMeshEntities(),
  )
  try! world.set_by_key(
    mesh,
    @mesh.ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(2)),
  )
  try! world.set_by_key(
    mesh,
    @visibility.ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::visible(),
  )
  try! world.set_by_key(
    mesh,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::hidden(),
  )
  try! world.set_by_key(
    mesh,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  try! world.set_by_key(
    mesh,
    @camera_primitives.ecs_key_aabb,
    @camera_primitives.Aabb::from_min_max(
      @math.Vec3::new(-0.5F, -0.5F, -0.5F),
      @math.Vec3::new(0.5F, 0.5F, 0.5F),
    ),
  )

  check_point_light_mesh_visibility(world)

  let visible = (try! world.get_by_key(
    spot, @camera_visibility.ecs_key_visible_mesh_entities,
  )).unwrap()
  debug_inspect(visible.len(), content="1")
  debug_inspect(
    (try! world.get_by_key(mesh, @visibility.ecs_key_view_visibility))
    .unwrap()
    .get(),
    content="true",
  )
}

///|
test "light visibility: directional shadow caster becomes view visible" {
  let world = @ecs.World::new()
  defer world.close()
  let view = world.spawn()
  let light = world.spawn()
  let mesh = world.spawn()
  let frusta = @camera_primitives.CascadesFrusta::CascadesFrusta()
  frusta.set(view, [Frustum()])
  try! world.set_by_key(
    light,
    ecs_key_directional_light,
    DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
  )
  try! world.set_by_key(
    light, @camera_primitives.ecs_key_cascades_frusta, frusta,
  )
  try! world.set_by_key(
    light,
    @camera_visibility.ecs_key_cascades_visible_entities,
    CascadesVisibleEntities(),
  )
  try! world.set_by_key(
    light,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::visible(),
  )
  try! world.set_by_key(
    mesh,
    @mesh.ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(3)),
  )
  try! world.set_by_key(
    mesh,
    @visibility.ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::visible(),
  )
  try! world.set_by_key(
    mesh,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::hidden(),
  )
  try! world.set_by_key(
    mesh,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  try! world.set_by_key(
    mesh,
    @camera_primitives.ecs_key_aabb,
    @camera_primitives.Aabb::from_min_max(
      @math.Vec3::new(-0.5F, -0.5F, -0.5F),
      @math.Vec3::new(0.5F, 0.5F, 0.5F),
    ),
  )

  check_dir_light_mesh_visibility(world)

  let visible = (try! world.get_by_key(
    light, @camera_visibility.ecs_key_cascades_visible_entities,
  )).unwrap()
  debug_inspect(visible.get(view)[0].len(), content="1")
  debug_inspect(
    (try! world.get_by_key(mesh, @visibility.ecs_key_view_visibility))
    .unwrap()
    .get(),
    content="true",
  )
}
