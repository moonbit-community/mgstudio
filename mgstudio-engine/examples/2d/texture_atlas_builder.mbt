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
pub fn texture_atlas_builder_run() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = [
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @window.window_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @time.time_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @asset.asset_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @render2d.render2d_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @input.input_plugin(app)
    },
  ]
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(fn(_world : @ecs_world.World) {
    texture_atlas_builder_setup()
  })
  .add_system(fn(_world : @ecs_world.World) { texture_atlas_builder_update() })
  .run()
}

///|
priv struct TextureAtlasBuilderState {
  mut built : Bool
  mut texture_a : @asset.Handle[@asset.Image]?
  mut texture_b : @asset.Handle[@asset.Image]?
}

///|
let builder_state : Ref[TextureAtlasBuilderState] = Ref::new(TextureAtlasBuilderState::{
  built: false,
  texture_a: None,
  texture_b: None,
})

///|
fn texture_atlas_builder_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture_a = asset_server.load("branding/bevy_bird_dark.png")
  let texture_b = asset_server.load("textures/simplespace/ship_C.png")
  builder_state.val.built = false
  builder_state.val.texture_a = Some(texture_a)
  builder_state.val.texture_b = Some(texture_b)
  let camera = @render2d.Camera2d::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
}

///|
fn texture_atlas_builder_update() -> Unit {
  if builder_state.val.built {
    return
  }
  let texture_a_opt = builder_state.val.texture_a
  let texture_b_opt = builder_state.val.texture_b
  if texture_a_opt is Some(texture_a) && texture_b_opt is Some(texture_b) {
    if !@asset.asset_is_texture_loaded(texture_a) ||
      !@asset.asset_is_texture_loaded(texture_b) {
      return
    }
    let builder = @asset.TextureAtlasBuilder::default()
      .initial_size(@math.UVec2::splat(256))
      .max_size(@math.UVec2::splat(1024))
      .add_texture(texture_a)
      .add_texture(texture_b)
    let result = builder.try_build()
    if result is None {
      return
    }
    let layout = if result is Some(value) { value.0 } else { return }
    let sources = if result is Some(value) { value.1 } else { return }
    let atlas_texture = if result is Some(value) { value.2 } else { return }
    let layout_handle = @asset.asset_add_texture_atlas_layout(layout)
    let index_a = sources.texture_index(texture_a).unwrap_or(-1)
    let index_b = sources.texture_index(texture_b).unwrap_or(-1)
    let sprite = @render2d.Sprite::new(@render2d.Color::white())
    let handle_a = @render2d.SpriteBundle::new(
      sprite,
      @math.Transform::new(
        @math.Vec2::new(-160.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
      ),
      atlas_texture,
    ).spawn()
    @render2d.render2d_set_sprite_atlas_handle(handle_a, layout_handle, index_a)
    |> ignore
    let handle_b = @render2d.SpriteBundle::new(
      sprite,
      @math.Transform::new(
        @math.Vec2::new(160.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
      ),
      atlas_texture,
    ).spawn()
    @render2d.render2d_set_sprite_atlas_handle(handle_b, layout_handle, index_b)
    |> ignore
    builder_state.val.built = true
  }
}
