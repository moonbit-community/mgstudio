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
priv struct Input {
  value : String
}

///|
let input_resource_key : @ecs.ResourceKey[Input] = @ecs.register_resource(
  debug_name="examples.app.custom_loop.Input",
)

///|
impl @app.Resource for Input with resource() {
  input_resource_key
}

///|
fn print_system(input : @app.Res[Input]) -> Unit {
  println("You typed: \{input.get().value}")
}

///|
fn exit_system(
  input : @app.Res[Input],
  app_exit : @ecs.MessageWriter[@app.AppExit],
) -> Unit {
  if input.get().value == "exit" {
    ignore(app_exit.write(@app.AppExit::Success))
  }
}

///|
fn my_runner_builder(app : @app.App[@ecs.World]) -> @app.RunnerFn {
  fn() {
    let mut runtime_app = app
    println("Type stuff into the console")
    while true {
      if @app.app_stdin_read_line() is Some(line) {
        runtime_app = runtime_app
          .insert_resource(Input::{ value: line })
          .update()
        if runtime_app.should_exit() is Some(_) {
          break
        }
      } else {
        break
      }
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(Input::{ value: "" })
  .set_runner(my_runner_builder)
  .add_systems(@app.Update, @app.system(@app.system_param(print_system)))
  .add_systems(@app.Update, @app.system(@app.system_param2(exit_system)))
  .run()
}
