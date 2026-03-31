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
const BOUNDS_X : Float = 1200.0F

///|
const BOUNDS_Y : Float = 640.0F

///|
const EPSILON : Float = 1.0e-6F

///|
struct Player {
  movement_speed : Float
  rotation_speed : Float
}

///|
let player_key : @ecs.ComponentKey[Player] = @ecs.register_component(
  debug_name="examples.2d.rotation.Player",
)

///|
pub impl @ecs.Component for Player with component() {
  player_key
}

///|
struct SnapToPlayer {}

///|
let snap_to_player_key : @ecs.ComponentKey[SnapToPlayer] = @ecs.register_component(
  debug_name="examples.2d.rotation.SnapToPlayer",
)

///|
pub impl @ecs.Component for SnapToPlayer with component() {
  snap_to_player_key
}

///|
struct RotateToPlayer {
  rotation_speed : Float
}

///|
let rotate_to_player_key : @ecs.ComponentKey[RotateToPlayer] = @ecs.register_component(
  debug_name="examples.2d.rotation.RotateToPlayer",
)

///|
pub impl @ecs.Component for RotateToPlayer with component() {
  rotate_to_player_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .insert_resource(@time.Time::from_hz(60.0F))
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(
    @app.FixedUpdate,
    @app.system(@app.system_param3(player_movement_system)),
  )
  .add_systems(
    @app.FixedUpdate,
    @app.system(@app.system_param2(snap_to_player_system)),
  )
  .add_systems(
    @app.FixedUpdate,
    @app.system(@app.system_param3(rotate_to_player_system)),
  )
  .run()
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
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
fn acosf(value : Float) -> Float {
  let clamped = clampf(value, -1.0F, 1.0F)
  let y = @math.sqrt(1.0F - clamped * clamped)
  @math.atan2(y, clamped)
}

///|
fn vec2_dot(a : @math.Vec2, b : @math.Vec2) -> Float {
  a.x * b.x + a.y * b.y
}

///|
fn vec2_normalize_or_zero(v : @math.Vec2) -> @math.Vec2 {
  let len_sq = v.x * v.x + v.y * v.y
  if len_sq <= 1.0e-12F {
    return @math.Vec2::new(0.0F, 0.0F)
  }
  let inv_len = 1.0F / @math.sqrt(len_sq)
  @math.Vec2::new(v.x * inv_len, v.y * inv_len)
}

///|
fn spawn_help_overlay(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
        @text.Text::new("Up Arrow: Move Forward\nLeft / Right Arrow: Turn"),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
      ),
    ),
  )
}

///|
fn player_translation(
  player_query : @ecs.Query[@ecs.Comp[@transform.Transform], @ecs.With[Player]],
) -> @math.Vec2? {
  match (player_query.single() catch { _ => None }) {
    Some(transform) => {
      let value = transform.value()
      Some(@math.Vec2::new(value.translation.x, value.translation.y))
    }
    None => None
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let ship_handle = asset_server.get().load("textures/simplespace/ship_C.png")
  let enemy_a_handle = asset_server
    .get()
    .load("textures/simplespace/enemy_A.png")
  let enemy_b_handle = asset_server
    .get()
    .load("textures/simplespace/enemy_B.png")

  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  spawn_help_overlay(commands, asset_server)

  let horizontal_margin = BOUNDS_X / 4.0F
  let vertical_margin = BOUNDS_Y / 4.0F

  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(ship_handle),
        Player::{ movement_speed: 500.0F, rotation_speed: 6.28318530718F },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(enemy_a_handle),
        @transform.Transform::from_xyz(-horizontal_margin, 0.0F, 0.0F),
        SnapToPlayer::{  },
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(
          asset_server.get().load("textures/simplespace/enemy_A.png"),
        ),
        @transform.Transform::from_xyz(0.0F, -vertical_margin, 0.0F),
        SnapToPlayer::{  },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(enemy_b_handle),
        @transform.Transform::from_xyz(horizontal_margin, 0.0F, 0.0F),
        RotateToPlayer::{ rotation_speed: 0.78539816339F },
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(
          asset_server.get().load("textures/simplespace/enemy_B.png"),
        ),
        @transform.Transform::from_xyz(0.0F, vertical_margin, 0.0F),
        RotateToPlayer::{ rotation_speed: 1.57079632679F },
      ),
    ),
  )
}

///|
fn player_movement_system(
  time : @app.Res[@time.Time[@time.Fixed]],
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  query : @ecs.Query[
    (@ecs.Comp[Player], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  try! query.for_each(fn(_entity, data) {
    let (player, transform) = data
    let player = player.value()
    let transform_ref = transform.get_ref()
    let mut rotation_factor = 0.0F
    let mut movement_factor = 0.0F

    if keyboard_input.pressed(@window.KeyCode::ArrowLeft) {
      rotation_factor += 1.0F
    }
    if keyboard_input.pressed(@window.KeyCode::ArrowRight) {
      rotation_factor -= 1.0F
    }
    if keyboard_input.pressed(@window.KeyCode::ArrowUp) {
      movement_factor += 1.0F
    }

    transform_ref.val.rotate_z(
      rotation_factor * player.rotation_speed * time.get().delta_seconds(),
    )

    let movement_direction = transform_ref.val.local_y()
    let movement_distance = movement_factor *
      player.movement_speed *
      time.get().delta_seconds()
    transform_ref.val.translation.x = clampf(
      transform_ref.val.translation.x + movement_direction.x * movement_distance,
      -BOUNDS_X / 2.0F,
      BOUNDS_X / 2.0F,
    )
    transform_ref.val.translation.y = clampf(
      transform_ref.val.translation.y + movement_direction.y * movement_distance,
      -BOUNDS_Y / 2.0F,
      BOUNDS_Y / 2.0F,
    )
  })
}

///|
fn snap_to_player_system(
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[SnapToPlayer]],
  player_query : @ecs.Query[@ecs.Comp[@transform.Transform], @ecs.With[Player]],
) -> Unit {
  guard player_translation(player_query) is Some(player_position) else {
    return
  }

  try! query.for_each(fn(_entity, enemy_transform) {
    let enemy_transform_ref = enemy_transform.get_ref()
    let to_player = vec2_normalize_or_zero(
      @math.Vec2::new(
        player_position.x - enemy_transform_ref.val.translation.x,
        player_position.y - enemy_transform_ref.val.translation.y,
      ),
    )
    if absf(to_player.x) <= EPSILON && absf(to_player.y) <= EPSILON {
      return
    }

    enemy_transform_ref.val.rotation = @math.Quat::from_rotation_z(
      to_player.to_angle() - @math.pi_half(),
    )
  })
}

///|
fn rotate_to_player_system(
  time : @app.Res[@time.Time[@time.Fixed]],
  query : @ecs.Query[
    (@ecs.Comp[RotateToPlayer], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
  player_query : @ecs.Query[@ecs.Comp[@transform.Transform], @ecs.With[Player]],
) -> Unit {
  guard player_translation(player_query) is Some(player_position) else {
    return
  }

  try! query.for_each(fn(_entity, data) {
    let (config, enemy_transform) = data
    let config = config.value()
    let enemy_transform_ref = enemy_transform.get_ref()
    let enemy_forward3 = enemy_transform_ref.val.local_y()
    let enemy_forward = @math.Vec2::new(enemy_forward3.x, enemy_forward3.y)
    let to_player = vec2_normalize_or_zero(
      @math.Vec2::new(
        player_position.x - enemy_transform_ref.val.translation.x,
        player_position.y - enemy_transform_ref.val.translation.y,
      ),
    )
    if absf(to_player.x) <= EPSILON && absf(to_player.y) <= EPSILON {
      return
    }

    let forward_dot_player = vec2_dot(enemy_forward, to_player)
    if absf(forward_dot_player - 1.0F) < EPSILON {
      return
    }

    let enemy_right3 = enemy_transform_ref.val.local_x()
    let enemy_right = @math.Vec2::new(enemy_right3.x, enemy_right3.y)
    let right_dot_player = vec2_dot(enemy_right, to_player)
    let rotation_sign = if right_dot_player < 0.0F { 1.0F } else { -1.0F }
    let max_angle = acosf(forward_dot_player)
    let rotation_angle = rotation_sign *
      minf(config.rotation_speed * time.get().delta_seconds(), max_angle)
    enemy_transform_ref.val.rotate_z(rotation_angle)
  })
}
