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
const IMAGE_WIDTH : Int = 256

///|
const IMAGE_HEIGHT : Int = 256

///|
const FIXED_TIMESTEP_SECONDS : Float = 0.0009765625F

///|
const SPIRAL_ROT_SPEED : Float = 0.0123F

///|
const SPIRAL_PERIOD : Float = 0.12345F

///|
const BASE_R : Int = 245

///|
const BASE_G : Int = 245

///|
const BASE_B : Int = 220

///|
const COLOR_DISTANCE_TOLERANCE : Float = 0.003921569F

///|
priv struct LinearColor {
  r : Float
  g : Float
  b : Float
}

///|
priv struct CpuDrawState {
  mut texture : @asset.Handle[@asset.Image]?
  mut draw_index : Int
  mut draw_color : LinearColor
  mut draw_color_initialized : Bool
  mut pixels : Array[Byte]
  mut rng : @random.Rand
}

///|
let cpu_draw_state : Ref[CpuDrawState] = Ref::new(CpuDrawState::{
  texture: None,
  draw_index: 0,
  draw_color: LinearColor::{ r: 0.0F, g: 0.0F, b: 0.0F },
  draw_color_initialized: false,
  pixels: [],
  rng: seeded_rng(),
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .insert_resource(@time.Fixed::from_seconds(FIXED_TIMESTEP_SECONDS))
  .add_startup_system(cpu_draw_setup)
  .add_fixed_update_system(cpu_draw_draw)
  .run()
}

///|
fn cpu_draw_setup(world : @ecs.World) -> Unit {
  let texture = @asset.asset_create_dynamic_texture(
    @math.UVec2::new(IMAGE_WIDTH, IMAGE_HEIGHT),
    false,
  )

  let initial_pixels = build_initial_pixels()
  @asset.asset_update_texture_region_rgba8(
    texture,
    full_texture_rect(),
    Bytes::from_array(initial_pixels),
  )

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  @render2d.SpriteBundle::new(
    @render2d.Sprite::from_image(texture),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  cpu_draw_state.val.texture = Some(texture)
  cpu_draw_state.val.draw_index = 0
  cpu_draw_state.val.draw_color = LinearColor::{ r: 0.0F, g: 0.0F, b: 0.0F }
  cpu_draw_state.val.draw_color_initialized = false
  cpu_draw_state.val.pixels = initial_pixels
  cpu_draw_state.val.rng = seeded_rng()
}

///|
fn cpu_draw_draw(_world : @ecs.World) -> Unit {
  guard cpu_draw_state.val.texture is Some(texture) else { return }

  if !cpu_draw_state.val.draw_color_initialized {
    cpu_draw_state.val.draw_color = next_random_color()
    cpu_draw_state.val.draw_color_initialized = true
  }

  let center = @math.Vec2::new(
    int_to_float(IMAGE_WIDTH) * 0.5F,
    int_to_float(IMAGE_HEIGHT) * 0.5F,
  )
  let max_radius = int_to_float(min_int(IMAGE_WIDTH, IMAGE_HEIGHT)) * 0.5F
  let sample = int_to_float(cpu_draw_state.val.draw_index)
  let radius = @math.sin(sample * SPIRAL_PERIOD) * max_radius
  let angle = sample * SPIRAL_ROT_SPEED

  let x = clamp_int(
    (center.x + @math.cos(angle) * radius).to_int(),
    0,
    IMAGE_WIDTH - 1,
  )
  let y = clamp_int(
    (center.y + @math.sin(angle) * radius).to_int(),
    0,
    IMAGE_HEIGHT - 1,
  )

  let start = (y * IMAGE_WIDTH + x) * 4
  let old_color = LinearColor::{
    r: byte_to_float(cpu_draw_state.val.pixels[start]),
    g: byte_to_float(cpu_draw_state.val.pixels[start + 1]),
    b: byte_to_float(cpu_draw_state.val.pixels[start + 2]),
  }
  let old_alpha = cpu_draw_state.val.pixels[start + 3]

  if color_distance(old_color, cpu_draw_state.val.draw_color) <=
    COLOR_DISTANCE_TOLERANCE {
    cpu_draw_state.val.draw_color = next_random_color()
  }

  let new_r = color_channel_to_byte(cpu_draw_state.val.draw_color.r)
  let new_g = color_channel_to_byte(cpu_draw_state.val.draw_color.g)
  let new_b = color_channel_to_byte(cpu_draw_state.val.draw_color.b)

  cpu_draw_state.val.pixels[start] = new_r
  cpu_draw_state.val.pixels[start + 1] = new_g
  cpu_draw_state.val.pixels[start + 2] = new_b

  @asset.asset_update_texture_region_rgba8(
    texture,
    @math.URect::new(@math.UVec2::new(x, y), @math.UVec2::new(x + 1, y + 1)),
    Bytes::from_array([new_r, new_g, new_b, old_alpha]),
  )

  cpu_draw_state.val.draw_index = cpu_draw_state.val.draw_index + 1
}

///|
fn seeded_rng() -> @random.Rand {
  @random.Rand::chacha8(seed=b"bevy-cpu-draw-seed19878367467712")
}

///|
fn next_random_color() -> LinearColor {
  let rng = cpu_draw_state.val.rng
  LinearColor::{ r: rng.float(), g: rng.float(), b: rng.float() }
}

///|
fn color_distance(a : LinearColor, b : LinearColor) -> Float {
  let dr = a.r - b.r
  let dg = a.g - b.g
  let db = a.b - b.b
  @math.sqrt(dr * dr + dg * dg + db * db)
}

///|
fn build_initial_pixels() -> Array[Byte] {
  let pixels : Array[Byte] = []
  let center_x = int_to_float(IMAGE_WIDTH) * 0.5F
  let center_y = int_to_float(IMAGE_HEIGHT) * 0.5F
  let max_radius = int_to_float(min_int(IMAGE_WIDTH, IMAGE_HEIGHT)) * 0.5F

  for y in 0..<IMAGE_HEIGHT {
    for x in 0..<IMAGE_WIDTH {
      let dx = int_to_float(x) - center_x
      let dy = int_to_float(y) - center_y
      let distance = @math.sqrt(dx * dx + dy * dy)
      let alpha_ratio = 1.0F - clamp_float(distance / max_radius, 0.0F, 1.0F)

      pixels.push(BASE_R.to_byte())
      pixels.push(BASE_G.to_byte())
      pixels.push(BASE_B.to_byte())
      pixels.push(clamp_int((alpha_ratio * 255.0F).to_int(), 0, 255).to_byte())
    }
  }

  pixels
}

///|
fn full_texture_rect() -> @math.URect {
  @math.URect::new(
    @math.UVec2::zero(),
    @math.UVec2::new(IMAGE_WIDTH, IMAGE_HEIGHT),
  )
}

///|
fn color_channel_to_byte(channel : Float) -> Byte {
  let clamped = clamp_float(channel, 0.0F, 1.0F)
  clamp_int((clamped * 255.0F).to_int(), 0, 255).to_byte()
}

///|
fn byte_to_float(value : Byte) -> Float {
  int_to_float(value.to_int()) / 255.0F
}

///|
fn int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn clamp_int(value : Int, lower : Int, upper : Int) -> Int {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}

///|
fn clamp_float(value : Float, lower : Float, upper : Float) -> Float {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}
