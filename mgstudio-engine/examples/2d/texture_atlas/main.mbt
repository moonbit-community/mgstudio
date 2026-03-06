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
priv struct TextureAtlasExampleState {
  mut folder_handle : @asset.Handle[@asset.LoadedFolder]?
  mut vendor_handle : @asset.Handle[@asset.Image]?
  mut built : Bool
}

///|
priv struct BuiltAtlas {
  layout_handle : @asset.Handle[@asset.TextureAtlasLayout]
  sources : @asset.TextureAtlasSources
  texture : @asset.Handle[@asset.Image]
}

///|
let texture_atlas_state : Ref[TextureAtlasExampleState] = Ref::new(TextureAtlasExampleState::{
  folder_handle: None,
  vendor_handle: None,
  built: false,
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(texture_atlas_setup)
  .add_system(texture_atlas_update)
  .run()
}

///|
fn texture_atlas_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  texture_atlas_state.val.folder_handle = Some(
    asset_server.load_folder("textures/rpg"),
  )
  texture_atlas_state.val.vendor_handle = Some(
    asset_server.load("textures/rpg/chars/vendor/generic-rpg-vendor.png"),
  )
  texture_atlas_state.val.built = false

  world |> ignore
}

///|
fn texture_atlas_update(world : @ecs.World) -> Unit {
  if texture_atlas_state.val.built {
    return
  }
  guard texture_atlas_state.val.folder_handle is Some(folder_handle) else {
    return
  }
  guard texture_atlas_state.val.vendor_handle is Some(vendor_handle) else {
    return
  }
  if !@asset.asset_is_texture_loaded(vendor_handle) {
    return
  }
  guard @asset.asset_get_loaded_folder(folder_handle) is Some(folder) else {
    return
  }
  if folder.handles.length() == 0 {
    return
  }
  for handle in folder.handles {
    if !@asset.asset_is_texture_loaded(handle) {
      return
    }
  }

  let linear_atlas = build_texture_atlas(folder, None, false)
  let nearest_atlas = build_texture_atlas(folder, None, true)
  let linear_padded_atlas = build_texture_atlas(
    folder,
    Some(@math.UVec2::new(6, 6)),
    false,
  )
  let nearest_padded_atlas = build_texture_atlas(
    folder,
    Some(@math.UVec2::new(6, 6)),
    true,
  )
  if linear_atlas is None ||
    nearest_atlas is None ||
    linear_padded_atlas is None ||
    nearest_padded_atlas is None {
    return
  }
  let linear = if linear_atlas is Some(value) { value } else { return }
  let nearest = if nearest_atlas is Some(value) { value } else { return }
  let linear_padded = if linear_padded_atlas is Some(value) {
    value
  } else {
    return
  }
  let nearest_padded = if nearest_padded_atlas is Some(value) {
    value
  } else {
    return
  }

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  spawn_texture_preview(world, linear.texture, -250.0F, -160.0F, 0.5F)
  spawn_texture_preview(world, linear_padded.texture, 250.0F, -160.0F, 0.5F)

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let title_font = @text.TextFont::default()
    .with_font(font)
    .with_font_size(42.0F)
  let sampling_font = @text.TextFont::default()
    .with_font(font)
    .with_font_size(25.0F)

  spawn_label("No padding", title_font, -250.0F, 250.0F)
  spawn_label("Padding", title_font, 250.0F, 250.0F)

  spawn_sampling_variant(
    world,
    linear,
    vendor_handle,
    -350.0F,
    "Linear",
    sampling_font,
  )
  spawn_sampling_variant(
    world,
    nearest,
    vendor_handle,
    -150.0F,
    "Nearest",
    sampling_font,
  )
  spawn_sampling_variant(
    world, linear_padded, vendor_handle, 150.0F, "Linear", sampling_font,
  )
  spawn_sampling_variant(
    world, nearest_padded, vendor_handle, 350.0F, "Nearest", sampling_font,
  )

  texture_atlas_state.val.built = true
}

///|
fn build_texture_atlas(
  folder : @asset.LoadedFolder,
  padding : @math.UVec2?,
  sampler_nearest : Bool,
) -> BuiltAtlas? {
  let mut builder = @asset.TextureAtlasBuilder::default()
    .initial_size(@math.UVec2::splat(512))
    .max_size(@math.UVec2::splat(4096))
    .sampler_nearest(sampler_nearest)
  if padding is Some(value) {
    builder = builder.padding(value)
  }
  for handle in folder.handles {
    builder = builder.add_texture(handle)
  }
  let result = builder.try_build()
  if result is Some(value) {
    let layout = value.0
    let sources = value.1
    let texture = value.2
    Some(BuiltAtlas::{
      layout_handle: @asset.asset_add_texture_atlas_layout(layout),
      sources,
      texture,
    })
  } else {
    None
  }
}

///|
fn spawn_texture_preview(
  world : @ecs.World,
  texture : @asset.Handle[@asset.Image],
  x : Float,
  y : Float,
  scale : Float,
) -> Unit {
  @render2d.SpriteBundle::new(
    @render2d.Sprite::from_image(texture),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(x, y),
      0.0F,
      @math.Vec2::new(scale, scale),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_sampling_variant(
  world : @ecs.World,
  atlas : BuiltAtlas,
  vendor_handle : @asset.Handle[@asset.Image],
  x : Float,
  sampling_label : String,
  font : @text.TextFont,
) -> Unit {
  if atlas.sources.handle(atlas.layout_handle, vendor_handle)
    is Some(vendor_sprite) {
    @render2d.SpriteBundle::new(
      @render2d.Sprite::from_atlas_image(atlas.texture, vendor_sprite),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(x, 80.0F),
        0.0F,
        @math.Vec2::new(3.0F, 3.0F),
      ),
    ).spawn(world)
    |> ignore
  }
  spawn_label(sampling_label, font, x, 190.0F)
}

///|
fn spawn_label(
  content : String,
  font : @text.TextFont,
  x : Float,
  y : Float,
) -> Unit {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    font,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(x, y),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .spawn()
  |> ignore
}
