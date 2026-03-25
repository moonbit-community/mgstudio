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
  InGame
} derive(Eq, Show)

///|
struct MenuData {
  root_entity : @core.Entity
}

///|
let menu_data_resource_key : @ecs.ResourceKey[MenuData] = @ecs.register_resource(
  debug_name="examples.state.custom_transitions.MenuData",
)

///|
impl Default for AppState with default() {
  AppState::Menu
}

///|
impl @app.States for AppState with debug_name(self) {
  ignore(self)
  "AppState"
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
fn main {
  let plugins = @mgstudio.default_plugins()
  plugins.push(@app.states_plugin(@app.StatesPlugin::default()))
  // Unlike upstream Bevy, mgstudio exposes OnReenter/OnReexit directly as
  // built-in state schedules, so this example does not need an extra plugin
  // install step to enable identity transitions.
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .insert_state(AppState::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_on_enter_system(AppState::Menu, @app.system_param(setup_menu))
  .add_systems(
    @app.Update,
    @app.system(menu).run_if(@app.in_state(AppState::Menu)),
  )
  .add_on_exit_system(AppState::Menu, @app.system_param2(cleanup_menu))
  .add_on_reenter_system(AppState::InGame, @app.system_param2(setup_game))
  .add_on_reexit_system(AppState::InGame, @app.system_param2(teardown_game))
  .add_systems(
    @app.Update,
    @app.system(movement).run_if(@app.in_state(AppState::InGame)),
  )
  .add_systems(
    @app.Update,
    @app.system(change_color).run_if(@app.in_state(AppState::InGame)),
  )
  .add_systems(
    @app.Update,
    @app.system(trigger_game_restart).run_if(@app.in_state(AppState::InGame)),
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
  world.for_each_component(@ui.ecs_key_interaction, fn(entity, interaction) {
    if !(try! world.contains_by_key(entity, @ui.ecs_key_button)) {
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
    if (try! world.contains_by_key(entity, @ui.ecs_key_background_color)) {
      try! (world.replace(
        entity,
        @ui.ecs_key_background_color,
        @ui.BackgroundColor::new(color),
      )
      |> ignore)
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
    commands.spawn_component(
      @sprite.Sprite::from_image(asset_server.get().load("branding/icon.png")),
    ),
  )
}

///|
fn teardown_game(
  commands : @app.Commands,
  sprites : @ecs.Query[@core.Entity, @ecs.With[@sprite.Sprite]],
) -> Unit {
  try! sprites.view(fn(_query_entity, entity) {
    commands.entity(entity).despawn()
  })
}

///|
fn movement(world : @ecs.World) -> Unit {
  let time = match
    (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => return
  }
  let query : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Sprite],
  ] = @ecs.query_filtered(world, @ecs.With::new(@sprite.ecs_key_sprite))
  let delta_seconds = time.delta_seconds()
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
  let query : @ecs.Query[@ecs.Mut[@sprite.Sprite], @ecs.All] = @ecs.query(world)
  let hue = time.elapsed_seconds() * 60.0F
  try! query.view(fn(_entity, sprite) {
    let sprite = sprite.get_ref()
    sprite.val.color = @sprite.Color::hsla(hue, 0.8F, 0.6F, 1.0F)
  })
}

///|
fn trigger_game_restart(_world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    @app.set_state(AppState::InGame)
  }
}
