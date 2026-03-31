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
pub fn rapier2d_spawn_camera(world : @ecs.World, x : Float, y : Float) -> Unit {
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(x, y, 0.0F),
  ).spawn(world)
  |> ignore
}

///|
pub fn rapier2d_set_clear_color(
  world : @ecs.World,
  color : @sprite.Color,
) -> Unit {
  world.insert_resource(
    @sprite.ClearColor::resource(),
    @sprite.ClearColor::new(color),
  )
}

///|
pub fn rapier2d_set_gravity(world : @ecs.World, gravity : @math.Vec2) -> Unit {
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current) => cfg_res.insert(current.with_gravity(gravity))
    None => cfg_res.insert(@physics2d.Physics2dConfig::new(gravity))
  }
}

///|
pub fn rapier2d_default_plugins() -> Array[@app.Plugin[@ecs.World]] {
  @mgstudio.default_plugins()
}

///|
pub fn rapier2d_spawn_sprite_box(
  world : @ecs.World,
  texture : @asset.Handle[@image.Image],
  position : @math.Vec2,
  half_size : @math.Vec2,
  z : Float,
  color : @sprite.Color,
) -> @core.Entity {
  @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(texture)
    .with_color(color)
    .with_custom_size(
      Some(@math.Vec2::new(half_size.x * 2.0F, half_size.y * 2.0F)),
    ),
    @transform.Transform::from_xy_rotation_scale(
      position,
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z~,
    ),
  ).spawn(world)
}

///|
pub fn rapier2d_spawn_camera_and_clear(
  world : @ecs.World,
  clear_color : @sprite.Color,
  camera_position : @math.Vec2,
) -> Unit {
  rapier2d_set_clear_color(world, clear_color)
  rapier2d_spawn_camera(world, camera_position.x, camera_position.y)
}

///|
fn rapier2d_spawn_physics_sprite(
  world : @ecs.World,
  texture : @asset.Handle[@image.Image],
  position : @math.Vec2,
  half_size : @math.Vec2,
  z : Float,
  color : @sprite.Color,
  body : @physics2d.RigidBody2d,
  shape : @physics2d.ColliderShape2d,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      position,
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z~,
    ),
  )
  try! world.set_by_key(
    entity,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(color)
    .with_custom_size(
      Some(@math.Vec2::new(half_size.x * 2.0F, half_size.y * 2.0F)),
    ),
  )
  try! world.set_by_key(entity, @physics2d.ecs_key_rigid_body2d, body)
  try! world.set_by_key(
    entity,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(shape),
  )
  entity
}

///|
pub fn rapier2d_spawn_dynamic_box(
  world : @ecs.World,
  texture : @asset.Handle[@image.Image],
  position : @math.Vec2,
  half_size : @math.Vec2,
  z : Float,
  color : @sprite.Color,
) -> @core.Entity {
  rapier2d_spawn_physics_sprite(
    world,
    texture,
    position,
    half_size,
    z,
    color,
    @physics2d.RigidBody2d::dynamic(),
    @physics2d.ColliderShape2d::cuboid(half_size.x, half_size.y),
  )
}

///|
pub fn rapier2d_spawn_fixed_box(
  world : @ecs.World,
  texture : @asset.Handle[@image.Image],
  position : @math.Vec2,
  half_size : @math.Vec2,
  z : Float,
  color : @sprite.Color,
) -> @core.Entity {
  rapier2d_spawn_physics_sprite(
    world,
    texture,
    position,
    half_size,
    z,
    color,
    @physics2d.RigidBody2d::fixed(),
    @physics2d.ColliderShape2d::cuboid(half_size.x, half_size.y),
  )
}

///|
pub fn rapier2d_spawn_dynamic_ball(
  world : @ecs.World,
  texture : @asset.Handle[@image.Image],
  position : @math.Vec2,
  radius : Float,
  z : Float,
  color : @sprite.Color,
) -> @core.Entity {
  rapier2d_spawn_physics_sprite(
    world,
    texture,
    position,
    @math.Vec2::new(radius, radius),
    z,
    color,
    @physics2d.RigidBody2d::dynamic(),
    @physics2d.ColliderShape2d::ball(radius),
  )
}

///|
pub fn rapier2d_spawn_fixed_ball(
  world : @ecs.World,
  texture : @asset.Handle[@image.Image],
  position : @math.Vec2,
  radius : Float,
  z : Float,
  color : @sprite.Color,
) -> @core.Entity {
  rapier2d_spawn_physics_sprite(
    world,
    texture,
    position,
    @math.Vec2::new(radius, radius),
    z,
    color,
    @physics2d.RigidBody2d::fixed(),
    @physics2d.ColliderShape2d::ball(radius),
  )
}

///|
pub fn rapier2d_spawn_static_bounds(
  world : @ecs.World,
  texture : @asset.Handle[@image.Image],
  floor_y : Float,
  half_width : Float,
  half_height : Float,
) -> Unit {
  let thickness = half_height
  let width = half_width
  let wall_x = width + thickness
  rapier2d_spawn_fixed_box(
    world,
    texture,
    @math.Vec2::new(0.0F, floor_y),
    @math.Vec2::new(width, thickness),
    0.0F,
    @sprite.Color::new(0.25F, 0.25F, 0.25F, 1.0F),
  )
  |> ignore
  rapier2d_spawn_fixed_box(
    world,
    texture,
    @math.Vec2::new(-wall_x, 0.0F),
    @math.Vec2::new(thickness, half_width),
    0.0F,
    @sprite.Color::new(0.25F, 0.25F, 0.25F, 1.0F),
  )
  |> ignore
  rapier2d_spawn_fixed_box(
    world,
    texture,
    @math.Vec2::new(wall_x, 0.0F),
    @math.Vec2::new(thickness, half_width),
    0.0F,
    @sprite.Color::new(0.25F, 0.25F, 0.25F, 1.0F),
  )
  |> ignore
}
