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
/// Port of `bevy/examples/ecs/generic_system.rs`.

///|
pub(all) enum AppState {
  MainMenu
  InGame
} derive(Eq, Show)

///|
struct TextToPrint {
  text : String
}

///|
struct PrinterTick {
  mut timer : @time.Timer
}

///|
struct MenuClose {}

///|
struct LevelUnload {}

///|
let text_to_print_key : @ecs.ComponentKey[TextToPrint] = @ecs.register_component(
  debug_name="examples.ecs.generic_system.TextToPrint",
)

///|
let printer_tick_key : @ecs.ComponentKey[PrinterTick] = @ecs.register_component(
  debug_name="examples.ecs.generic_system.PrinterTick",
)

///|
let menu_close_key : @ecs.ComponentKey[MenuClose] = @ecs.register_component(
  debug_name="examples.ecs.generic_system.MenuClose",
)

///|
let level_unload_key : @ecs.ComponentKey[LevelUnload] = @ecs.register_component(
  debug_name="examples.ecs.generic_system.LevelUnload",
)

///|
impl @app.States for AppState with debug_name(self) {
  ignore(self)
  "AppState"
}

///|
impl Default for AppState with default() {
  AppState::MainMenu
}

///|
impl @ecs.Component for TextToPrint with component() {
  text_to_print_key
}

///|
impl @ecs.Component for PrinterTick with component() {
  printer_tick_key
}

///|
impl @ecs.Component for MenuClose with component() {
  menu_close_key
}

///|
impl @ecs.Component for LevelUnload with component() {
  level_unload_key
}

///|
fn setup_system(commands : @app.Commands) -> Unit {
  commands.spawn(
    (
      PrinterTick::{
        timer: @time.Timer::from_seconds(1.0F, @time.TimerMode::Repeating),
      },
      TextToPrint::{ text: "I will print until you press space." },
      MenuClose::{  },
    ),
  )
  |> ignore

  commands.spawn(
    (
      PrinterTick::{
        timer: @time.Timer::from_seconds(1.0F, @time.TimerMode::Repeating),
      },
      TextToPrint::{ text: "I will always print" },
      LevelUnload::{  },
    ),
  )
  |> ignore
}

///|
fn print_text_system(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[(@ecs.Comp[TextToPrint], @ecs.Mut[PrinterTick]), @ecs.All],
) -> Unit {
  let delta = time.get().delta()
  try! query.view(fn(_entity, data) {
    let (text, timer) = data
    let timer_ref = timer.get_ref()
    timer_ref.val.timer = timer_ref.val.timer.tick(delta)
    if timer_ref.val.timer.just_finished() {
      @app.log_info(text.value().text)
    }
  })
}

///|
fn transition_to_in_game_system(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
) -> Unit {
  if keyboard_input.pressed(@window.KeyCode::Space) {
    @app.set_state(AppState::InGame)
  }
}

///|
fn[T] cleanup_system(
  commands : @app.Commands,
  query : @ecs.Query[@ecs.EntityRef, @ecs.With[T]],
) -> Unit {
  try! query.view(fn(entity, _value) { commands.entity(entity).despawn() })
}

///|
let cleanup_menu_close_system : (
  @app.Commands,
  @ecs.Query[@ecs.EntityRef, @ecs.With[MenuClose]],
) -> Unit = cleanup_system

///|
let cleanup_level_unload_system : (
  @app.Commands,
  @ecs.Query[@ecs.EntityRef, @ecs.With[LevelUnload]],
) -> Unit = cleanup_system

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .insert_state(AppState::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup_system)))
  .add_systems(@app.Update, @app.system(@app.system_param2(print_text_system)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(transition_to_in_game_system)).run_if(
      @app.in_state(AppState::MainMenu),
    ),
  )
  .add_on_exit_system(
    AppState::MainMenu,
    @app.system_param2(cleanup_menu_close_system),
  )
  .add_on_exit_system(
    AppState::InGame,
    @app.system_param2(cleanup_level_unload_system),
  )
  .run()
}
