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
struct Enemy {
  origin : @math.Vec2
  radius : Float
  mut rotation : Float
  rotation_speed : Float
}

///|
struct Player {
  speed : Float
  rotation_speed : Float
  min_follow_radius : Float
}

///|
struct EnemySpawnCursor {
  mut next : Int
}

///|
let enemy_key : @ecs.ComponentKey[Enemy] = @ecs.register_component(
  debug_name="examples.ecs.fallible_params.enemy",
)

///|
let player_key : @ecs.ComponentKey[Player] = @ecs.register_component(
  debug_name="examples.ecs.fallible_params.player",
)

///|
let enemy_spawn_cursor_key : @ecs.ResourceKey[EnemySpawnCursor] = @ecs.register_resource(
  debug_name="examples.ecs.fallible_params.enemy_spawn_cursor",
)

///|
pub impl @ecs.Component for Enemy with fn component() {
  enemy_key
}

///|
pub impl @ecs.Component for Player with fn component() {
  player_key
}

///|
pub impl @app.Resource for EnemySpawnCursor with fn resource() {
  enemy_spawn_cursor_key
}

///|
fn minf(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn main {
  println("")
  println("Press 'A' to add enemy ships and 'R' to remove them.")
  println(
    "Player ship waits for enemies and tracks one when exactly one exists.",
  )
  println("")

  let user_input_system : @app.SystemConfig[@ecs.World] = @app.system_config_param4(
    user_input,
  )
  let move_targets_system : @app.SystemConfig[@ecs.World] = @app.system_config_param2(
    move_targets,
  )
  let track_targets_system : @app.SystemConfig[@ecs.World] = @app.system_config_param3(
    track_targets,
  )

  @app.App::new(@ecs.World::new())
  .set_error_handler(@app.ErrorHandlers::warn)
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_resource(EnemySpawnCursor::{ next: 0 })
  .add_systems_param3(Startup, setup)
  .add_systems(
    Update,
    (user_input_system, move_targets_system, track_targets_system)
    |> @app.chain(),
  )
  .add_systems_param(Update, do_nothing_fail_validation)
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  cursor : @app.ResMut[EnemySpawnCursor],
) -> Unit {
  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))
  cursor.modify(fn(value) { value.next = 0 })

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let texture = asset_server.get().load("textures/simplespace/ship_C.png")
  ignore(
    commands.spawn(
      (
        Player::{
          speed: 100.0F,
          rotation_speed: 2.0F,
          min_follow_radius: 50.0F,
        },
        @sprite.Sprite::from_image(texture).with_color(
          @palettes.tailwind_blue_800(),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @text.Text::new(
          "A: add enemy ship\nR: remove enemy ship\n\nThe player follows only when exactly one enemy exists.",
        ),
        @ui.Node::{
          ..Node(),
          position_type: Absolute,
          left: Px(12.0F),
          top: Px(12.0F),
        },
        @text.TextFont::TextFont().with_font(font).with_font_size(18.0F),
        @text.TextColor::new(@color.Color::white()),
        @text.TextLayout::new_with_justify(Left),
      ),
    ),
  )
}

///|
fn enemy_blueprint(index : Int) -> Enemy {
  match index % 5 {
    0 =>
      {
        origin: @math.Vec2::new(-180.0F, 100.0F),
        radius: 70.0F,
        rotation: 0.3F,
        rotation_speed: 0.6F,
      }
    1 =>
      {
        origin: @math.Vec2::new(170.0F, 90.0F),
        radius: 90.0F,
        rotation: 1.2F,
        rotation_speed: 0.8F,
      }
    2 =>
      {
        origin: @math.Vec2::new(140.0F, -140.0F),
        radius: 120.0F,
        rotation: 2.4F,
        rotation_speed: 1.1F,
      }
    3 =>
      {
        origin: @math.Vec2::new(-160.0F, -120.0F),
        radius: 80.0F,
        rotation: 4.2F,
        rotation_speed: 1.35F,
      }
    _ =>
      {
        origin: @math.Vec2::new(0.0F, 180.0F),
        radius: 110.0F,
        rotation: 5.1F,
        rotation_speed: 0.95F,
      }
  }
}

///|
fn spawn_enemy(
  commands : @app.Commands,
  enemy_texture : @asset.Handle[@image.Image],
  enemy : Enemy,
) -> Unit {
  ignore(
    commands.spawn(
      (
        enemy,
        @sprite.Sprite::from_image(enemy_texture).with_color(
          @palettes.tailwind_red_800(),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )
}

///|
fn first_enemy_entity(
  enemies : @ecs.Query[@core.Entity, @ecs.With[Enemy]],
) -> @core.Entity? {
  let entity_ref : Ref[@core.Entity?] = Ref(None)
  try! enemies.view(fn(_query_entity, entity) {
    if entity_ref.val is None {
      entity_ref.val = Some(entity)
    }
  })
  entity_ref.val
}

///|
fn user_input(
  commands : @app.Commands,
  enemies : @ecs.Query[@core.Entity, @ecs.With[Enemy]],
  asset_server : @app.Res[@asset.AssetServer],
  cursor : @app.ResMut[EnemySpawnCursor],
) -> Unit {
  if @input.key_just_pressed(KeyA) {
    let next_index = cursor.modify(fn(value) {
      let next_index = value.next
      value.next = next_index + 1
      next_index
    })
    spawn_enemy(
      commands,
      asset_server.get().load("textures/simplespace/enemy_A.png"),
      enemy_blueprint(next_index),
    )
  }

  if @input.key_just_pressed(KeyR) &&
    first_enemy_entity(enemies) is Some(entity) {
    commands.entity(entity).despawn()
  }
}

///|
fn move_targets(
  enemies : @app.Populated[
    (@ecs.Write[@transform.Transform], @ecs.Write[Enemy]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! enemies
  .query()
  .view(fn(_entity, data) {
    let (transform_mut, enemy_mut) = data
    let enemy = enemy_mut.modify(fn(value) {
      value.rotation = value.rotation + value.rotation_speed * delta
      value
    })
    transform_mut.modify(fn(value) {
      value.rotation = @math.Quat::from_rotation_z(enemy.rotation)
      value.translation.x = enemy.origin.x +
        @math.cos(enemy.rotation) * enemy.radius
      value.translation.y = enemy.origin.y +
        @math.sin(enemy.rotation) * enemy.radius
    })
  })
}

///|
fn track_targets(
  player : @app.Single[
    (@ecs.Write[@transform.Transform], @ecs.Read[Player]),
    @ecs.All,
  ],
  enemy_query : @ecs.Query[
    @ecs.Read[@transform.Transform],
    (@ecs.With[Enemy], @ecs.Without[Player]),
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let (player_transform_mut, player_ref) = player.get()
  let current_transform = player_transform_mut.value()
  let player_value = player_ref.value()

  let enemy_transform_opt = try Some(enemy_query.require_single()) catch {
    @ecs.Skipped(_) => None
    _ => None
  } noraise {
    value => value
  }

  match enemy_transform_opt {
    Some(enemy_transform) => {
      let enemy_transform = enemy_transform.value()
      let delta = @math.Vec2::new(
        enemy_transform.translation.x - current_transform.translation.x,
        enemy_transform.translation.y - current_transform.translation.y,
      )
      let distance = delta.length()
      let front = delta.normalize_or_zero()
      if front.length() > 0.0F {
        let next_transform = current_transform
        next_transform.rotation = @math.Quat::from_rotation_z(
          front.to_angle() - @math.pi_half(),
        )
        let max_step = distance - player_value.min_follow_radius
        if 0.0F < max_step {
          let velocity = minf(
            player_value.speed * time.get().delta_seconds(),
            max_step,
          )
          next_transform.translation.x = next_transform.translation.x +
            front.x * velocity
          next_transform.translation.y = next_transform.translation.y +
            front.y * velocity
        }
        player_transform_mut.set(next_transform)
      }
    }
    None =>
      player_transform_mut.modify(fn(value) {
        value.rotate_z(player_value.rotation_speed * time.get().delta_seconds())
      })
  }
}

///|
fn do_nothing_fail_validation(
  _never_matches : @app.Single[
    @core.Entity,
    (@ecs.With[Player], @ecs.With[Enemy]),
  ],
) -> Unit {
  ()
}
