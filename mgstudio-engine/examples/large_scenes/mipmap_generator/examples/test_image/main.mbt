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
const IMAGE_SIZE : Int = 192

///|
fn build_pixels(width : Int, height : Int) -> Bytes {
  Bytes::makei(width * height * 4, fn(i) {
    let pixel = i / 4
    let x = pixel % width
    let y = pixel / width
    let ring = (x - width / 2) * (x - width / 2) +
      (y - height / 2) * (y - height / 2)
    let value = if ring % 4096 < 2048 { 220 } else { 40 }
    match i % 4 {
      0 => value.to_byte()
      1 => (255 - value).to_byte()
      2 => (x * 255 / width).to_byte()
      _ => (255).to_byte()
    }
  })
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let texture = @asset.asset_create_dynamic_texture(
    @math.UVec2::new(IMAGE_SIZE, IMAGE_SIZE),
    false,
  )
  @asset.asset_update_texture_region_rgba8(
    texture,
    @math.URect::new(
      @math.UVec2::new(0, 0),
      @math.UVec2::new(IMAGE_SIZE, IMAGE_SIZE),
    ),
    build_pixels(IMAGE_SIZE, IMAGE_SIZE),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(texture).with_custom_size(
          Some(@math.Vec2::new(420.0F, 420.0F)),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .run()
}
