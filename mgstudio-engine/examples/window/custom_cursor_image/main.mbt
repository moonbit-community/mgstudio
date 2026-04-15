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
// Bevy source: `bevy/examples/window/custom_cursor_image.rs`.

///|
pub struct AnimationConfig {
  first_sprite_index : Int
  last_sprite_index : Int
  increment : Int
  fps : Int
  mut frame_timer : @time.Timer
}

///|
let animation_config_component_key : @ecs.ComponentKey[AnimationConfig] = @ecs.register_component(
  debug_name="examples.window.custom_cursor_image.AnimationConfig",
)

///|
pub impl @ecs.Component for AnimationConfig with component() {
  animation_config_component_key
}

///|
pub struct CursorImageExampleState {
  mut cached_texture_atlas : @asset.TextureAtlas?
  mut rect_index : Int
}

///|
let cursor_image_example_state_resource_key : @ecs.ResourceKey[
  CursorImageExampleState,
] = @ecs.register_resource(
  debug_name="examples.window.custom_cursor_image.CursorImageExampleState",
)

///|
pub impl @app.Resource for CursorImageExampleState with resource() {
  cursor_image_example_state_resource_key
}

///|
fn animation_config_new(
  first : Int,
  last : Int,
  increment : Int,
  fps : Int,
) -> AnimationConfig {
  AnimationConfig::{
    first_sprite_index: first,
    last_sprite_index: last,
    increment,
    fps,
    frame_timer: @time.Timer::from_seconds(
      1.0F / Float::from_int(fps),
      @time.TimerMode::Once,
    ),
  }
}

///|
fn cursor_image_with(
  image : @window.CustomCursorImage,
  texture_atlas? : @asset.TextureAtlas? = image.texture_atlas,
  flip_x? : Bool = image.flip_x,
  flip_y? : Bool = image.flip_y,
  rect? : @math.URect? = image.rect,
) -> @window.CustomCursorImage {
  @window.CustomCursorImage::new(
    image.handle,
    image.hotspot,
    texture_atlas~,
    flip_x~,
    flip_y~,
    rect~,
  )
}

///|
fn setup_cursor_image_state(commands : @app.Commands) -> Unit {
  commands.insert_resource(CursorImageExampleState::{
    cached_texture_atlas: None,
    rect_index: 0,
  })
}

///|
fn setup_cursor_icon(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  texture_atlas_layouts : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
  window_entity : @app.Single[@core.Entity, @ecs.With[@window.Window]],
) -> Unit {
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::splat(64),
    20,
    10,
    padding=@math.UVec2::splat(5),
  )
  let texture_atlas_layout = texture_atlas_layouts.get_ref().val.add(layout)
  let animation_config = animation_config_new(0, 199, 1, 4)
  let atlas = @asset.TextureAtlas::new(
    texture_atlas_layout,
    animation_config.first_sprite_index,
  )
  let custom_cursor_image = @window.CustomCursorImage::new(
    asset_server
    .get()
    .load_image(
      "cursors/kenney_crosshairPack/Tilesheet/crosshairs_tilesheet_white.png",
    ),
    (0, 0),
    texture_atlas=Some(atlas),
  )
  commands
  .entity(window_entity.get())
  .insert_component(
    @window.CursorIcon::from_custom(
      @window.CustomCursor::Image(custom_cursor_image),
    ),
  )
  commands.entity(window_entity.get()).insert_component(animation_config)
}

///|
fn execute_animation(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Mut[AnimationConfig], @ecs.Mut[@window.CursorIcon]),
    @ecs.With[@window.Window],
  ],
) -> Unit {
  try! query.for_each(fn(_entity, data) {
    let (config, cursor_icon) = data
    let config_ref = config.get_ref()
    config_ref.val.frame_timer = config_ref.val.frame_timer.tick(
      time.get().delta(),
    )
    guard config_ref.val.frame_timer.just_finished() else { return }
    let next_cursor_icon = match cursor_icon.get_ref().val {
      @window.CursorIcon::Custom(@window.CustomCursor::Image(image)) =>
        match image.texture_atlas {
          Some(atlas) => {
            let next_index = if atlas.index + config_ref.val.increment >
              config_ref.val.last_sprite_index {
              config_ref.val.first_sprite_index
            } else {
              atlas.index + config_ref.val.increment
            }
            let next_image = cursor_image_with(
              image,
              texture_atlas=Some(atlas.with_index(next_index)),
            )
            @window.CursorIcon::from_custom(
              @window.CustomCursor::Image(next_image),
            )
          }
          None => cursor_icon.get_ref().val
        }
      _ => cursor_icon.get_ref().val
    }
    cursor_icon.get_ref().val = next_cursor_icon
    config_ref.val.frame_timer = @time.Timer::from_seconds(
      1.0F / Float::from_int(config_ref.val.fps),
      @time.TimerMode::Once,
    )
  })
}

///|
fn toggle_texture_atlas(
  keyboard : @input.ButtonInput[@window.KeyCode],
  state : @app.ResMut[CursorImageExampleState],
  query : @ecs.Query[@ecs.Mut[@window.CursorIcon], @ecs.With[@window.Window]],
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::KeyT) {
    return
  }
  let state_ref = state.get_ref()
  try! query.for_each(fn(_entity, cursor_icon) {
    let next_cursor_icon = match cursor_icon.get_ref().val {
      @window.CursorIcon::Custom(@window.CustomCursor::Image(image)) =>
        match image.texture_atlas {
          Some(atlas) => {
            state_ref.val.cached_texture_atlas = Some(atlas)
            let next_image = cursor_image_with(image, texture_atlas=None)
            @window.CursorIcon::from_custom(
              @window.CustomCursor::Image(next_image),
            )
          }
          None =>
            match state_ref.val.cached_texture_atlas {
              Some(cached) => {
                let next_image = cursor_image_with(
                  image,
                  texture_atlas=Some(cached),
                )
                @window.CursorIcon::from_custom(
                  @window.CustomCursor::Image(next_image),
                )
              }
              None => cursor_icon.get_ref().val
            }
        }
      _ => cursor_icon.get_ref().val
    }
    cursor_icon.get_ref().val = next_cursor_icon
  })
}

///|
fn toggle_flip_x(
  keyboard : @input.ButtonInput[@window.KeyCode],
  query : @ecs.Query[@ecs.Mut[@window.CursorIcon], @ecs.With[@window.Window]],
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::KeyX) {
    return
  }
  try! query.for_each(fn(_entity, cursor_icon) {
    let next_cursor_icon = match cursor_icon.get_ref().val {
      @window.CursorIcon::Custom(@window.CustomCursor::Image(image)) => {
        let next_image = cursor_image_with(image, flip_x=!image.flip_x)
        @window.CursorIcon::from_custom(@window.CustomCursor::Image(next_image))
      }
      _ => cursor_icon.get_ref().val
    }
    cursor_icon.get_ref().val = next_cursor_icon
  })
}

///|
fn toggle_flip_y(
  keyboard : @input.ButtonInput[@window.KeyCode],
  query : @ecs.Query[@ecs.Mut[@window.CursorIcon], @ecs.With[@window.Window]],
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::KeyY) {
    return
  }
  try! query.for_each(fn(_entity, cursor_icon) {
    let next_cursor_icon = match cursor_icon.get_ref().val {
      @window.CursorIcon::Custom(@window.CustomCursor::Image(image)) => {
        let next_image = cursor_image_with(image, flip_y=!image.flip_y)
        @window.CursorIcon::from_custom(@window.CustomCursor::Image(next_image))
      }
      _ => cursor_icon.get_ref().val
    }
    cursor_icon.get_ref().val = next_cursor_icon
  })
}

///|
fn rect_from_index(index : Int) -> @math.URect? {
  let rect_size = 32
  match index {
    0 =>
      Some(@math.URect::new(@math.UVec2::zero(), @math.UVec2::splat(rect_size)))
    1 =>
      Some(
        @math.URect::new(
          @math.UVec2::new(rect_size, 0),
          @math.UVec2::new(rect_size * 2, rect_size),
        ),
      )
    2 =>
      Some(
        @math.URect::new(
          @math.UVec2::new(0, rect_size),
          @math.UVec2::new(rect_size, rect_size * 2),
        ),
      )
    3 =>
      Some(
        @math.URect::new(
          @math.UVec2::new(rect_size, rect_size),
          @math.UVec2::splat(rect_size * 2),
        ),
      )
    _ => None
  }
}

///|
fn cycle_rect(
  keyboard : @input.ButtonInput[@window.KeyCode],
  state : @app.ResMut[CursorImageExampleState],
  query : @ecs.Query[@ecs.Mut[@window.CursorIcon], @ecs.With[@window.Window]],
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::KeyC) {
    return
  }
  let state_ref = state.get_ref()
  state_ref.val.rect_index = (state_ref.val.rect_index + 1) % 5
  let next_rect = rect_from_index(state_ref.val.rect_index)
  try! query.for_each(fn(_entity, cursor_icon) {
    let next_cursor_icon = match cursor_icon.get_ref().val {
      @window.CursorIcon::Custom(@window.CustomCursor::Image(image)) => {
        let next_image = cursor_image_with(image, rect=next_rect)
        @window.CursorIcon::from_custom(@window.CustomCursor::Image(next_image))
      }
      _ => cursor_icon.get_ref().val
    }
    cursor_icon.get_ref().val = next_cursor_icon
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(
    @app.Startup,
    @app.system(@app.system_param(setup_cursor_image_state)),
  )
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup_cursor_icon)))
  .add_systems(@app.Update, @app.system(@app.system_param2(execute_animation)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(toggle_texture_atlas)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param2(toggle_flip_x)))
  .add_systems(@app.Update, @app.system(@app.system_param2(toggle_flip_y)))
  .add_systems(@app.Update, @app.system(@app.system_param3(cycle_rect)))
  .run()
}
