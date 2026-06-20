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
test "ci testing: MoveCamera inserts CameraMovement component" {
  let world = @ecs.World::new()
  world.insert_resource(
    ci_testing_config_resource_key,
    CiTestingConfig::CiTestingConfig().with_event(
      0,
      MoveCamera(@math.Vec3::new(1.0F, 2.0F, 3.0F), @math.Quat::identity()),
    ),
  )
  world.insert_resource(
    ci_testing_runtime_state_resource_key,
    CiTestingRuntimeState::CiTestingRuntimeState(),
  )
  let camera = world.spawn()
  try! world.set_by_key(
    camera,
    @camera.Camera::component(),
    @camera.Camera::Camera(),
  )
  ci_testing_send_events_system(world)
  debug_inspect(
    (try! world.get_by_key(
      camera, @dev_tools_easy_camera_movement.ecs_key_camera_movement,
    ))
    is Some(_),
    content="true",
  )
}

///|
test "ci testing: send_events runs before screenshot trigger set" {
  let observed : Array[String] = []
  let app = @app.App::new(@ecs.World::new())
    .insert_world_resource(
      ci_testing_config_resource_key,
      CiTestingConfig::CiTestingConfig().with_event(0, Custom("same-frame")),
    )
    .insert_world_resource(
      ci_testing_runtime_state_resource_key,
      CiTestingRuntimeState::CiTestingRuntimeState(),
    )
    .add_message(ci_testing_custom_event_message_key)
    .add_systems(
      @app.Update,
      @app.system(ci_testing_send_events_system)
      .in_set(ci_testing_event_sender_system_set)
      .before(@render.screenshot_trigger_system_set),
    )
    .add_systems(
      @app.Update,
      @app.system_config_param(fn(
        reader : @ecs.MessageReader[CiTestingCustomEvent],
      ) {
        for event in reader.read() {
          observed.push(event.value())
        }
      }).in_set(@render.screenshot_trigger_system_set),
    )
  let _app = app.run_once()
  debug_inspect(observed, content="[\"same-frame\"]")
}
