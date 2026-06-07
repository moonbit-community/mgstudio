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
struct PrintOnCompletionTimer {
  mut timer : @time.Timer
}

///|
let print_on_completion_timer_component_key : @ecs.ComponentKey[
  PrintOnCompletionTimer,
] = @ecs.register_component(
  debug_name="examples.time.timers.PrintOnCompletionTimer",
)

///|
impl @ecs.Component for PrintOnCompletionTimer with fn component() {
  print_on_completion_timer_component_key
}

///|
struct Countdown {
  mut percent_trigger : @time.Timer
  mut main_timer : @time.Timer
}

///|
let countdown_resource_key : @ecs.ResourceKey[Countdown] = @ecs.register_resource(
  debug_name="examples.time.timers.Countdown",
)

///|
impl @app.Resource for Countdown with fn resource() {
  countdown_resource_key
}

///|
fn Countdown::Countdown() -> Countdown {
  {
    percent_trigger: @time.Timer::from_seconds(4.0F, @time.TimerMode::Repeating),
    main_timer: @time.Timer::from_seconds(20.0F, @time.TimerMode::Once),
  }
}

///|
fn setup(commands : @app.Commands) -> Unit {
  let timer_entity = commands.spawn_empty()
  commands
  .entity(timer_entity)
  .insert_component(PrintOnCompletionTimer::{
    timer: @time.Timer::from_seconds(5.0F, @time.TimerMode::Once),
  })
}

///|
fn print_when_completed(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Write[PrintOnCompletionTimer], @ecs.All],
) -> Unit {
  let delta = time.get().delta()
  try! query.view(fn(_entity, timer_component) {
    let just_finished = timer_component.modify(fn(value) {
      value.timer = value.timer.tick(delta)
      value.timer.just_finished()
    })
    if just_finished {
      @app.log_info("Entity timer just finished")
    }
  })
}

///|
fn countdown(
  time : @app.Res[@time.Time[Unit]],
  countdown : @app.ResMut[Countdown],
) -> Unit {
  let delta = time.get().delta()
  let status = countdown.modify(fn(value) {
    value.main_timer = value.main_timer.tick(delta)
    value.percent_trigger = value.percent_trigger.tick(delta)

    if !value.percent_trigger.just_finished() {
      None
    } else if !value.main_timer.is_finished() {
      Some((value.main_timer.fraction() * 100.0F).to_int())
    } else {
      value.percent_trigger = value.percent_trigger.pause()
      Some(-1)
    }
  })
  match status {
    Some(percent_complete) if percent_complete >= 0 =>
      @app.log_info("Timer is \{percent_complete}% complete!")
    Some(_) => @app.log_info("Paused percent trigger timer")
    None => ()
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .init_resource(fn() { Countdown::Countdown() })
  .add_systems_param(@app.Startup, setup)
  .add_systems_param2(@app.Update, countdown)
  .add_systems_param2(@app.Update, print_when_completed)
  .run()
}
