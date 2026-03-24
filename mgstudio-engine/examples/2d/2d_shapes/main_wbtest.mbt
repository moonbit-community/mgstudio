// Copyright 2025 International Digital Economy Academy
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
test "examples 2d shapes: scheduled update queues visible 2d draw items" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.default_plugins())
    .add_plugins([@sprite.wireframe2d_plugin])
    .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))

  app = app.update()

  let world = app.world()
  inspect(world.query1(@sprite.ecs_key_camera2d).count(), content="1")
  inspect(world.query1(@sprite.ecs_key_mesh2d).count() > 0, content="true")
  inspect(
    @sprite.render2d_diagnostic_prepared_camera_count() > 0,
    content="true",
  )
  inspect(
    @sprite.render2d_diagnostic_queued_draw_item_count() > 0,
    content="true",
  )
}
