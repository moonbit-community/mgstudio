// Copyright 2025 International Digital Economy Academy
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
/// Port of `bevy/examples/2d/move_sprite.rs`.
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(sprite_movement)))
  .run()
}

///|
pub(all) enum Direction {
  Left
  Right
}

///|
let direction_key : @ecs.ComponentKey[Direction] = @ecs.register_component(
  debug_name="examples.2d.move_sprite.Direction",
)

///|
pub impl @ecs.Component for Direction with component() {
  direction_key
}

///|
const SPEED : Float = 150.0F

///|
const EDGE_LIMIT : Float = 200.0F

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(asset_server.get().load("branding/icon.png")),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
        Direction::Right,
      ),
    ),
  )
}

///|
fn sprite_movement(
  commands : @app.Commands,
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query2[Direction, @transform.Transform],
) -> Unit {
  let delta = SPEED * time.get().delta_seconds()
  try! query.for_each(fn(entity, direction, transform) {
    if direction is Right {
      transform.translation.x += delta
    } else {
      transform.translation.x -= delta
    }

    let next_x = transform.translation.x
    if next_x > EDGE_LIMIT {
      commands.entity(entity).insert_component(Direction::Left)
    } else if next_x < -EDGE_LIMIT {
      commands.entity(entity).insert_component(Direction::Right)
    }
  })
}
