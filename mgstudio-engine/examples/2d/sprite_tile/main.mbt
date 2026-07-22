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
struct AnimationState {
  min : Float
  max : Float
  current : Float
  speed : Float
}

///|
let animation_state_key : @ecs.ResourceKey[AnimationState] = @ecs.register_resource(
  debug_name="examples.2d.sprite_tile.AnimationState",
)

///|
pub impl @app.Resource for AnimationState with fn resource() {
  animation_state_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(Startup, setup)
  .add_systems_param3(Update, animate)
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))
  commands.insert_resource(AnimationState::{
    min: 128.0F,
    max: 512.0F,
    current: 128.0F,
    speed: 50.0F,
  })
  ignore(
    commands.spawn_component(
      @sprite.Sprite::from_image(asset_server.get().load("branding/icon.png")).with_image_mode(
        @sprite.SpriteImageMode::tiled(
          tile_x=true,
          tile_y=true,
          stretch_value=0.5F,
        ),
      ),
    ),
  )
}

///|
fn animate(
  sprites : @ecs.Query[@ecs.Write[@sprite.Sprite], @ecs.All],
  state : @app.ResMut[AnimationState],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let mut animation_state = state.get()
  if animation_state.current >= animation_state.max ||
    animation_state.current <= animation_state.min {
    animation_state = { ..animation_state, speed: -animation_state.speed }
  }
  animation_state = {
    ..animation_state,
    current: animation_state.current +
    animation_state.speed * time.get().delta_secs(),
  }
  state.set(animation_state)
  let current = animation_state.current
  try! sprites.for_each(fn(_entity, sprite) {
    sprite.modify(fn(value) {
      value.custom_size = Some(@math.Vec2::new(current, current))
    })
  })
}
