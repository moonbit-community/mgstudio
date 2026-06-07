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
pub(all) enum GameState {
  A
  B
} derive(Eq, Debug)

///|
struct TickTock {
  mut timer : @time.Timer
}

///|
let tick_tock_resource_key : @ecs.ResourceKey[TickTock] = @ecs.register_resource(
  debug_name="examples.ecs.state_scoped.TickTock",
)

///|
impl Default for GameState with fn default() {
  GameState::A
}

///|
impl @app.States for GameState with fn type_debug_name() {
  "GameState"
}

///|
impl @app.States for GameState with fn debug_name(self) {
  ignore(self)
  "GameState"
}

///|
let game_state_resource_keys : @app.StateResourceKeys[GameState] = @app.register_state_resource_keys(
  "GameState",
)

///|
impl @app.States for GameState with fn state_resource_keys() {
  game_state_resource_keys
}

///|
impl @app.Resource for TickTock with fn resource() {
  tick_tock_resource_key
}

///|
fn spawn_text(
  commands : @app.Commands,
  text : String,
  top : Float,
  left : Float,
  color : @color.Color,
  exit_marker : @state.DespawnOnExit?,
  enter_marker : @state.DespawnOnEnter?,
) -> Unit {
  let node = @ui.Node::Node()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(top))
    .with_left(@ui.Val::Px(left))

  let entity = match (exit_marker, enter_marker) {
    (Some(marker), None) =>
      commands.spawn(
        (
          @text.Text::new(text),
          @text.TextFont::TextFont().with_font_size(33.0F),
          @text.TextColor::new(color),
          node,
          marker,
        ),
      )
    (None, Some(marker)) =>
      commands.spawn(
        (
          @text.Text::new(text),
          @text.TextFont::TextFont().with_font_size(33.0F),
          @text.TextColor::new(color),
          node,
          marker,
        ),
      )
    _ =>
      abort("state_scoped spawn_text expects exactly one state scoped marker")
  }

  match exit_marker {
    Some(marker) =>
      ignore(commands.spawn((@hierarchy.Parent::new(entity), marker)))
    None => ()
  }
  match enter_marker {
    Some(marker) =>
      ignore(commands.spawn((@hierarchy.Parent::new(entity), marker)))
    None => ()
  }
}

///|
fn on_a_enter(commands : @app.Commands) -> Unit {
  println("on_a_enter")
  spawn_text(
    commands,
    "Game is in state 'A'",
    0.0F,
    0.0F,
    @color.Color::srgb(0.5F, 0.5F, 1.0F),
    Some(@state.DespawnOnExit::new(GameState::A)),
    None,
  )
}

///|
fn on_a_exit(commands : @app.Commands) -> Unit {
  println("on_a_exit")
  spawn_text(
    commands,
    "Game state 'A' will be back in 1 second",
    0.0F,
    500.0F,
    @color.Color::srgb(0.5F, 0.5F, 1.0F),
    None,
    Some(@state.DespawnOnEnter::new(GameState::A)),
  )
}

///|
fn on_b_enter(commands : @app.Commands) -> Unit {
  println("on_b_enter")
  spawn_text(
    commands,
    "Game is in state 'B'",
    50.0F,
    0.0F,
    @color.Color::srgb(0.5F, 0.5F, 1.0F),
    Some(@state.DespawnOnExit::new(GameState::B)),
    None,
  )
}

///|
fn on_b_exit(commands : @app.Commands) -> Unit {
  println("on_b_exit")
  spawn_text(
    commands,
    "Game state 'B' will be back in 1 second",
    50.0F,
    500.0F,
    @color.Color::srgb(0.5F, 0.5F, 1.0F),
    None,
    Some(@state.DespawnOnEnter::new(GameState::B)),
  )
}

///|
fn setup_camera(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@camera.Camera3d::Camera3d()))
}

///|
fn toggle(
  time : @app.Res[@time.Time[Unit]],
  timer : @app.ResMut[TickTock],
  state : @app.Res[@app.State[GameState]],
  next_state : @app.ResMut[@app.NextState[GameState]],
) -> Unit {
  let ready = timer.modify(fn(value) {
    value.timer = value.timer.tick(time.get().delta())
    value.timer.just_finished()
  })
  guard ready else { return }

  let next = match state.get().get() {
    GameState::A => @app.NextState::Pending(GameState::B)
    GameState::B => @app.NextState::Pending(GameState::A)
  }
  next_state.set(next)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_state(GameState::default())
  .insert_resource(TickTock::{
    timer: @time.Timer::from_seconds(1.0F, @time.TimerMode::Repeating),
  })
  .add_systems_param(@app.Startup, setup_camera)
  .add_on_enter_system_param(GameState::A, on_a_enter)
  .add_on_enter_system_param(GameState::B, on_b_enter)
  .add_on_exit_system_param(GameState::A, on_a_exit)
  .add_on_exit_system_param(GameState::B, on_b_exit)
  .add_systems_param4(@app.Update, toggle)
  .run()
}
