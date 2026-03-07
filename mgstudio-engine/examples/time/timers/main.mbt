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
priv struct Countdown {
  mut percent_trigger : @time.Timer
  mut main_timer : @time.Timer
}

///|
priv struct TimerExampleState {
  mut entity_timer : @time.Timer
  countdown : Countdown
  mut percent_trigger_paused : Bool
}

///|
let timer_example_state : Ref[TimerExampleState] = Ref::new({
  entity_timer: @time.Timer::from_seconds(5.0F, @time.TimerMode::Once),
  countdown: {
    percent_trigger: @time.Timer::from_seconds(4.0F, @time.TimerMode::Repeating),
    main_timer: @time.Timer::from_seconds(20.0F, @time.TimerMode::Once),
  },
  percent_trigger_paused: false,
})

///|
fn setup(_world : @ecs.World) -> Unit {
  timer_example_state.val = {
    entity_timer: @time.Timer::from_seconds(5.0F, @time.TimerMode::Once),
    countdown: {
      percent_trigger: @time.Timer::from_seconds(
        4.0F,
        @time.TimerMode::Repeating,
      ),
      main_timer: @time.Timer::from_seconds(20.0F, @time.TimerMode::Once),
    },
    percent_trigger_paused: false,
  }
}

///|
fn print_when_completed(time : @app.Res[@time.Time[Unit]]) -> Unit {
  let delta = time.get().delta()
  timer_example_state.val.entity_timer = timer_example_state.val.entity_timer.tick(
    delta,
  )
  if timer_example_state.val.entity_timer.just_finished() {
    println("Entity timer just finished")
  }
}

///|
fn countdown(time : @app.Res[@time.Time[Unit]]) -> Unit {
  let delta = time.get().delta()

  timer_example_state.val.countdown.main_timer = timer_example_state.val.countdown.main_timer.tick(
    delta,
  )

  timer_example_state.val.countdown.percent_trigger = timer_example_state.val.countdown.percent_trigger.tick(
    delta,
  )

  if timer_example_state.val.countdown.percent_trigger.just_finished() {
    if !timer_example_state.val.countdown.main_timer.is_finished() {
      println(
        "Timer is \{(timer_example_state.val.countdown.main_timer.fraction() * 100.0F).to_int()}% complete!",
      )
    } else if !timer_example_state.val.percent_trigger_paused {
      timer_example_state.val.countdown.percent_trigger = timer_example_state.val.countdown.percent_trigger.pause()
      timer_example_state.val.percent_trigger_paused = true
      println("Paused percent trigger timer")
    }
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param(countdown)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(print_when_completed)),
  )
  .run()
}
