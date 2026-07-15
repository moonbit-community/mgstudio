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
test "camera visibility: check visibility fills camera VisibleEntities by visibility class" {
  let world = @ecs.World::new()
  defer world.close()
  let camera = world.spawn()
  let visible_mesh = world.spawn()
  let hidden_layer_mesh = world.spawn()
  let newly_visible_mesh = world.spawn()
  let mesh3d_class = 123456
  try! world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(
    camera,
    @camera_camera.ecs_key_visible_entities,
    @camera_camera.VisibleEntities::VisibleEntities(),
  )
  try! world.set_by_key(
    camera,
    @camera_render_layers.ecs_key_render_layers,
    @camera_render_layers.RenderLayers::layer(0),
  )
  try! world.set_by_key(
    camera,
    @camera_primitives.ecs_key_frustum,
    @camera_primitives.Frustum::default_2d(),
  )
  for entity in [visible_mesh, hidden_layer_mesh, newly_visible_mesh] {
    try! world.set_by_key(
      entity,
      @root_visibility.ecs_key_inherited_visibility,
      @root_visibility.InheritedVisibility::visible(),
    )
    try! world.set_by_key(
      entity,
      @root_visibility.ecs_key_view_visibility,
      @root_visibility.ViewVisibility::hidden(),
    )
    try! world.set_by_key(
      entity,
      @root_visibility.ecs_key_visibility_class,
      @root_visibility.VisibilityClass::single(mesh3d_class),
    )
    try! world.set_by_key(
      entity,
      @transform.ecs_key_global_transform,
      @transform.GlobalTransform::identity(),
    )
    try! world.set_by_key(
      entity,
      @camera_primitives.ecs_key_aabb,
      @camera_primitives.Aabb::from_min_max(
        @math.Vec3::new(-0.5F, -0.5F, -0.5F),
        @math.Vec3::new(0.5F, 0.5F, 0.5F),
      ),
    )
  }
  try! world.set_by_key(
    visible_mesh,
    @camera_render_layers.ecs_key_render_layers,
    @camera_render_layers.RenderLayers::layer(0),
  )
  try! world.set_by_key(
    hidden_layer_mesh,
    @camera_render_layers.ecs_key_render_layers,
    @camera_render_layers.RenderLayers::layer(1),
  )
  try! world.set_by_key(
    newly_visible_mesh,
    @camera_render_layers.ecs_key_render_layers,
    @camera_render_layers.RenderLayers::layer(0),
  )
  try! (world.replace(
    visible_mesh,
    @root_visibility.ecs_key_view_visibility,
    @root_visibility.ViewVisibility::visible(),
  ) |> ignore)
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  let tick_context = @core.SystemTickContext::new()
  tick_context.set(@core.SystemTicks::new(1, 2))
  world.set_tick_context(tick_context)
  (try! world.get_by_key(
    visible_mesh, @root_visibility.ecs_key_view_visibility,
  ))
  .unwrap()
  .update()

  check_visibility_visible_entities_system(world)

  let visible_entities = (try! world.get_by_key(
    camera, @camera_camera.ecs_key_visible_entities,
  )).unwrap()
  debug_inspect(visible_entities.len(mesh3d_class), content="2")
  debug_inspect(visible_entities.get(mesh3d_class)[0].id, content="1")
  debug_inspect(visible_entities.get(mesh3d_class)[1].id, content="3")
  debug_inspect(
    (try! world.get_by_key(
      visible_mesh, @root_visibility.ecs_key_view_visibility,
    ))
    .unwrap()
    .is_visible(),
    content="true",
  )
  let changed = world
    .changed_components(
      @root_visibility.ecs_key_view_visibility,
      @core.SystemTicks::new(1, 2),
    )
    .read()
  debug_inspect(changed.contains(visible_mesh), content="false")
  debug_inspect(changed.contains(newly_visible_mesh), content="true")
}

///|
test "camera visibility: frustum culls Aabb unless disabled" {
  let world = @ecs.World::new()
  defer world.close()
  let camera = world.spawn()
  let inside = world.spawn()
  let outside = world.spawn()
  let outside_no_frustum_culling = world.spawn()
  let mesh3d_class = 123456
  try! world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(
    camera,
    @camera_camera.ecs_key_visible_entities,
    @camera_camera.VisibleEntities::VisibleEntities(),
  )
  try! world.set_by_key(
    camera,
    @camera_primitives.ecs_key_frustum,
    @camera_primitives.Frustum::default_2d(),
  )
  for entity in [inside, outside, outside_no_frustum_culling] {
    try! world.set_by_key(
      entity,
      @root_visibility.ecs_key_inherited_visibility,
      @root_visibility.InheritedVisibility::visible(),
    )
    try! world.set_by_key(
      entity,
      @root_visibility.ecs_key_view_visibility,
      @root_visibility.ViewVisibility::hidden(),
    )
    try! world.set_by_key(
      entity,
      @root_visibility.ecs_key_visibility_class,
      @root_visibility.VisibilityClass::single(mesh3d_class),
    )
    try! world.set_by_key(
      entity,
      @camera_primitives.ecs_key_aabb,
      @camera_primitives.Aabb::from_min_max(
        @math.Vec3::new(-0.5F, -0.5F, -0.5F),
        @math.Vec3::new(0.5F, 0.5F, 0.5F),
      ),
    )
  }
  try! world.set_by_key(
    inside,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  try! world.set_by_key(
    outside,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(10.0F, 0.0F, 0.0F),
    ),
  )
  try! world.set_by_key(
    outside_no_frustum_culling,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(10.0F, 0.0F, 0.0F),
    ),
  )
  try! world.set_by_key(
    outside_no_frustum_culling,
    @root_visibility.ecs_key_no_frustum_culling,
    @root_visibility.NoFrustumCulling::NoFrustumCulling(),
  )

  check_visibility_visible_entities_system(world)

  let visible_entities = (try! world.get_by_key(
    camera, @camera_camera.ecs_key_visible_entities,
  )).unwrap()
  debug_inspect(visible_entities.len(mesh3d_class), content="2")
  let entities = visible_entities.get(mesh3d_class)
  debug_inspect(entities[0].id, content="1")
  debug_inspect(entities[1].id, content="3")
}

///|
test "camera visibility: VisibilityRange filters entities before frustum culling" {
  let world = @ecs.World::new()
  defer world.close()
  world.insert_resource(
    ecs_key_visible_entity_ranges,
    VisibleEntityRanges::VisibleEntityRanges(),
  )
  let camera = world.spawn()
  let near_entity = world.spawn()
  let far_entity = world.spawn()
  let mesh3d_class = 123456
  try! world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(
    camera,
    @camera_camera.ecs_key_visible_entities,
    @camera_camera.VisibleEntities::VisibleEntities(),
  )
  try! world.set_by_key(
    camera,
    @camera_primitives.ecs_key_frustum,
    @camera_primitives.Frustum::default_2d(),
  )
  try! world.set_by_key(
    camera,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  for entity in [near_entity, far_entity] {
    try! world.set_by_key(
      entity,
      @root_visibility.ecs_key_inherited_visibility,
      @root_visibility.InheritedVisibility::visible(),
    )
    try! world.set_by_key(
      entity,
      @root_visibility.ecs_key_view_visibility,
      @root_visibility.ViewVisibility::hidden(),
    )
    try! world.set_by_key(
      entity,
      @root_visibility.ecs_key_visibility_class,
      @root_visibility.VisibilityClass::single(mesh3d_class),
    )
    try! world.set_by_key(
      entity,
      @root_visibility.ecs_key_visibility_range,
      @root_visibility.VisibilityRange::abrupt(0.0F, 5.0F),
    )
  }
  try! world.set_by_key(
    near_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  try! world.set_by_key(
    far_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(10.0F, 0.0F, 0.0F),
    ),
  )

  check_visibility_ranges(world)
  check_visibility_visible_entities_system(world)

  let visible_entities = (try! world.get_by_key(
    camera, @camera_camera.ecs_key_visible_entities,
  )).unwrap()
  debug_inspect(visible_entities.len(mesh3d_class), content="1")
  debug_inspect(visible_entities.get(mesh3d_class)[0].id, content="1")
}

///|
test "camera visibility: light visible entity containers mirror Bevy defaults" {
  let world = @ecs.World::new()
  defer world.close()
  let first = world.spawn()
  let second = world.spawn()

  let visible = VisibleMeshEntities::VisibleMeshEntities()
  debug_inspect(visible.is_empty(), content="true")
  visible.push(first)
  debug_inspect(visible.len(), content="1")
  debug_inspect(visible.iter()[0].id, content="0")
  visible.clear()
  debug_inspect(visible.is_empty(), content="true")

  let cubemap = CubemapVisibleEntities::CubemapVisibleEntities()
  debug_inspect(cubemap.iter().length(), content="6")
  let face_entities = VisibleMeshEntities::VisibleMeshEntities()
  face_entities.push(second)
  cubemap.set(2, face_entities)
  debug_inspect(cubemap.get(2).unwrap().iter()[0].id, content="1")
  debug_inspect(cubemap.get(6) is None, content="true")

  let cascades = CascadesVisibleEntities::CascadesVisibleEntities()
  let view = world.spawn()
  debug_inspect(cascades.get(view).length(), content="0")
  cascades.set(view, [face_entities])
  debug_inspect(cascades.get(view).length(), content="1")
  cascades.clear()
  debug_inspect(cascades.get(view).length(), content="0")
}
