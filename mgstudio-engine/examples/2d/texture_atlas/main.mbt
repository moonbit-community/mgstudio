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
pub(all) enum AppState {
  Setup
  Finished
} derive(Eq, Debug)

///|
impl Default for AppState with default() {
  AppState::Setup
}

///|
impl @app.States for AppState with debug_name(self) {
  ignore(self)
  "examples.2d.texture_atlas.AppState"
}

///|
struct RpgSpriteFolder {
  handle : @asset.Handle[@asset.LoadedFolder]
}

///|
let rpg_sprite_folder_key : @ecs.ResourceKey[RpgSpriteFolder] = @ecs.register_resource(
  debug_name="examples.2d.texture_atlas.RpgSpriteFolder",
)

///|
pub impl @app.Resource for RpgSpriteFolder with resource() {
  rpg_sprite_folder_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@asset.AssetPlugin::default_nearest()),
  )
  .insert_state(AppState::default())
  .add_on_enter_system_config(
    AppState::Setup,
    @app.system(@app.system_param2(load_textures)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(check_textures)).run_if(
      @app.in_state(AppState::Setup),
    ),
  )
  .add_on_enter_system_config(
    AppState::Finished,
    @app.system(@app.system_param5(setup)),
  )
  .run()
}

///|
fn load_textures(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.insert_resource(RpgSpriteFolder::{
    handle: asset_server.get().load_folder("textures/rpg"),
  })
}

///|
fn check_textures(
  rpg_sprite_folder : @app.Res[RpgSpriteFolder],
  events : @ecs.MessageReader[@asset.AssetEvent[@asset.LoadedFolder]],
) -> Unit {
  for event in (try! events.read()) {
    match event {
      LoadedWithDependencies(handle) =>
        if handle.id() == rpg_sprite_folder.get().handle.id() {
          @app.set_state(AppState::Finished)
        }
      _ => ()
    }
  }
}

///|
fn setup(
  commands : @app.Commands,
  rpg_sprite_handles : @app.Res[RpgSpriteFolder],
  asset_server : @app.Res[@asset.AssetServer],
  texture_atlases : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
  loaded_folders : @app.Res[@asset.Assets[@asset.LoadedFolder]],
) -> Unit {
  guard loaded_folders.get().get(rpg_sprite_handles.get().handle)
    is Some(loaded_folder) else {
    return
  }

  let (atlas_linear_handle, linear_sources, linear_texture) = create_texture_atlas(
    loaded_folder,
    None,
    false,
    texture_atlases,
  )
  let (atlas_nearest_handle, nearest_sources, nearest_texture) = create_texture_atlas(
    loaded_folder,
    None,
    true,
    texture_atlases,
  )
  let (atlas_linear_padded_handle, linear_padded_sources, linear_padded_texture) = create_texture_atlas(
    loaded_folder,
    Some(@math.UVec2::new(6, 6)),
    false,
    texture_atlases,
  )
  let (
    atlas_nearest_padded_handle,
    nearest_padded_sources,
    nearest_padded_texture,
  ) = create_texture_atlas(
    loaded_folder,
    Some(@math.UVec2::new(6, 6)),
    true,
    texture_atlases,
  )

  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(linear_texture),
        @transform.Transform::from_xyz(-250.0F, -160.0F, 0.0F).with_scale(
          @math.Vec3::splat(0.5F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(linear_padded_texture),
        @transform.Transform::from_xyz(250.0F, -160.0F, 0.0F).with_scale(
          @math.Vec3::splat(0.5F),
        ),
      ),
    ),
  )

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let text_style = @text.TextFont::default()
    .with_font(font)
    .with_font_size(42.0F)
  create_label((-250.0F, 250.0F, 0.0F), "No padding", text_style)
  create_label(
    (250.0F, 250.0F, 0.0F),
    "Padding",
    @text.TextFont::default().with_font(font).with_font_size(42.0F),
  )

  guard asset_server
    .get()
    .get_handle("textures/rpg/chars/vendor/generic-rpg-vendor.png")
    is Some(vendor_handle) else {
    return
  }

  let sampling_label_style = @text.TextFont::default()
    .with_font(font)
    .with_font_size(25.0F)
  let configurations : Array[
    (
      String,
      @asset.Handle[@asset.TextureAtlasLayout],
      @asset.TextureAtlasSources,
      @asset.Handle[@asset.Image],
      Float,
    ),
  ] = [
    ("Linear", atlas_linear_handle, linear_sources, linear_texture, -350.0F),
    ("Nearest", atlas_nearest_handle, nearest_sources, nearest_texture, -150.0F),
    (
      "Linear", atlas_linear_padded_handle, linear_padded_sources, linear_padded_texture,
      150.0F,
    ),
    (
      "Nearest", atlas_nearest_padded_handle, nearest_padded_sources, nearest_padded_texture,
      350.0F,
    ),
  ]

  for configuration in configurations {
    let sampling = configuration.0
    let atlas_handle = configuration.1
    let atlas_sources = configuration.2
    let atlas_texture = configuration.3
    let x = configuration.4
    create_sprite_from_atlas(
      commands,
      (x, 80.0F, 0.0F),
      atlas_texture,
      atlas_sources,
      atlas_handle,
      vendor_handle,
    )
    create_label((x, 190.0F, 0.0F), sampling, sampling_label_style)
  }
}

///|
fn create_texture_atlas(
  folder : @asset.LoadedFolder,
  padding : @math.UVec2?,
  sampler_nearest : Bool,
  texture_atlases : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
) -> (
  @asset.Handle[@asset.TextureAtlasLayout],
  @asset.TextureAtlasSources,
  @asset.Handle[@asset.Image],
) {
  let mut texture_atlas_builder = @asset.TextureAtlasBuilder::default().sampler_nearest(
    sampler_nearest,
  )
  if padding is Some(padding_value) {
    texture_atlas_builder = texture_atlas_builder.padding(padding_value)
  }
  for handle in folder.handles {
    texture_atlas_builder = texture_atlas_builder.add_texture(handle)
  }
  let (texture_atlas_layout, texture_atlas_sources, texture) = texture_atlas_builder.build()
  (
    texture_atlases.peek().add(texture_atlas_layout),
    texture_atlas_sources,
    texture,
  )
}

///|
fn create_sprite_from_atlas(
  commands : @app.Commands,
  translation : (Float, Float, Float),
  atlas_texture : @asset.Handle[@asset.Image],
  atlas_sources : @asset.TextureAtlasSources,
  atlas_handle : @asset.Handle[@asset.TextureAtlasLayout],
  vendor_handle : @asset.Handle[@asset.Image],
) -> Unit {
  guard atlas_sources.handle(atlas_handle, vendor_handle) is Some(vendor_sprite) else {
    return
  }
  ignore(
    commands.spawn(
      (
        @transform.Transform::from_xyz(
          translation.0,
          translation.1,
          translation.2,
        ).with_scale(@math.Vec3::splat(3.0F)),
        @sprite.Sprite::from_atlas_image(atlas_texture, vendor_sprite),
      ),
    ),
  )
}

///|
fn create_label(
  translation : (Float, Float, Float),
  text : String,
  text_style : @text.TextFont,
) -> Unit {
  ignore(
    @text.Text2dBundle::new(
      @text.Text2d::new(text),
      text_style,
      @transform.Transform::from_xyz(
        translation.0,
        translation.1,
        translation.2,
      ),
    )
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
    .spawn(),
  )
}
