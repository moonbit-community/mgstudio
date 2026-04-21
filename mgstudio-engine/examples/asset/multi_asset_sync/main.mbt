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
struct PendingTextures {
  icon : @asset.Handle[@asset.Image]
  bird : @asset.Handle[@asset.Image]
  spawned : Bool
}

///|
let pending_textures_key : @ecs.ResourceKey[PendingTextures] = @ecs.register_resource(
  debug_name="examples.asset.multi_asset_sync.PendingTextures",
)

///|
impl @app.Resource for PendingTextures with resource() {
  pending_textures_key
}

///|
struct LoadedSprite {
  phase : Float
}

///|
let loaded_sprite_key : @ecs.ComponentKey[LoadedSprite] = @ecs.register_component(
  debug_name="examples.asset.multi_asset_sync.LoadedSprite",
)

///|
pub impl @ecs.Component for LoadedSprite with component() {
  loaded_sprite_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let server = asset_server.get()
  commands.insert_resource(PendingTextures::{
    icon: server.load("branding/icon.png"),
    bird: server.load("branding/bevy_bird_dark.png"),
    spawned: false,
  })
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
}

///|
fn spawn_when_loaded(
  commands : @app.Commands,
  pending : @app.ResMut[PendingTextures],
) -> Unit {
  let pending_state = pending.get()
  if pending_state.spawned {
    return
  }
  let icon_loaded = @asset.asset_is_texture_loaded(pending_state.icon)
  let bird_loaded = @asset.asset_is_texture_loaded(pending_state.bird)
  if !(icon_loaded && bird_loaded) {
    return
  }
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(pending_state.icon).with_custom_size(
          Some(@math.Vec2::new(240.0F, 240.0F)),
        ),
        @transform.Transform::from_xyz(-220.0F, 0.0F, 0.0F),
        LoadedSprite::{ phase: 0.0F },
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(pending_state.bird).with_custom_size(
          Some(@math.Vec2::new(240.0F, 240.0F)),
        ),
        @transform.Transform::from_xyz(220.0F, 0.0F, 0.0F),
        LoadedSprite::{ phase: 1.2F },
      ),
    ),
  )
  pending.set(PendingTextures::{ ..pending_state, spawned: true })
  @window.host_debug_string(
    value="[multi_asset_sync] all requested textures loaded and spawned",
  )
}

///|
fn animate_loaded_sprites(
  time : @app.Res[@time.Time[Unit]],
  sprites : @ecs.Query[
    (@ecs.Comp[LoadedSprite], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! sprites.for_each(fn(_entity, data) {
    let (loaded, transform) = data
    transform.modify(fn(value) {
      value.translation.y = @math.sin(t * 1.5F + loaded.value().phase) * 48.0F
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(spawn_when_loaded)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(animate_loaded_sprites)),
  )
  .run()
}
