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
fn taa_test_spawn_camera(world : @ecs.World) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  entity
}

///|
test "anti_alias/taa: runtime state tracks camera-only and reset count" {
  let app = @app.App::new(@ecs.World::new()).add_plugin(
    temporal_anti_alias_plugin,
  )
  let camera_entity = taa_test_spawn_camera(app.world())
  let non_camera_entity = app.world().spawn_empty()
  try! app
  .world()
  .set_by_key(
    camera_entity,
    ecs_key_temporal_anti_aliasing,
    TemporalAntiAliasing::new(true),
  )
  try! app
  .world()
  .set_by_key(
    non_camera_entity,
    ecs_key_temporal_anti_aliasing,
    TemporalAntiAliasing::new(true),
  )
  let app = app.update()
  let runtime = try! app
    .world()
    .get_resource(ecs_key_temporal_anti_alias_runtime_state)
    .unwrap()
  debug_inspect(runtime.enabled_camera_count, content="1")
  debug_inspect(runtime.reset_requested_count, content="1")
}
