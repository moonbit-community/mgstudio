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
const PIXELS_PER_FRAME : Int = 64

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
priv struct CpuDrawState {
  mut texture : @asset.Handle[@asset.Image]?
  mut draw_index : Int
}

///|
let cpu_draw_state : Ref[CpuDrawState] = Ref::new(CpuDrawState::{
  texture: None,
  draw_index: 0,
})

///|
pub fn app_main() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(cpu_draw_setup)
  .add_system(cpu_draw_update)
  .run()
}

///|
fn cpu_draw_setup(world : @ecs_world.World) -> Unit {
  let texture = @asset.asset_create_dynamic_texture(
    @math.UVec2::new(IMAGE_WIDTH, IMAGE_HEIGHT),
    false,
  )
  @asset.asset_update_texture_region_rgba8(
    texture,
    full_texture_rect(),
    build_initial_pixels(),
  )
  @render2d.SpriteBundle::new(
    @render2d.Sprite::from_image(texture),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
  cpu_draw_state.val.texture = Some(texture)
  cpu_draw_state.val.draw_index = 0
}

///|
fn cpu_draw_update(_world : @ecs_world.World) -> Unit {
  if cpu_draw_state.val.texture is Some(texture) {
    for i in 0..<PIXELS_PER_FRAME {
      draw_spiral_pixel(texture, cpu_draw_state.val.draw_index + i)
    }
    cpu_draw_state.val.draw_index = cpu_draw_state.val.draw_index +
      PIXELS_PER_FRAME
  }
}

///|
fn draw_spiral_pixel(
  texture : @asset.Handle[@asset.Image],
  draw_index : Int,
) -> Unit {
  let center_x = int_to_float(IMAGE_WIDTH) * 0.5F
  let center_y = int_to_float(IMAGE_HEIGHT) * 0.5F
  let max_radius = int_to_float(min_int(IMAGE_WIDTH, IMAGE_HEIGHT)) * 0.5F
  let sample = int_to_float(draw_index)
  let radius = @math.sin(sample * SPIRAL_PERIOD) * max_radius
  let angle = sample * SPIRAL_ROT_SPEED
  let x = clamp_int(
    (center_x + @math.cos(angle) * radius).to_int(),
    0,
    IMAGE_WIDTH - 1,
  )
  let y = clamp_int(
    (center_y + @math.sin(angle) * radius).to_int(),
    0,
    IMAGE_HEIGHT - 1,
  )
  let pixel = Bytes::from_array([
    ((draw_index * 17 + x * 7 + 29) % 256).to_byte(),
    ((draw_index * 31 + y * 11 + 71) % 256).to_byte(),
    ((draw_index * 43 + x * 5 + y * 3 + 131) % 256).to_byte(),
    compute_alpha(x, y).to_byte(),
  ])
  @asset.asset_update_texture_region_rgba8(
    texture,
    @math.URect::new(@math.UVec2::new(x, y), @math.UVec2::new(x + 1, y + 1)),
    pixel,
  )
}

///|
fn build_initial_pixels() -> Bytes {
  let pixels : Array[Byte] = []
  for y in 0..<IMAGE_HEIGHT {
    for x in 0..<IMAGE_WIDTH {
      pixels.push(BASE_R.to_byte())
      pixels.push(BASE_G.to_byte())
      pixels.push(BASE_B.to_byte())
      pixels.push(compute_alpha(x, y).to_byte())
    }
  }
  Bytes::from_array(pixels)
}

///|
fn compute_alpha(x : Int, y : Int) -> Int {
  let center_x = int_to_float(IMAGE_WIDTH) * 0.5F
  let center_y = int_to_float(IMAGE_HEIGHT) * 0.5F
  let dx = int_to_float(x) - center_x
  let dy = int_to_float(y) - center_y
  let distance = @math.sqrt(dx * dx + dy * dy)
  let max_radius = int_to_float(min_int(IMAGE_WIDTH, IMAGE_HEIGHT)) * 0.5F
  let alpha_ratio = 1.0F - clamp_float(distance / max_radius, 0.0F, 1.0F)
  clamp_int((alpha_ratio * 255.0F).to_int(), 0, 255)
}

///|
fn full_texture_rect() -> @math.URect {
  @math.URect::new(
    @math.UVec2::zero(),
    @math.UVec2::new(IMAGE_WIDTH, IMAGE_HEIGHT),
  )
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

///|
fn main {
  app_main()
}
