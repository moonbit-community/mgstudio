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
fn read_real_time(world : @ecs.World) -> @my_time.Real {
  let real_time = try! world.get_resource(@my_time.Real::resource())
  match real_time {
    Some(real_time) => real_time
    None => @my_time.Real::default()
  }
}

///|
fn read_generic_time(world : @ecs.World) -> @my_time.Time {
  let time = try! world.get_resource(@my_time.Time::resource())
  match time {
    Some(time) => time
    None => @my_time.Time::new()
  }
}

///|
fn update_virtual_time_resource(
  app : @app.App[@ecs.World],
  update : (@my_time.Virtual) -> @my_time.Virtual,
) -> @app.App[@ecs.World] {
  let world = app.world()
  let change_tick = world.increment_change_tick()
  let virtual_ref = try! world
    .get_resource_ref_mut(@my_time.Virtual::resource(), change_tick)
    .unwrap()
  let time_ref = try! world
    .get_resource_ref_mut(@my_time.Time::resource(), change_tick)
    .unwrap()
  let next_virtual = update(virtual_ref.val)
  virtual_ref.val = next_virtual
  time_ref.val = next_virtual.as_generic()
  app
}

///|
fn print_real_time(world : @ecs.World) -> Unit {
  let real_time = read_real_time(world)
  println(
    "PreUpdate: real time, delta=" +
    real_time.delta_seconds().to_string() +
    ", elapsed=" +
    real_time.elapsed_seconds().to_string(),
  )
}

///|
fn print_fixed_time(world : @ecs.World) -> Unit {
  let time = read_generic_time(world)
  println(
    "FixedUpdate: generic time in fixed schedule, delta=" +
    time.delta_seconds().to_string() +
    ", elapsed=" +
    time.elapsed_seconds().to_string(),
  )
}

///|
fn print_time(world : @ecs.World) -> Unit {
  let time = read_generic_time(world)
  println(
    "Update: generic time clock, delta=" +
    time.delta_seconds().to_string() +
    ", elapsed=" +
    time.elapsed_seconds().to_string(),
  )
}

///|
fn apply_command(
  app : @app.App[@ecs.World],
  command : String,
) -> (@app.App[@ecs.World], Bool) {
  match command {
    "" => (app.update(), false)
    "f" => {
      println("FAST: setting relative speed to 2x")
      (
        update_virtual_time_resource(app, fn(virtual_time : @my_time.Virtual) {
          virtual_time.set_relative_speed(2.0F)
        }),
        false,
      )
    }
    "n" => {
      println("NORMAL: setting relative speed to 1x")
      (
        update_virtual_time_resource(app, fn(virtual_time : @my_time.Virtual) {
          virtual_time.set_relative_speed(1.0F)
        }),
        false,
      )
    }
    "s" => {
      println("SLOW: setting relative speed to 0.5x")
      (
        update_virtual_time_resource(app, fn(virtual_time : @my_time.Virtual) {
          virtual_time.set_relative_speed(0.5F)
        }),
        false,
      )
    }
    "p" => {
      println("PAUSE: pausing virtual clock")
      (
        update_virtual_time_resource(app, fn(virtual_time : @my_time.Virtual) {
          virtual_time.pause()
        }),
        false,
      )
    }
    "u" => {
      println("UNPAUSE: resuming virtual clock")
      (
        update_virtual_time_resource(app, fn(virtual_time : @my_time.Virtual) {
          virtual_time.unpause()
        }),
        false,
      )
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
  .add_systems(@app.PreUpdate, @app.system(print_real_time))
  .add_systems(@app.FixedUpdate, @app.system(print_fixed_time))
  .add_systems(@app.Update, @app.system(print_time))
  .set_runner(time_runner_builder)
  .run()
}
