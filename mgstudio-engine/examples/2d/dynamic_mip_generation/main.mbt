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
const BASE_WIDTH : Int = 256

///|
const BASE_HEIGHT : Int = 256

///|
const MIN_VISUAL_SIZE : Float = 40.0F

///|
const MAX_VISUAL_SIZE : Float = 560.0F

///|
priv struct DynamicMipState {
  mut sprite : @core.Entity?
  mut current_level : Int
  mut textures : Array[@asset.Handle[@asset.Image]]
}

///|
let dynamic_mip_state : Ref[DynamicMipState] = Ref::new(DynamicMipState::{
  sprite: None,
  current_level: 0,
  textures: [],
})

///|
pub fn game_main() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(dynamic_mip_setup)
  .add_system(dynamic_mip_update)
  .run()
}

///|
fn dynamic_mip_setup(world : @ecs_world.World) -> Unit {
  let base_pixels = build_base_level_pixels()
  let mip_textures = @asset.asset_create_dynamic_texture_mip_chain_rgba8(
    BASE_WIDTH,
    BASE_HEIGHT,
    base_pixels,
    false,
  )
  if mip_textures.length() == 0 {
    return
  }
  let sprite_entity = @render2d.SpriteBundle::new(
    @render2d.Sprite::from_image(mip_textures[0]).with_custom_size(
      Some(@math.Vec2::new(1.0F, 1.0F)),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  dynamic_mip_state.val.sprite = Some(sprite_entity)
  dynamic_mip_state.val.current_level = 0
  dynamic_mip_state.val.textures = mip_textures

  spawn_mip_previews(world)
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
}

///|
fn dynamic_mip_update(world : @ecs_world.World) -> Unit {
  guard dynamic_mip_state.val.sprite is Some(sprite_entity) else { return }
  let textures = dynamic_mip_state.val.textures
  if textures.length() == 0 {
    return
  }
  let elapsed = @time.time_elapsed_seconds()
  let oscillation = (1.0F + @math.sin(elapsed * 0.8F)) * 0.5F
  let display_size = MIN_VISUAL_SIZE +
    (MAX_VISUAL_SIZE - MIN_VISUAL_SIZE) * oscillation
  let next_level = pick_mip_level(display_size, textures.length())
  let tick = world.read_change_tick()

  let transform_store = world.get_transform_store()
  if transform_store.get(sprite_entity) is Some(transform) {
    let next_transform = @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(transform.translation.x, transform.translation.y),
      transform.rotation_z(),
      @math.Vec2::new(display_size, display_size),
      z=transform.translation.z,
    )
    transform_store.set(sprite_entity, next_transform, tick) |> ignore
  }
  if next_level != dynamic_mip_state.val.current_level {
    let sprite_store = world.get_sprite_store()
    if sprite_store.get(sprite_entity) is Some(_sprite) {
      let next_sprite = @render2d.Sprite::from_image(textures[next_level]).with_custom_size(
        Some(@math.Vec2::new(1.0F, 1.0F)),
      )
      sprite_store.set(sprite_entity, next_sprite, tick) |> ignore
      dynamic_mip_state.val.current_level = next_level
    }
  }
}

///|
fn pick_mip_level(display_size : Float, mip_count : Int) -> Int {
  if mip_count <= 1 {
    return 0
  }
  let base_size = Float::from_double(BASE_WIDTH.to_double())
  let mut ratio = base_size / display_size
  if ratio < 1.0F {
    ratio = 1.0F
  }
  let mut level = 0
  while ratio >= 2.0F && level + 1 < mip_count {
    ratio = ratio * 0.5F
    level = level + 1
  }
  level
}

///|
fn build_base_level_pixels() -> Bytes {
  let pixels : Array[Byte] = []
  let center_x = Float::from_double(BASE_WIDTH.to_double()) * 0.5F
  let center_y = Float::from_double(BASE_HEIGHT.to_double()) * 0.5F
  let max_radius = Float::from_double(BASE_WIDTH.to_double()) * 0.5F
  for y in 0..<BASE_HEIGHT {
    for x in 0..<BASE_WIDTH {
      let dx = Float::from_double(x.to_double()) - center_x
      let dy = Float::from_double(y.to_double()) - center_y
      let radial = @math.sqrt(dx * dx + dy * dy) / max_radius
      let clamped = if radial > 1.0F { 1.0F } else { radial }
      let u = Float::from_double(x.to_double()) /
        Float::from_double((BASE_WIDTH - 1).to_double())
      let v = Float::from_double(y.to_double()) /
        Float::from_double((BASE_HEIGHT - 1).to_double())
      let r = ((0.5F + 0.5F * @math.sin(u * 24.0F)) * 255.0F).to_int()
      let g = ((0.5F + 0.5F * @math.sin(v * 18.0F + 1.7F)) * 255.0F).to_int()
      let b = ((1.0F - clamped) * 255.0F).to_int()
      pixels.push(clamp_to_byte(r))
      pixels.push(clamp_to_byte(g))
      pixels.push(clamp_to_byte(b))
      pixels.push((255).to_byte())
    }
  }
  Bytes::from_array(pixels)
}

///|
fn spawn_mip_previews(world : @ecs_world.World) -> Unit {
  let textures = dynamic_mip_state.val.textures
  let count = textures.length()
  if count == 0 {
    return
  }
  let mut x = -520.0F
  let mut preview_size = 84.0F
  for i in 0..<count {
    let sprite = @render2d.Sprite::from_image(textures[i])
      .with_custom_size(Some(@math.Vec2::new(1.0F, 1.0F)))
      .with_color(@render2d.Color::new(1.0F, 1.0F, 1.0F, 0.85F))
    @render2d.SpriteBundle::new(
      sprite,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(x, -260.0F),
        0.0F,
        @math.Vec2::new(preview_size, preview_size),
      ),
    ).spawn(world)
    |> ignore
    x = x + preview_size + 10.0F
    preview_size = if preview_size * 0.5F < 12.0F {
      12.0F
    } else {
      preview_size * 0.5F
    }
  }
}

///|
fn clamp_to_byte(value : Int) -> Byte {
  if value < 0 {
    (0).to_byte()
  } else if value > 255 {
    (255).to_byte()
  } else {
    value.to_byte()
  }
}

///|
fn main {
  game_main()
}
