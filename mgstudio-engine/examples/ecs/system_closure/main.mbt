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
fn main {
  // Create a simple closure.
  let simple_closure = fn(_world : @ecs.World) {
    // This is a closure that does nothing beyond logging.
    @app.log_info("Hello from a simple closure!")
  }

  // Create a closure with an "input" value.
  let complex_closure = fn(value : String) -> @app.SystemFn[@ecs.World] {
    let stored_value : Ref[String] = Ref::new(value)
    fn(_world : @ecs.World) {
      @app.log_info("Hello from a complex closure! \{stored_value.val}")

      // We can modify the value inside the closure. This is saved between calls.
      stored_value.val = "\{stored_value.val} - updated"
    }
  }

  let outside_variable = "bar"

  @app.App::new(@ecs.World::new())
  .add_plugins([@app.log_plugin(@app.LogPlugin::default())])
  // We can use a closure as a system.
  .add_systems(@app.Update, @app.system(simple_closure))
  // Or we can use a more complex closure and pass an argument to initialize state.
  .add_systems(@app.Update, @app.system(complex_closure("foo")))
  // We can also inline a closure.
  .add_systems(
    @app.Update,
    @app.system(fn(_world : @ecs.World) {
      @app.log_info("Hello from an inlined closure!")
    }),
  )
  // Or use variables outside a closure.
  .add_systems(
    @app.Update,
    @app.system(fn(_world : @ecs.World) {
      @app.log_info(
        "Hello from an inlined closure that captured the 'outside_variable'! \{outside_variable}",
      )
    }),
  )
  .run()
}
