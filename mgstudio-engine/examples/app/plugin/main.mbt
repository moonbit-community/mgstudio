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
/// Port of `bevy/examples/app/plugin.rs`.

///|
priv struct PrintMessagePluginConfig {
  wait_duration_seconds : Float
  message : String
}

///|
priv struct PrintMessageState {
  message : String
  mut timer : @time.Timer
}

///|
let print_message_state_resource : Ref[@core.Resource[PrintMessageState]] = Ref::new(
  @core.Resource::new(),
)

///|
impl @app.Resource for PrintMessageState with resource() {
  print_message_state_resource.val
}

///|
fn print_message_plugin(
  config : PrintMessagePluginConfig,
) -> @app.Plugin[@ecs.World] {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    app
    .insert_resource(PrintMessageState::{
      message: config.message,
      timer: @time.Timer::from_seconds(
        config.wait_duration_seconds,
        @time.TimerMode::Repeating,
      ),
    })
    .add_system_param2(print_message_system)
  }
}

///|
fn print_message_system(
  state : @app.ResMut[PrintMessageState],
  time : @app.Res[@time.Time],
) -> Unit {
  let state_ref = state.get_ref()
  let timer = state_ref.val.timer.tick(time.get().delta_seconds())
  state_ref.val.timer = timer
  if timer.is_finished() {
    println(state_ref.val.message)
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins_ecs()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([
    print_message_plugin({
      wait_duration_seconds: 1.0F,
      message: "This is an example plugin",
    }),
  ])
  .run()
}
