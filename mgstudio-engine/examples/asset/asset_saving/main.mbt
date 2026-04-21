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
const TEXTURE_SIZE : Int = 96

///|
const OUTPUT_PATH : String = "/tmp/mgstudio_asset_saving_checker.png"

///|
fn checker_pixels(width : Int, height : Int) -> Bytes {
  Bytes::makei(width * height * 4, fn(i) {
    let pixel = i / 4
    let x = pixel % width
    let y = pixel / width
    let checker = (x / 8 + y / 8) % 2 == 0
    let r = if checker { 235 } else { 48 }
    let g = if checker { 116 } else { 206 }
    let b = if checker { 56 } else { 238 }
    match i % 4 {
      0 => r.to_byte()
      1 => g.to_byte()
      2 => b.to_byte()
      _ => (255).to_byte()
    }
  })
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let texture = @asset.asset_create_dynamic_texture(
    @math.UVec2::new(TEXTURE_SIZE, TEXTURE_SIZE),
    false,
  )
  @asset.asset_update_texture_region_rgba8(
    texture,
    @math.URect::new(
      @math.UVec2::new(0, 0),
      @math.UVec2::new(TEXTURE_SIZE, TEXTURE_SIZE),
    ),
    checker_pixels(TEXTURE_SIZE, TEXTURE_SIZE),
  )
  @asset.asset_save_texture_png(texture, OUTPUT_PATH)
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(texture).with_custom_size(
          Some(@math.Vec2::new(360.0F, 360.0F)),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )
  @window.host_debug_string(
    value="[asset_saving] wrote texture to \{OUTPUT_PATH}",
  )
}

///|
fn rotate_saved_texture(
  time : @app.Res[@time.Time[Unit]],
  sprites : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Sprite],
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! sprites.for_each(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.rotation = @math.Quat::from_rotation_z(t * 0.35F)
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(rotate_saved_texture)),
  )
  .run()
}
