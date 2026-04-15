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
struct LinearColor {
  r : Float
  g : Float
  b : Float
} derive(ToJson, FromJson)

///|
impl @app.FromWorld for LinearColor with from_world(world) {
  ignore(world)
  LinearColor::{ r: 0.0F, g: 0.0F, b: 0.0F }
}

///|
struct MyProcGenImage {
  handle : @asset.Handle[@asset.Image]
}

///|
let my_proc_gen_image_key : @ecs.ResourceKey[MyProcGenImage] = @ecs.register_resource(
  debug_name="examples.2d.cpu_draw.MyProcGenImage",
)

///|
pub impl @app.Resource for MyProcGenImage with resource() {
  my_proc_gen_image_key
}

///|
struct SeededRng {
  rng : @random.Rand
}

///|
let seeded_rng_key : @ecs.ResourceKey[SeededRng] = @ecs.register_resource(
  debug_name="examples.2d.cpu_draw.SeededRng",
)

///|
pub impl @app.Resource for SeededRng with resource() {
  seeded_rng_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .insert_resource(@time.Time::from_hz(120.0F))
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.FixedUpdate, @app.system(@app.system_param5(draw)))
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  images : @app.ResMut[@asset.Assets[@asset.Image]],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let handle = images.get_ref().val.add(
    @asset.Image::new(
      IMAGE_WIDTH,
      IMAGE_HEIGHT,
      Bytes::from_array(build_initial_pixels()),
    ),
  )

  ignore(commands.spawn_component(@sprite.Sprite::from_image(handle)))
  commands.insert_resource(MyProcGenImage::{ handle, })
  commands.insert_resource(SeededRng::{ rng: seeded_rng() })
}

///|
fn draw(
  my_handle : @app.Res[MyProcGenImage],
  images : @app.ResMut[@asset.Assets[@asset.Image]],
  i : @app.Local[Int],
  draw_color : @app.Local[LinearColor],
  seeded_rng : @app.ResMut[SeededRng],
) -> Unit {
  let images_ref = images.get_ref()
  guard images_ref.val.get(my_handle.get().handle) is Some(image) else {
    return
  }

  let seeded_rng_ref = seeded_rng.get_ref()
  if i.get() == 0 {
    draw_color.get_ref().val = next_random_color(seeded_rng_ref.val.rng)
  }

  let center = @math.Vec2::new(
    int_to_float(IMAGE_WIDTH) * 0.5F,
    int_to_float(IMAGE_HEIGHT) * 0.5F,
  )
  let max_radius = int_to_float(min_int(IMAGE_WIDTH, IMAGE_HEIGHT)) * 0.5F
  let index = i.get()
  let sample = int_to_float(index)
  let radius = @math.sin(sample * SPIRAL_PERIOD) * max_radius
  let angle = sample * SPIRAL_ROT_SPEED
  let xy = @math.Vec2::from_angle(angle).mul_scalar(radius).add(center)
  let x = clamp_int(xy.x.to_int(), 0, IMAGE_WIDTH - 1)
  let y = clamp_int(xy.y.to_int(), 0, IMAGE_HEIGHT - 1)

  let pixels = image.pixels.to_array()
  let start = (y * IMAGE_WIDTH + x) * 4
  let old_color = LinearColor::{
    r: byte_to_float(pixels[start]),
    g: byte_to_float(pixels[start + 1]),
    b: byte_to_float(pixels[start + 2]),
  }
  let old_alpha = pixels[start + 3]

  if color_distance(old_color, draw_color.get()) <= COLOR_DISTANCE_TOLERANCE {
    draw_color.get_ref().val = next_random_color(seeded_rng_ref.val.rng)
  }

  pixels[start] = color_channel_to_byte(draw_color.get().r)
  pixels[start + 1] = color_channel_to_byte(draw_color.get().g)
  pixels[start + 2] = color_channel_to_byte(draw_color.get().b)
  pixels[start + 3] = old_alpha

  ignore(
    images_ref.val.set(
      my_handle.get().handle,
      @asset.Image::new(image.width, image.height, Bytes::from_array(pixels)),
    ),
  )

  i.set(index + 1)
}

///|
fn seeded_rng() -> @random.Rand {
  @random.Rand::chacha8(seed=b"bevy-cpu-draw-seed19878367467712")
}

///|
fn next_random_color(rng : @random.Rand) -> LinearColor {
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
