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
fn fxaa_test_spawn_camera(world : @ecs.World) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  entity
}

///|
test "anti_alias/fxaa: runtime state counts only camera entities with Fxaa" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(FxaaPlugin::default())
  let camera_entity = fxaa_test_spawn_camera(app.world())
  let disabled_camera_entity = fxaa_test_spawn_camera(app.world())
  let non_camera_entity = app.world().spawn_empty()
  try! app
  .world()
  .set_by_key(camera_entity, ecs_key_fxaa, Fxaa::default().with_enabled(true))
  try! app
  .world()
  .set_by_key(
    disabled_camera_entity,
    ecs_key_fxaa,
    Fxaa::default().with_enabled(false),
  )
  try! app
  .world()
  .set_by_key(
    non_camera_entity,
    ecs_key_fxaa,
    Fxaa::default().with_enabled(true),
  )
  let app = app.update()
  let runtime = try! app
    .world()
    .get_resource(ecs_key_fxaa_runtime_state)
    .unwrap()
  debug_inspect(runtime.enabled_camera_count, content="1")
}

///|
test "anti_alias/fxaa: node requires camera component and enabled=true" {
  let world = @ecs.World::new()
  let camera_entity = fxaa_test_spawn_camera(world)
  let non_camera_entity = world.spawn_empty()
  try! world.set_by_key(
    camera_entity,
    ecs_key_fxaa,
    Fxaa::default().with_enabled(false),
  )
  try! world.set_by_key(
    non_camera_entity,
    ecs_key_fxaa,
    Fxaa::default().with_enabled(true),
  )
  debug_inspect(fxaa_node_enabled(world, camera_entity), content="false")
  debug_inspect(fxaa_node_enabled(world, non_camera_entity), content="false")
  try! (world.replace(
    camera_entity,
    ecs_key_fxaa,
    Fxaa::default().with_enabled(true),
  )
  |> ignore)
  debug_inspect(fxaa_node_enabled(world, camera_entity), content="true")
}
