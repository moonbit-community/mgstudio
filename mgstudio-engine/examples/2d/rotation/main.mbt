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
/// Port of `bevy/examples/2d/rotation.rs`.
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .insert_resource(@time.Time::from_seconds(1.0F / 60.0F))
  .add_systems(@app.Startup, @app.system(rotation_setup))
  .add_systems(@app.FixedUpdate, @app.system(player_movement_system))
  .add_systems(@app.FixedUpdate, @app.system(snap_to_player_system))
  .add_systems(@app.FixedUpdate, @app.system(rotate_to_player_system))
  .run()
}

///|
const BOUNDS_X : Float = 1200.0F

///|
const BOUNDS_Y : Float = 640.0F

///|
const PLAYER_MOVEMENT_SPEED : Float = 500.0F

///|
const PLAYER_ROTATION_SPEED : Float = 6.28318530718F

///|
const ROTATE_SPEED_SLOW : Float = 0.78539816339F

///|
const ROTATE_SPEED_FAST : Float = 1.57079632679F

///|
const EPSILON : Float = 1.0e-6F

///|
priv struct RotationState {
  mut player : @core.Entity
  mut snap_targets : Array[@core.Entity]
  mut rotate_targets : Array[(@core.Entity, Float)]
}

///|
let rotation_state : Ref[RotationState] = Ref::new(RotationState::{
  player: @core.Entity::placeholder(),
  snap_targets: [],
  rotate_targets: [],
})

///|
fn entity_is_same(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
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
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
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
fn forward_from_rotation(rotation : Float) -> @math.Vec2 {
  @math.Vec2::new(-@math.sin(rotation), @math.cos(rotation))
}

///|
fn right_from_rotation(rotation : Float) -> @math.Vec2 {
  @math.Vec2::new(@math.cos(rotation), @math.sin(rotation))
}

///|
fn spawn_help_overlay(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new("Up Arrow: Move Forward\nLeft / Right Arrow: Turn"),
      @text.TextFont::default().with_font(font).with_font_size(20.0F),
      @transform.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )
  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn spawn_ship(
  world : @ecs.World,
  texture : @asset.Handle[@asset.Image],
  translation : @math.Vec2,
) -> @core.Entity {
  @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(texture),
    @transform.Transform::from_xy_rotation_scale(
      translation,
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
}

///|
fn rotation_setup(world : @ecs.World) -> Unit {
  rotation_state.val.player = @core.Entity::placeholder()
  rotation_state.val.snap_targets = []
  rotation_state.val.rotate_targets = []

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  spawn_help_overlay(world)

  let asset_server = @asset.AssetServer::new()
  let ship_handle = asset_server.load("textures/simplespace/ship_C.png")
  let enemy_a_handle = asset_server.load("textures/simplespace/enemy_A.png")
  let enemy_b_handle = asset_server.load("textures/simplespace/enemy_B.png")

  let horizontal_margin = BOUNDS_X / 4.0F
  let vertical_margin = BOUNDS_Y / 4.0F

  let player = spawn_ship(world, ship_handle, @math.Vec2::new(0.0F, 0.0F))
  rotation_state.val.player = player

  let snap_left = spawn_ship(
    world,
    enemy_a_handle,
    @math.Vec2::new(-horizontal_margin, 0.0F),
  )
  let snap_bottom = spawn_ship(
    world,
    enemy_a_handle,
    @math.Vec2::new(0.0F, -vertical_margin),
  )
  rotation_state.val.snap_targets = [snap_left, snap_bottom]

  let rotate_right = spawn_ship(
    world,
    enemy_b_handle,
    @math.Vec2::new(horizontal_margin, 0.0F),
  )
  let rotate_top = spawn_ship(
    world,
    enemy_b_handle,
    @math.Vec2::new(0.0F, vertical_margin),
  )
  rotation_state.val.rotate_targets = [
    (rotate_right, ROTATE_SPEED_SLOW),
    (rotate_top, ROTATE_SPEED_FAST),
  ]
}

///|
fn player_movement_system(world : @ecs.World) -> Unit {
  if rotation_state.val.player.is_placeholder() {
    return
  }
  let dt = @time.time_fixed_delta_seconds()
  let tick = world.read_change_tick()
  let transform_store = world.component(@transform.ecs_key_transform)
  guard transform_store.get(rotation_state.val.player) is Some(transform) else {
    return
  }

  let mut rotation_factor = 0.0F
  let mut movement_factor = 0.0F

  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    rotation_factor = rotation_factor + 1.0F
  }
  if @input.key_pressed(@window.KeyCode::ArrowRight) {
    rotation_factor = rotation_factor - 1.0F
  }
  if @input.key_pressed(@window.KeyCode::ArrowUp) {
    movement_factor = movement_factor + 1.0F
  }

  let next_rotation = transform.rotation_z() +
    rotation_factor * PLAYER_ROTATION_SPEED * dt
  let move_dir = forward_from_rotation(next_rotation)
  let move_distance = movement_factor * PLAYER_MOVEMENT_SPEED * dt
  let mut next_x = transform.translation.x + move_dir.x * move_distance
  let mut next_y = transform.translation.y + move_dir.y * move_distance
  next_x = clampf(next_x, -BOUNDS_X / 2.0F, BOUNDS_X / 2.0F)
  next_y = clampf(next_y, -BOUNDS_Y / 2.0F, BOUNDS_Y / 2.0F)

  let next_transform = @transform.Transform::from_xy_rotation_scale(
    @math.Vec2::new(next_x, next_y),
    next_rotation,
    @math.Vec2::new(transform.scale.x, transform.scale.y),
    z=transform.translation.z,
  )
  transform_store.set(rotation_state.val.player, next_transform, tick) |> ignore
}

///|
fn snap_to_player_system(world : @ecs.World) -> Unit {
  let player_entity = rotation_state.val.player
  if player_entity.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let transform_store = world.component(@transform.ecs_key_transform)
  guard transform_store.get(player_entity) is Some(player_transform) else {
    return
  }
  let player_position = @math.Vec2::new(
    player_transform.translation.x,
    player_transform.translation.y,
  )

  for enemy in rotation_state.val.snap_targets {
    if entity_is_same(enemy, player_entity) {
      continue
    }
    if transform_store.get(enemy) is Some(enemy_transform) {
      let to_player = vec2_normalize_or_zero(
        @math.Vec2::new(
          player_position.x - enemy_transform.translation.x,
          player_position.y - enemy_transform.translation.y,
        ),
      )
      if absf(to_player.x) <= EPSILON && absf(to_player.y) <= EPSILON {
        continue
      }
      let next_rotation = to_player.to_angle() - @math.pi_half()
      let next_transform = @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(
          enemy_transform.translation.x,
          enemy_transform.translation.y,
        ),
        next_rotation,
        @math.Vec2::new(enemy_transform.scale.x, enemy_transform.scale.y),
        z=enemy_transform.translation.z,
      )
      transform_store.set(enemy, next_transform, tick) |> ignore
    }
  }
}

///|
fn rotate_to_player_system(world : @ecs.World) -> Unit {
  let player_entity = rotation_state.val.player
  if player_entity.is_placeholder() {
    return
  }
  let dt = @time.time_fixed_delta_seconds()
  let tick = world.read_change_tick()
  let transform_store = world.component(@transform.ecs_key_transform)
  guard transform_store.get(player_entity) is Some(player_transform) else {
    return
  }
  let player_position = @math.Vec2::new(
    player_transform.translation.x,
    player_transform.translation.y,
  )

  for entry in rotation_state.val.rotate_targets {
    let enemy = entry.0
    let rotation_speed = entry.1
    if entity_is_same(enemy, player_entity) {
      continue
    }
    if transform_store.get(enemy) is Some(enemy_transform) {
      let enemy_rotation = enemy_transform.rotation_z()
      let enemy_forward = forward_from_rotation(enemy_rotation)
      let to_player = vec2_normalize_or_zero(
        @math.Vec2::new(
          player_position.x - enemy_transform.translation.x,
          player_position.y - enemy_transform.translation.y,
        ),
      )
      if absf(to_player.x) <= EPSILON && absf(to_player.y) <= EPSILON {
        continue
      }
      let forward_dot_player = vec2_dot(enemy_forward, to_player)
      if absf(forward_dot_player - 1.0F) < EPSILON {
        continue
      }

      let enemy_right = right_from_rotation(enemy_rotation)
      let right_dot_player = vec2_dot(enemy_right, to_player)
      let rotation_sign = if right_dot_player < 0.0F { 1.0F } else { -1.0F }
      let max_angle = acosf(clampf(forward_dot_player, -1.0F, 1.0F))
      let rotation_angle = rotation_sign * minf(rotation_speed * dt, max_angle)
      let next_transform = @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(
          enemy_transform.translation.x,
          enemy_transform.translation.y,
        ),
        enemy_rotation + rotation_angle,
        @math.Vec2::new(enemy_transform.scale.x, enemy_transform.scale.y),
        z=enemy_transform.translation.z,
      )
      transform_store.set(enemy, next_transform, tick) |> ignore
    }
  }
}
