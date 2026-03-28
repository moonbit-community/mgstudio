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
const BASE_WIDTH : Int = 256

///|
const BASE_HEIGHT : Int = 256

///|
fn build_base_pixels(width : Int, height : Int) -> Bytes {
  Bytes::makei(width * height * 4, fn(i) {
    let pixel = i / 4
    let x = pixel % width
    let y = pixel / width
    let gradient_x = x * 255 / width
    let gradient_y = y * 255 / height
    let checker = (x / 16 + y / 16) % 2 == 0
    let boost = if checker { 64 } else { 0 }
    match i % 4 {
      0 => (gradient_x + boost).min(255).to_byte()
      1 => (gradient_y + boost / 2).min(255).to_byte()
      2 => (255 - gradient_x).to_byte()
      _ => (255).to_byte()
    }
  })
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let mip_chain = @asset.asset_create_dynamic_texture_mip_chain_rgba8(
    BASE_WIDTH,
    BASE_HEIGHT,
    build_base_pixels(BASE_WIDTH, BASE_HEIGHT),
    false,
  )
  let mut y = 220.0F
  for i in 0..<mip_chain.length() {
    let texture = mip_chain[i]
    let width = @asset.asset_texture_width(texture)
    let height = @asset.asset_texture_height(texture)
    let width_f = Float::from_double(width.to_double())
    let height_f = Float::from_double(height.to_double())
    ignore(
      commands.spawn(
        (
          @sprite.Sprite::from_image(texture).with_custom_size(
            Some(@math.Vec2::new(width_f, height_f)),
          ),
          @transform.Transform::from_xyz(-280.0F + width_f / 2.0F, y, 0.0F),
        ),
      ),
    )
    y -= height_f * 0.6F + 12.0F
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .run()
}
