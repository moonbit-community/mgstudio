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
pub(all) enum AppState {
  Menu
  InGame(Bool, Bool)
} derive(Eq, Debug)

///|
pub(all) enum TutorialState {
  Active
  Inactive
} derive(Eq, Debug)

///|
struct InGame {} derive(Eq, Debug)

///|
struct TurboMode {} derive(Eq, Debug)

///|
pub(all) enum IsPaused {
  NotPaused
  Paused
} derive(Eq, Debug)

///|
pub(all) enum Tutorial {
  MovementInstructions
  PauseInstructions
} derive(Eq, Debug)

///|
pub(all) enum MenuButton {
  Play
  Tutorial
} derive(Eq, Debug)

///|
struct MenuData {
  root_entity : @core.Entity
}

///|
let menu_button_key : @ecs.ComponentKey[MenuButton] = @ecs.register_component(
  debug_name="examples.state.computed_states.MenuButton",
)

///|
let menu_data_resource_key : @ecs.ResourceKey[MenuData] = @ecs.register_resource(
  debug_name="examples.state.computed_states.MenuData",
)

///|
impl Default for AppState with default() {
  AppState::Menu
}

///|
impl Default for TutorialState with default() {
  TutorialState::Active
}

///|
impl @app.States for AppState with debug_name(self) {
  ignore(self)
  "AppState"
}

///|
impl @app.States for TutorialState with debug_name(self) {
  ignore(self)
  "TutorialState"
}

///|
impl @app.States for InGame with debug_name(self) {
  ignore(self)
  "InGame"
}

///|
impl @app.States for TurboMode with debug_name(self) {
  ignore(self)
  "TurboMode"
}

///|
impl @app.States for IsPaused with debug_name(self) {
  ignore(self)
  "IsPaused"
}

///|
impl @app.States for Tutorial with debug_name(self) {
  ignore(self)
  "Tutorial"
}

///|
impl @ecs.Component for MenuButton with component() {
  menu_button_key
}

///|
pub impl @app.Resource for MenuData with resource() {
  menu_data_resource_key
}

///|
fn normal_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.15F, 0.15F, 0.15F)
}

///|
fn hovered_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.25F, 0.25F, 0.25F)
}

///|
fn pressed_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.35F, 0.75F, 0.35F)
}

///|
fn active_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.15F, 0.35F, 0.65F)
}

///|
fn hovered_active_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.2F, 0.45F, 0.8F)
}

///|
fn pressed_active_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.25F, 0.55F, 0.95F)
}

///|
fn compute_in_game(state : AppState) -> InGame? {
  match state {
    AppState::InGame(_, _) => Some(InGame::{  })
    AppState::Menu => None
  }
}

///|
fn compute_turbo_mode(state : AppState) -> TurboMode? {
  match state {
    AppState::InGame(_, turbo) =>
      if turbo {
        Some(TurboMode::{  })
      } else {
        None
      }
    AppState::Menu => None
  }
}

///|
fn compute_is_paused(state : AppState) -> IsPaused? {
  match state {
    AppState::InGame(paused, _) =>
      if paused {
        Some(IsPaused::Paused)
      } else {
        Some(IsPaused::NotPaused)
      }
    AppState::Menu => None
  }
}

///|
fn compute_tutorial(input : (TutorialState, InGame, IsPaused?)) -> Tutorial? {
  let (tutorial_state, _in_game, is_paused) = input
  if tutorial_state == TutorialState::Inactive {
    return None
  }
  match is_paused {
    Some(IsPaused::NotPaused) => Some(Tutorial::MovementInstructions)
    Some(IsPaused::Paused) => Some(Tutorial::PauseInstructions)
    None => None
  }
}

///|
fn main {
  let plugins = @mgstudio.default_plugins()
  plugins.push(@app.states_plugin(@app.StatesPlugin::default()))
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .insert_state(AppState::default())
  .insert_state(TutorialState::default())
  .add_computed_state(AppState::Menu, InGame::{  }, compute_in_game)
  .add_computed_state(AppState::Menu, TurboMode::{  }, compute_turbo_mode)
  .add_computed_state(AppState::Menu, IsPaused::NotPaused, compute_is_paused)
  .add_computed_state3_optional(
    TutorialState::Active,
    InGame::{  },
    @state.optional_state(IsPaused::Paused),
    Tutorial::MovementInstructions,
    compute_tutorial,
  )
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_on_enter_system(AppState::Menu, @app.system_param(setup_menu))
  .add_systems(
    @app.Update,
    @app.system(menu).run_if(@app.in_state(AppState::Menu)),
  )
  .add_on_exit_system(AppState::Menu, @app.system_param2(cleanup_menu))
  .add_on_enter_system(InGame::{  }, @app.system_param2(setup_game))
  .add_systems(
    @app.Update,
    @app.system(toggle_pause).run_if(@app.in_state(InGame::{  })),
  )
  .add_systems(
    @app.Update,
    @app.system(change_color).run_if(@app.in_state(InGame::{  })),
  )
  .add_systems(
    @app.Update,
    @app.system(quit_to_menu).run_if(@app.in_state(InGame::{  })),
  )
  .add_systems(
    @app.Update,
    @app.system(toggle_turbo).run_if(@app.in_state(IsPaused::NotPaused)),
  )
  .add_systems(
    @app.Update,
    @app.system(movement).run_if(@app.in_state(IsPaused::NotPaused)),
  )
  .add_on_enter_system(IsPaused::Paused, @app.system_param(setup_paused_screen))
  .add_on_enter_system(TurboMode::{  }, @app.system_param(setup_turbo_text))
  .add_on_enter_system(
    Tutorial::MovementInstructions,
    @app.system_param(movement_instructions),
  )
  .add_on_enter_system(
    Tutorial::PauseInstructions,
    @app.system_param(pause_instructions),
  )
  .run()
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
}

///|
fn setup_menu(commands : @app.Commands) -> Unit {
  let root = commands.spawn_component(
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center)
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_row_gap(@ui.Val::Px(16.0F)),
  )
  let play_button = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Button::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Px(200.0F))
      .with_height(@ui.Val::Px(65.0F))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center),
      @ui.BackgroundColor::new(normal_button_color()),
      MenuButton::Play,
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(play_button),
        @text.Text::new("Play"),
        @text.TextFont::default().with_font_size(33.0F),
        @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.9F, 0.9F)),
      ),
    ),
  )
  let tutorial_button = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Button::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Px(200.0F))
      .with_height(@ui.Val::Px(65.0F))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center),
      @ui.BackgroundColor::new(active_button_color()),
      MenuButton::Tutorial,
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(tutorial_button),
        @text.Text::new("Tutorial"),
        @text.TextFont::default().with_font_size(33.0F),
        @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.9F, 0.9F)),
      ),
    ),
  )
  commands.insert_resource(MenuData::{ root_entity: root })
}

///|
fn button_color(
  interaction : @ui.Interaction,
  tutorial_active : Bool,
  button : MenuButton,
) -> @sprite.Color {
  match button {
    MenuButton::Play =>
      match interaction {
        @ui.Interaction::Pressed => pressed_button_color()
        @ui.Interaction::Hovered => hovered_button_color()
        @ui.Interaction::None => normal_button_color()
      }
    MenuButton::Tutorial =>
      if tutorial_active {
        match interaction {
          @ui.Interaction::Pressed => pressed_active_button_color()
          @ui.Interaction::Hovered => hovered_active_button_color()
          @ui.Interaction::None => active_button_color()
        }
      } else {
        match interaction {
          @ui.Interaction::Pressed => pressed_button_color()
          @ui.Interaction::Hovered => hovered_button_color()
          @ui.Interaction::None => normal_button_color()
        }
      }
  }
}

///|
fn menu(world : @ecs.World) -> Unit {
  let tutorial_active = match @app.world_state(world, TutorialState::Active) {
    Some(state) => state.get() == TutorialState::Active
    None => true
  }
  world.for_each_component(@ui.ecs_key_interaction, fn(entity, interaction) {
    if !(try! world.contains_by_key(entity, @ui.ecs_key_button)) {
      return
    }
    guard (try! world.get_by_key(entity, menu_button_key)) is Some(button) else {
      return
    }
    let color = button_color(interaction, tutorial_active, button)
    if (try! world.contains_by_key(entity, @ui.ecs_key_background_color)) {
      try! (world.replace(
        entity,
        @ui.ecs_key_background_color,
        @ui.BackgroundColor::new(color),
      )
      |> ignore)
    }
    if interaction != @ui.Interaction::Pressed {
      return
    }
    match button {
      MenuButton::Play => @app.set_state(AppState::InGame(false, false))
      MenuButton::Tutorial =>
        if tutorial_active {
          @app.set_state(TutorialState::Inactive)
        } else {
          @app.set_state(TutorialState::Active)
        }
    }
  })
}

///|
fn cleanup_menu(
  commands : @app.Commands,
  menu_data : @app.Res[MenuData],
) -> Unit {
  commands.entity(menu_data.get().root_entity).despawn()
}

///|
fn setup_game(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @state.DespawnOnExit::new(InGame::{  }),
        @sprite.Sprite::from_image(asset_server.get().load("branding/icon.png")),
      ),
    ),
  )
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit]? {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => Some(time)
    None => None
  }
}

///|
fn turbo_active(world : @ecs.World) -> Bool {
  @app.world_state(world, TurboMode::{  }) is Some(_)
}

///|
fn movement(world : @ecs.World) -> Unit {
  guard world_time(world) is Some(time) else { return }
  let query : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Sprite],
  ] = @ecs.query_filtered(world, @ecs.With::new(@sprite.ecs_key_sprite))
  let delta_seconds = time.delta_seconds()
  let speed = if turbo_active(world) { 300.0F } else { 100.0F }
  try! query.view(fn(_entity, transform) {
    let transform = transform.get_ref()
    let direction = @math.Vec3::zero()
    if @input.key_pressed(@window.KeyCode::ArrowLeft) {
      direction.x = direction.x - 1.0F
    }
    if @input.key_pressed(@window.KeyCode::ArrowRight) {
      direction.x = direction.x + 1.0F
    }
    if @input.key_pressed(@window.KeyCode::ArrowUp) {
      direction.y = direction.y + 1.0F
    }
    if @input.key_pressed(@window.KeyCode::ArrowDown) {
      direction.y = direction.y - 1.0F
    }
    if direction.x == 0.0F && direction.y == 0.0F {
      return
    }
    transform.val.translation = @math.Vec3::add(
      transform.val.translation,
      @math.Vec3::mul_scalar(
        direction.normalize_or_zero(),
        speed * delta_seconds,
      ),
    )
  })
}

///|
fn setup_paused_screen(commands : @app.Commands) -> Unit {
  let root = commands.spawn(
    (
      @state.DespawnOnExit::new(IsPaused::Paused),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_position_type(@ui.PositionType::Absolute)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_width(@ui.Val::Px(400.0F))
        .with_height(@ui.Val::Px(120.0F))
        .with_justify_content(@ui.JustifyContent::Center)
        .with_align_items(@ui.AlignItems::Center),
        @ui.BackgroundColor::new(normal_button_color()),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @text.Text::new("Paused"),
        @text.TextFont::default().with_font_size(33.0F),
        @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.9F, 0.9F)),
      ),
    ),
  )
}

///|
fn setup_turbo_text(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @state.DespawnOnExit::new(TurboMode::{  }),
        @text.Text::new("TURBO MODE"),
        @text.TextFont::default().with_font_size(33.0F),
        @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.3F, 0.1F)),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          top: @ui.Val::Px(16.0F),
          left: @ui.Val::Px(16.0F),
        },
      ),
    ),
  )
}

///|
fn change_color(world : @ecs.World) -> Unit {
  guard world_time(world) is Some(time) else { return }
  let query : @ecs.Query[@ecs.Mut[@sprite.Sprite], @ecs.All] = @ecs.query(world)
  let hue_speed = if turbo_active(world) { 180.0F } else { 60.0F }
  let hue = time.elapsed_seconds() * hue_speed
  try! query.view(fn(_entity, sprite) {
    let sprite = sprite.get_ref()
    sprite.val.color = @sprite.Color::hsla(hue, 0.8F, 0.6F, 1.0F)
  })
}

///|
fn movement_instructions(commands : @app.Commands) -> Unit {
  let root = commands.spawn(
    (
      @state.DespawnOnExit::new(Tutorial::MovementInstructions),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_position_type(@ui.PositionType::Absolute)
      .with_justify_content(@ui.JustifyContent::End)
      .with_align_items(@ui.AlignItems::Center)
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_row_gap(@ui.Val::Px(8.0F)),
    ),
  )
  let lines = [
    "Move the bevy logo with the arrow keys", "Press T to enter TURBO MODE", "Press SPACE to pause",
    "Press ESCAPE to return to the menu",
  ]
  for line in lines {
    ignore(
      commands.spawn(
        (
          @hierarchy.Parent::new(root),
          @text.Text::new(line),
          @text.TextFont::default().with_font_size(28.0F),
          @text.TextColor::new(@sprite.Color::srgb(0.3F, 0.3F, 0.7F)),
        ),
      ),
    )
  }
}

///|
fn pause_instructions(commands : @app.Commands) -> Unit {
  let root = commands.spawn(
    (
      @state.DespawnOnExit::new(Tutorial::PauseInstructions),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_position_type(@ui.PositionType::Absolute)
      .with_justify_content(@ui.JustifyContent::End)
      .with_align_items(@ui.AlignItems::Center)
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_row_gap(@ui.Val::Px(8.0F)),
    ),
  )
  let lines = ["Press SPACE to resume", "Press ESCAPE to return to the menu"]
  for line in lines {
    ignore(
      commands.spawn(
        (
          @hierarchy.Parent::new(root),
          @text.Text::new(line),
          @text.TextFont::default().with_font_size(28.0F),
          @text.TextColor::new(@sprite.Color::srgb(0.3F, 0.3F, 0.7F)),
        ),
      ),
    )
  }
}

///|
fn toggle_pause(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  match @app.world_state(world, AppState::Menu) {
    Some(current_state) =>
      match current_state.get() {
        AppState::InGame(paused, turbo) =>
          @app.set_state(AppState::InGame(!paused, turbo))
        AppState::Menu => ()
      }
    None => ()
  }
}

///|
fn toggle_turbo(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::KeyT) {
    return
  }
  match @app.world_state(world, AppState::Menu) {
    Some(current_state) =>
      match current_state.get() {
        AppState::InGame(paused, turbo) =>
          @app.set_state(AppState::InGame(paused, !turbo))
        AppState::Menu => ()
      }
    None => ()
  }
}

///|
fn quit_to_menu(_world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Escape) {
    @app.set_state(AppState::Menu)
  }
}
