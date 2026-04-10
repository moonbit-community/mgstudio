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

///|
fn banner() -> Unit {
  println(
    "This example is meant to intuitively demonstrate how Time works in Bevy.",
  )
  println("")
  println("Time will be printed in three different schedules in the app:")
  println("- PreUpdate: real time is printed")
  println(
    "- FixedUpdate: fixed time step time is printed, may be run zero or multiple times",
  )
  println("- Update: virtual game time is printed")
  println("")
  println(
    "Max delta time is set to 5 seconds. Fixed timestep is set to 1 second.",
  )
  println("")
}

///|
fn help() -> Unit {
  println("The app reads commands line-by-line from standard input.")
  println("")
  println("Commands:")
  println("  empty line: Run app.update() once on the Bevy App")
  println("  q: Quit the app.")
  println("  f: Set speed to fast, 2x")
  println("  n: Set speed to normal, 1x")
  println("  s: Set speed to slow, 0.5x")
  println("  p: Pause")
  println("  u: Unpause")
  println("")
}

///|
fn[T] read_time_resource(
  world : @ecs.World,
  key : @ecs.ResourceKey[@my_time.Time[T]],
  debug_name : String,
) -> @my_time.Time[T] {
  match (try! world.get_resource(key)) {
    Some(time) => time
    None => abort("Missing required time resource: \{debug_name}")
  }
}

///|
fn update_virtual_time_resource(
  app : @app.App[@ecs.World],
  update : (@my_time.Time[@my_time.Virtual]) -> @my_time.Time[@my_time.Virtual],
) -> @app.App[@ecs.World] {
  let world = app.world()
  let virtual_ref = try! world
    .get_resource_ref_mut(@my_time.virtual_time_resource_key())
    .unwrap()
  let time_ref = try! world
    .get_resource_ref_mut(@my_time.default_time_resource_key())
    .unwrap()
  let next_virtual = update(virtual_ref.val)
  virtual_ref.val = next_virtual
  time_ref.val = next_virtual.as_generic()
  app
}

///|
fn print_real_time(world : @ecs.World) -> Unit {
  let real_time = read_time_resource(
    world,
    @my_time.real_time_resource_key(),
    "Time<Real>",
  )
  println(
    "PreUpdate: this is real time clock, delta is \{to_repr(real_time.delta()).to_string()} and elapsed is \{to_repr(real_time.elapsed()).to_string()}",
  )
}

///|
fn print_fixed_time(world : @ecs.World) -> Unit {
  let time = read_time_resource(
    world,
    @my_time.default_time_resource_key(),
    "Time<Unit>",
  )
  println(
    "FixedUpdate: this is generic time clock inside fixed, delta is \{to_repr(time.delta()).to_string()} and elapsed is \{to_repr(time.elapsed()).to_string()}",
  )
}

///|
fn print_time(world : @ecs.World) -> Unit {
  let time = read_time_resource(
    world,
    @my_time.default_time_resource_key(),
    "Time<Unit>",
  )
  println(
    "Update: this is generic time clock, delta is \{to_repr(time.delta()).to_string()} and elapsed is \{to_repr(time.elapsed()).to_string()}",
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
        update_virtual_time_resource(app, fn(
          virtual_time : @my_time.Time[@my_time.Virtual],
        ) {
          virtual_time.set_relative_speed(2.0F)
        }),
        false,
      )
    }
    "n" => {
      println("NORMAL: setting relative speed to 1x")
      (
        update_virtual_time_resource(app, fn(
          virtual_time : @my_time.Time[@my_time.Virtual],
        ) {
          virtual_time.set_relative_speed(1.0F)
        }),
        false,
      )
    }
    "s" => {
      println("SLOW: setting relative speed to 0.5x")
      (
        update_virtual_time_resource(app, fn(
          virtual_time : @my_time.Time[@my_time.Virtual],
        ) {
          virtual_time.set_relative_speed(0.5F)
        }),
        false,
      )
    }
    "p" => {
      println("PAUSE: pausing virtual clock")
      (
        update_virtual_time_resource(app, fn(
          virtual_time : @my_time.Time[@my_time.Virtual],
        ) {
          virtual_time.pause()
        }),
        false,
      )
    }
    "u" => {
      println("UNPAUSE: resuming virtual clock")
      (
        update_virtual_time_resource(app, fn(
          virtual_time : @my_time.Time[@my_time.Virtual],
        ) {
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
    let mut runtime_app = app
    let mut should_quit = false
    while !should_quit {
      match @app.app_stdin_read_line() {
        Some(command) => {
          let (next_app, quit_now) = apply_command(runtime_app, command)
          runtime_app = next_app
          should_quit = quit_now
        }
        None => should_quit = true
      }
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.minimal_plugins())
  .insert_resource(@my_time.Time::from_max_delta(@core.Duration::from_secs(5L)))
  .insert_resource(@my_time.Time::from_duration(@core.Duration::from_secs(1L)))
  .add_systems(@app.PreUpdate, @app.system(print_real_time))
  .add_systems(@app.FixedUpdate, @app.system(print_fixed_time))
  .add_systems(@app.Update, @app.system(print_time))
  .set_runner(time_runner_builder)
  .run()
}
