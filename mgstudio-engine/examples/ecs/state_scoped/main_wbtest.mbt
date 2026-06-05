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
test "examples ecs state_scoped: scheduled update queues UI overlay for Camera3d" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .insert_state(GameState::default())
    .insert_resource(TickTock::{
      timer: @time.Timer::from_seconds(1.0F, @time.TimerMode::Repeating),
    })
    .add_systems(@app.Startup, @app.system_config_param(setup_camera))
    .add_on_enter_system_config(
      GameState::A,
      @app.system_config_param(on_a_enter),
    )
    .add_on_enter_system_config(
      GameState::B,
      @app.system_config_param(on_b_enter),
    )
    .add_on_exit_system_config(
      GameState::A,
      @app.system_config_param(on_a_exit),
    )
    .add_on_exit_system_config(
      GameState::B,
      @app.system_config_param(on_b_exit),
    )
    .add_systems(@app.Update, @app.system_config_param4(toggle))

  app = app.update()
  app = app.update()

  let world = app.world()
  debug_inspect(
    @ui.get_ui_context_resource(world).get().unwrap().camera_entity is Some(_),
    content="true",
  )
  let text_query : @ecs.Query[@ecs.Comp[@text.Text], @ecs.All] = @ecs.query(
    world,
  )
  debug_inspect(text_query.count() > 0, content="true")
}
