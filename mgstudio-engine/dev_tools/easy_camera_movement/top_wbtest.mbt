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
test "easy camera movement: nudges camera transform toward target" {
  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let mut app = @app.App::new(lifecycle_world_15_0)
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(EasyCameraMovementPlugin::EasyCameraMovementPlugin())
    .insert_resource(@time.TimeUpdateStrategy::FixedTimesteps(60))
  let camera = app.world().spawn()
  try! app.world().set_by_key(camera, @camera.Camera::component(), Camera())
  try! app
  .world()
  .set_by_key(camera, @transform.Transform::component(), Transform())
  try! app
  .world()
  .set_by_key(
    camera,
    ecs_key_camera_movement,
    CameraMovement(@math.Vec3::new(10.0F, 0.0F, 0.0F), @math.Quat::identity()),
  )
  app = app.run_once()
  app = app.run_once()
  let transform = (try! app
  .world()
  .get_by_key(camera, @transform.Transform::component())).unwrap()
  debug_inspect(transform.translation.x > 0.0F, content="true")
}
