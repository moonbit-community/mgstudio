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
pub fn sprite_animation_run() -> Unit {
  let plugins : Array[@app.Plugin] = [
    @window.window_plugin, @time.time_plugin, @asset.asset_plugin, @render2d.render2d_plugin,
    @input.input_plugin,
  ]
  @app.App::new()
  .add_plugins(plugins)
  .add_startup_system(sprite_animation_setup)
  .add_system(sprite_animation_update)
  .run()
}

///|
priv struct SpriteAnimationState {
  mut sprite : @render2d.SpriteHandle?
  mut layout : @asset.Handle[@asset.TextureAtlasLayout]?
  mut timer : Float
  mut index : Int
}

///|
let animation_state : Ref[SpriteAnimationState] = Ref::new(SpriteAnimationState::{
  sprite: None,
  layout: None,
  timer: 0.0F,
  index: 0,
})

///|
fn sprite_animation_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::new(128, 128),
    2,
    2,
  )
  let layout_handle = @asset.asset_add_texture_atlas_layout(layout)
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let transform = @math.Transform::identity()
  let handle = @render2d.SpriteBundle::new(sprite, transform, texture).spawn()
  @render2d.render2d_set_sprite_atlas_handle(handle, layout_handle, 0) |> ignore
  let camera = @render2d.Camera2d::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
  animation_state.val.sprite = Some(handle)
  animation_state.val.layout = Some(layout_handle)
  animation_state.val.timer = 0.0F
  animation_state.val.index = 0
}

///|
fn sprite_animation_update() -> Unit {
  let sprite_opt = animation_state.val.sprite
  let layout_opt = animation_state.val.layout
  if sprite_opt is Some(sprite_handle) && layout_opt is Some(layout_handle) {
    animation_state.val.timer = animation_state.val.timer +
      @time.time_delta_seconds()
    if animation_state.val.timer >= 0.2F {
      animation_state.val.timer = 0.0F
      animation_state.val.index = (animation_state.val.index + 1) % 4
      @render2d.render2d_set_sprite_atlas_handle(
        sprite_handle,
        layout_handle,
        animation_state.val.index,
      )
      |> ignore
    }
  }
}
