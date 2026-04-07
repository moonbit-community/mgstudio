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
const WORLD_HALF_X : Float = 560.0F

///|
const WORLD_HALF_Y : Float = 320.0F

///|
struct Player {}

///|
struct Cake {}

///|
struct Score {
  mut value : Int
}

///|
let player_key : @ecs.ComponentKey[Player] = @ecs.register_component(
  debug_name="examples.games.alien_cake_addict.Player",
)

///|
let cake_key : @ecs.ComponentKey[Cake] = @ecs.register_component(
  debug_name="examples.games.alien_cake_addict.Cake",
)

///|
let score_key : @ecs.ResourceKey[Score] = @ecs.register_resource(
  debug_name="examples.games.alien_cake_addict.Score",
)

///|
pub impl @ecs.Component for Player with component() {
  player_key
}

///|
pub impl @ecs.Component for Cake with component() {
  cake_key
}

///|
impl @app.Resource for Score with resource() {
  score_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn clampf(value : Float, lower : Float, upper : Float) -> Float {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}

///|
fn spawn_cakes(commands : @app.Commands, count : Int) -> Unit {
  for i in 0..<count {
    let x = @math.sin(float_from_int(i) * 1.31F) * 460.0F
    let y = @math.cos(float_from_int(i) * 1.77F) * 250.0F
    ignore(
      commands.spawn(
        (
          @sprite.Sprite::sized(@math.Vec2::new(28.0F, 28.0F)).with_color(
            @sprite.Color::hsl(float_from_int(i * 37 % 360), 0.82F, 0.56F),
          ),
          @transform.Transform::from_xyz(x, y, 0.0F),
          Cake::{  },
        ),
      ),
    )
  }
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.insert_resource(Score::{ value: 0 })
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(40.0F, 40.0F)).with_color(
          @sprite.Color::srgb(0.25F, 0.9F, 0.4F),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.5F),
        Player::{  },
      ),
    ),
  )
  spawn_cakes(commands, 24)
}

///|
fn move_player(
  time : @app.Res[@time.Time[Unit]],
  keyboard : @input.ButtonInput[@window.KeyCode],
  players : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Player]],
) -> Unit {
  let speed = 360.0F
  let dt = time.get().delta_secs()
  let mut dx = 0.0F
  let mut dy = 0.0F
  if keyboard.pressed(@window.KeyCode::ArrowLeft) ||
    keyboard.pressed(@window.KeyCode::KeyA) {
    dx -= 1.0F
  }
  if keyboard.pressed(@window.KeyCode::ArrowRight) ||
    keyboard.pressed(@window.KeyCode::KeyD) {
    dx += 1.0F
  }
  if keyboard.pressed(@window.KeyCode::ArrowUp) ||
    keyboard.pressed(@window.KeyCode::KeyW) {
    dy += 1.0F
  }
  if keyboard.pressed(@window.KeyCode::ArrowDown) ||
    keyboard.pressed(@window.KeyCode::KeyS) {
    dy -= 1.0F
  }
  try! players.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.translation.x = clampf(
      transform_ref.val.translation.x + dx * speed * dt,
      -WORLD_HALF_X,
      WORLD_HALF_X,
    )
    transform_ref.val.translation.y = clampf(
      transform_ref.val.translation.y + dy * speed * dt,
      -WORLD_HALF_Y,
      WORLD_HALF_Y,
    )
  })
}

///|
fn collect_cakes(
  commands : @app.Commands,
  score : @app.ResMut[Score],
  players : @ecs.Query[@ecs.Comp[@transform.Transform], @ecs.With[Player]],
  cakes : @ecs.Query[@ecs.Comp[@transform.Transform], @ecs.With[Cake]],
) -> Unit {
  let player_transform = players.require_single() catch { _ => return }
  let mut remaining = 0
  try! cakes.for_each(fn(entity, cake_transform) {
    let dx = cake_transform.value().translation.x -
      player_transform.value().translation.x
    let dy = cake_transform.value().translation.y -
      player_transform.value().translation.y
    if dx * dx + dy * dy < 34.0F * 34.0F {
      commands.entity(entity).despawn()
      score.get_ref().val.value += 1
      @window.host_debug_string(
        value="[alien_cake_addict] score: \{score.get_ref().val.value.to_string()}",
      )
    } else {
      remaining += 1
    }
  })
  if remaining == 0 {
    spawn_cakes(commands, 24)
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(move_player)))
  .add_systems(@app.Update, @app.system(@app.system_param4(collect_cakes)))
  .run()
}
