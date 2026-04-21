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
priv struct PrintMessagePluginConfig {
  wait_duration_seconds : Float
  message : String
}

///|
priv struct PrintMessagePlugin {
  config : PrintMessagePluginConfig
}

///|
priv struct PrintMessageState {
  message : String
  mut timer : @time.Timer
}

///|
let print_message_state_resource_key : @ecs.ResourceKey[PrintMessageState] = @ecs.register_resource(
  debug_name="examples.app.plugin.PrintMessageState",
)

///|
impl @app.Resource for PrintMessageState with resource() {
  print_message_state_resource_key
}

///|
fn print_message_plugin(
  config : PrintMessagePluginConfig,
) -> PrintMessagePlugin {
  PrintMessagePlugin::{ config, }
}

///|
impl @app.Plugin for PrintMessagePlugin with build(self, app) {
  app
  .insert_resource(PrintMessageState::{
    message: self.config.message,
    timer: @time.Timer::from_seconds(
      self.config.wait_duration_seconds,
      @time.TimerMode::Repeating,
    ),
  })
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(print_message_system)),
  )
}

///|
fn print_message_system(
  state : @app.ResMut[PrintMessageState],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let message = state.modify(fn(value) {
    let timer = value.timer.tick(time.get().delta())
    value.timer = timer
    if timer.is_finished() {
      Some(value.message)
    } else {
      None
    }
  })
  if message is Some(message) {
    println(message)
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(
    print_message_plugin({
      wait_duration_seconds: 1.0F,
      message: "This is an example plugin",
    }),
  )
  .run()
}
