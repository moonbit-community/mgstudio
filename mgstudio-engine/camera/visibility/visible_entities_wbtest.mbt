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
  let camera = world.spawn()
  let visible_mesh = world.spawn()
  let hidden_layer_mesh = world.spawn()
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
  for entity in [visible_mesh, hidden_layer_mesh] {
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

  check_visibility_visible_entities_system(world)

  let visible_entities = (try! world.get_by_key(
    camera, @camera_camera.ecs_key_visible_entities,
  )).unwrap()
  debug_inspect(visible_entities.len(mesh3d_class), content="1")
  debug_inspect(visible_entities.get(mesh3d_class)[0].id, content="1")
  debug_inspect(
    (try! world.get_by_key(
      visible_mesh, @root_visibility.ecs_key_view_visibility,
    ))
    .unwrap()
    .is_visible(),
    content="true",
  )
}
