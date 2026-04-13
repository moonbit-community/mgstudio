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
fn setup(_world : @ecs.World) -> Unit {
  println("Press P to panic")
}

///|
fn panic_on_p(_world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::KeyP) {
    abort("P pressed, panicking")
  }
}

///|
fn log_system(_world : @ecs.World) -> Unit {
  @app.log_trace("very noisy")
  @app.log_debug("helpful for debugging")
  @app.log_info("helpful information that is worth printing by default")
  @app.log_warn(
    "something bad happened that isn't a failure, but thats worth calling out",
  )
  @app.log_error("something failed")
}

///|
fn log_once_system(_world : @ecs.World) -> Unit {
  @app.log_trace_once("logs::trace_once", "one time noisy message")
  @app.log_debug_once("logs::debug_once", "one time debug message")
  @app.log_info_once("logs::info_once", "some info which is printed only once")
  @app.log_warn_once(
    "logs::warn_once", "some warning we wish to call out only once",
  )
  @app.log_error_once(
    "logs::error_once", "some error we wish to report only once",
  )

  for i in 0..<10 {
    @app.log_info_once(
      "logs::loop_info_once",
      "logs once per call site, so this works just fine: \{i.to_string()}",
    )
  }

  @app.log_info_once("logs::expensive_once_begin", "doing expensive things")
  @app.log_once_with(
    @app.LogLevel::Info,
    callsite="logs::expensive_once_compute",
    fn() { expensive_sum_message() },
  )
}

///|
fn expensive_sum_message() -> String {
  let mut sum : Int64 = 0
  for i in 0..<100000000 {
    sum = sum + Int64::from_int(i)
  }
  "result of some expensive one time calculation: \{sum.to_string()}"
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([@app.log_plugin(@app.LogPlugin::default())])
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Startup, @app.system(setup_visual))
  .add_systems(@app.Update, @app.system(log_system))
  .add_systems(@app.Update, @app.system(log_once_system))
  .add_systems(@app.Update, @app.system(panic_on_p))
  .run()
}

///|
fn setup_visual(world : @ecs.World) -> Unit {
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_clear_color(
      @sprite.Color::srgb(0.16F, 0.12F, 0.18F),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
}
