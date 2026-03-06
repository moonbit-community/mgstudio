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
/// Port of `bevy/examples/time/time.rs`.

///|
fn banner() -> Unit {
  println(
    "This example intuitively demonstrates how Time works in Bevy-style schedules.",
  )
  println("")
  println("Time is printed in three schedules:")
  println("- PreUpdate: real time clock")
  println("- FixedUpdate: generic time clock inside fixed schedule")
  println("- Update: generic time clock (virtual time)")
  println("")
  println(
    "Max delta time is set to 5 seconds. Fixed timestep is set to 1 second.",
  )
  println("")
}

///|
fn help() -> Unit {
  println("Scripted commands:")
  println("  empty line: run app.update() once")
  println("  f: set speed to fast (2x)")
  println("  n: set speed to normal (1x)")
  println("  s: set speed to slow (0.5x)")
  println("  p: pause virtual clock")
  println("  u: unpause virtual clock")
  println("  q: quit")
  println("")
}

///|
fn print_real_time(_world : @ecs.World) -> Unit {
  println(
    "PreUpdate: real time, delta=" +
    @my_time.time_real_delta_seconds().to_string() +
    ", elapsed=" +
    @my_time.time_real_elapsed_seconds().to_string(),
  )
}

///|
fn print_fixed_time(_world : @ecs.World) -> Unit {
  println(
    "FixedUpdate: generic time in fixed schedule, delta=" +
    @my_time.time_delta_seconds().to_string() +
    ", elapsed=" +
    @my_time.time_elapsed_seconds().to_string(),
  )
}

///|
fn print_time(_world : @ecs.World) -> Unit {
  println(
    "Update: generic time clock, delta=" +
    @my_time.time_delta_seconds().to_string() +
    ", elapsed=" +
    @my_time.time_elapsed_seconds().to_string(),
  )
}

///|
fn apply_command(
  app : @app.App[@ecs.World],
  command : String,
) -> (@app.App[@ecs.World], Bool) {
  match command {
    "" => (app.run_once(), false)
    "f" => {
      println("FAST: setting relative speed to 2x")
      @my_time.time_virtual_set_relative_speed(2.0F)
      (app, false)
    }
    "n" => {
      println("NORMAL: setting relative speed to 1x")
      @my_time.time_virtual_set_relative_speed(1.0F)
      (app, false)
    }
    "s" => {
      println("SLOW: setting relative speed to 0.5x")
      @my_time.time_virtual_set_relative_speed(0.5F)
      (app, false)
    }
    "p" => {
      println("PAUSE: pausing virtual clock")
      @my_time.time_virtual_pause()
      (app, false)
    }
    "u" => {
      println("UNPAUSE: resuming virtual clock")
      @my_time.time_virtual_unpause()
      (app, false)
    }
    "q" => {
      println("QUITTING!")
      (app, true)
    }
    _ => {
      help()
      (app, false)
    }
  }
}

///|
fn time_runner_builder(app : @app.App[@ecs.World]) -> @app.RunnerFn {
  fn() {
    banner()
    help()

    // `time.rs` is stdin-driven in Bevy. For native smoke runs we replay the
    // same command model using a deterministic script.
    let commands : Array[String] = [
      "", "", "f", "", "n", "", "s", "", "p", "", "u", "", "q",
    ]

    let mut runtime_app = app
      .insert_resource(@my_time.Fixed::from_seconds(1.0F))
      .insert_resource(
        @my_time.Virtual::new()
        .set_max_delta_seconds(5.0F)
        .set_relative_speed(1.0F),
      )
      .run_startup()
    for command in commands {
      let (next_app, should_quit) = apply_command(runtime_app, command)
      runtime_app = next_app
      if should_quit {
        break
      }
    }
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = [
    fn(app : @app.App[@ecs.World]) { @my_time.time_plugin(app) },
  ]
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_pre_update_system(print_real_time)
  .add_fixed_update_system(print_fixed_time)
  .add_system(print_time)
  .set_runner(time_runner_builder)
  .run()
}
