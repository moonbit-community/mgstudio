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
struct MenuState {
  mut playing : Bool
}

///|
struct MenuPanel {}

///|
struct Player {}

///|
let menu_state_key : @ecs.ResourceKey[MenuState] = @ecs.register_resource(
  debug_name="examples.games.game_menu.MenuState",
)

///|
let menu_panel_key : @ecs.ComponentKey[MenuPanel] = @ecs.register_component(
  debug_name="examples.games.game_menu.MenuPanel",
)

///|
let player_key : @ecs.ComponentKey[Player] = @ecs.register_component(
  debug_name="examples.games.game_menu.Player",
)

///|
impl @app.Resource for MenuState with resource() {
  menu_state_key
}

///|
pub impl @ecs.Component for MenuPanel with component() {
  menu_panel_key
}

///|
pub impl @ecs.Component for Player with component() {
  player_key
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.insert_resource(MenuState::{ playing: false })
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(620.0F, 360.0F)).with_color(
          @sprite.Color::srgb(0.14F, 0.16F, 0.24F),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, -1.0F),
        MenuPanel::{  },
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(44.0F, 44.0F)).with_color(
          @sprite.Color::srgb(0.24F, 0.94F, 0.36F),
        ),
        @transform.Transform::from_xyz(0.0F, -120.0F, 0.2F),
        Player::{  },
      ),
    ),
  )
}

///|
fn toggle_mode(
  keyboard : @input.ButtonInput[@window.KeyCode],
  state : @app.ResMut[MenuState],
) -> Unit {
  if keyboard.just_pressed(@window.KeyCode::Enter) {
    state.get_ref().val.playing = true
  }
  if keyboard.just_pressed(@window.KeyCode::Escape) {
    state.get_ref().val.playing = false
  }
}

///|
fn update_visuals(
  time : @app.Res[@time.Time[Unit]],
  state : @app.Res[MenuState],
  panels : @ecs.Query[@ecs.Mut[@sprite.Sprite], @ecs.With[MenuPanel]],
  players : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Player]],
) -> Unit {
  let playing = state.get().playing
  try! panels.for_each(fn(_entity, panel) {
    panel.get_ref().val.color = if playing {
      @sprite.Color::srgb(0.09F, 0.24F, 0.18F)
    } else {
      @sprite.Color::srgb(0.14F, 0.16F, 0.24F)
    }
  })
  try! players.for_each(fn(_entity, player_transform) {
    let transform_ref = player_transform.get_ref()
    if playing {
      transform_ref.val.translation.x = @math.sin(
          time.get().elapsed_secs() * 2.4F,
        ) *
        280.0F
    } else {
      transform_ref.val.translation.x = 0.0F
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(toggle_mode)))
  .add_systems(@app.Update, @app.system(@app.system_param4(update_visuals)))
  .run()
}
