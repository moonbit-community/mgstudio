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
/// Port of `bevy/examples/state/sub_states.rs`.

///|
pub(all) enum AppState {
  Menu
  InGame
} derive(Eq, Show)

///|
pub(all) enum IsPaused {
  Running
  Paused
} derive(Eq, Show)

///|
struct MenuData {
  root_entity : @core.Entity
}

///|
let menu_data_resource_key : @ecs.ResourceKey[MenuData] = @ecs.register_resource(
  debug_name="examples.state.sub_states.MenuData",
)

///|
impl Default for AppState with default() {
  AppState::Menu
}

///|
impl Default for IsPaused with default() {
  IsPaused::Running
}

///|
impl @app.States for AppState with debug_name(self) {
  ignore(self)
  "AppState"
}

///|
impl @app.States for IsPaused with debug_name(self) {
  ignore(self)
  "IsPaused"
}

///|
impl @app.FreelyMutableState for IsPaused

///|
impl @app.SubStates for IsPaused

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
fn should_exist(source : AppState) -> IsPaused? {
  match source {
    AppState::InGame => Some(IsPaused::Running)
    AppState::Menu => None
  }
}

///|
fn main {
  let plugins = @mgstudio.default_plugins()
  plugins.push(@app.states_plugin(@app.StatesPlugin::default()))
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .insert_state(AppState::default())
  .add_sub_state(AppState::InGame, IsPaused::Running, should_exist)
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_on_enter_system(AppState::Menu, @app.system_param(setup_menu))
  .add_systems(
    @app.Update,
    @app.system(menu).run_if(@app.in_state(AppState::Menu)),
  )
  .add_on_exit_system(AppState::Menu, @app.system_param2(cleanup_menu))
  .add_on_enter_system(AppState::InGame, @app.system_param2(setup_game))
  .add_on_enter_system(IsPaused::Paused, @app.system_param(setup_paused_screen))
  .add_systems(
    @app.Update,
    @app.system(movement).run_if(@app.in_state(IsPaused::Running)),
  )
  .add_systems(
    @app.Update,
    @app.system(change_color).run_if(@app.in_state(IsPaused::Running)),
  )
  .add_systems(
    @app.Update,
    @app.system(toggle_pause).run_if(@app.in_state(AppState::InGame)),
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
    .with_align_items(@ui.AlignItems::Center),
  )
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Button::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Px(150.0F))
      .with_height(@ui.Val::Px(65.0F))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center),
      @ui.BackgroundColor::new(normal_button_color()),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(button),
        @text.Text::new("Play"),
        @text.TextFont::default().with_font_size(33.0F),
        @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.9F, 0.9F)),
      ),
    ),
  )
  commands.insert_resource(MenuData::{ root_entity: root })
}

///|
fn menu(world : @ecs.World) -> Unit {
  let button_store = world.component(@ui.ecs_key_button)
  let interaction_store = world.component(@ui.ecs_key_interaction)
  let background_store = world.component(@ui.ecs_key_background_color)
  interaction_store.for_each(fn(entity, interaction) {
    if !button_store.contains(entity) {
      return
    }
    let color = match interaction {
      @ui.Interaction::Pressed => {
        @app.set_state(AppState::InGame)
        pressed_button_color()
      }
      @ui.Interaction::Hovered => hovered_button_color()
      @ui.Interaction::None => normal_button_color()
    }
    if background_store.contains(entity) {
      background_store.set(entity, @ui.BackgroundColor::new(color)) |> ignore
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
        @state.DespawnOnExit::new(AppState::InGame),
        @sprite.Sprite::from_image(asset_server.get().load("branding/icon.png")),
      ),
    ),
  )
}

///|
fn movement(world : @ecs.World) -> Unit {
  let time = match
    (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => return
  }
  let query = world.query1_filtered(
    @transform.ecs_key_transform,
    @ecs.With::new(@sprite.ecs_key_sprite),
  )
  let delta_seconds = time.delta_seconds()
  try! query.for_each(fn(_entity, transform) {
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
    transform.translation = @math.Vec3::add(
      transform.translation,
      @math.Vec3::mul_scalar(
        direction.normalize_or_zero(),
        100.0F * delta_seconds,
      ),
    )
  })
}

///|
fn change_color(world : @ecs.World) -> Unit {
  let time = match
    (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => return
  }
  let query = world.query1_filtered(@sprite.ecs_key_sprite, @ecs.All::new())
  let hue = time.elapsed_seconds() * 60.0F
  try! query.for_each(fn(_entity, sprite) {
    sprite.color = @sprite.Color::hsla(hue, 0.8F, 0.6F, 1.0F)
  })
}

///|
fn toggle_pause(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  match @app.world_state(world, IsPaused::Running) {
    Some(current_state) =>
      match current_state.get() {
        IsPaused::Running => @app.set_state(IsPaused::Paused)
        IsPaused::Paused => @app.set_state(IsPaused::Running)
      }
    None => ()
  }
}

///|
fn setup_paused_screen(commands : @app.Commands) -> Unit {
  let root = commands.spawn(
    (
      @state.DespawnOnExit::new(IsPaused::Paused),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center)
      .with_flex_direction(@ui.FlexDirection::Column),
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
