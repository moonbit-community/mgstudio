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
/// Port of `bevy/examples/time/timers.rs`.

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
impl @ecs.Component for PrintOnCompletionTimer with component() {
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
impl @app.Resource for Countdown with resource() {
  countdown_resource_key
}

///|
impl Default for Countdown with default() {
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
  query : @ecs.Query[@ecs.Mut[PrintOnCompletionTimer], @ecs.All],
) -> Unit {
  let delta = time.get().delta()
  try! query.view(fn(_entity, timer_component) {
    let timer_ref = timer_component.get_ref()
    timer_ref.val.timer = timer_ref.val.timer.tick(delta)
    if timer_ref.val.timer.just_finished() {
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
  let countdown_ref = countdown.get_ref()
  countdown_ref.val.main_timer = countdown_ref.val.main_timer.tick(delta)
  countdown_ref.val.percent_trigger = countdown_ref.val.percent_trigger.tick(
    delta,
  )

  if countdown_ref.val.percent_trigger.just_finished() {
    if !countdown_ref.val.main_timer.is_finished() {
      let percent_complete = (countdown_ref.val.main_timer.fraction() * 100.0F).to_int()
      @app.log_info("Timer is \{percent_complete}% complete!")
    } else {
      countdown_ref.val.percent_trigger = countdown_ref.val.percent_trigger.pause()
      @app.log_info("Paused percent trigger timer")
    }
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .init_resource(fn() { Countdown::default() })
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(countdown)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(print_when_completed)),
  )
  .run()
}
