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
/// Load a cubemap texture onto a cube like a skybox and cycle through different
/// compressed texture formats.
///
/// Bevy source: `bevy/examples/3d/skybox.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const CUBEMAP_SWAP_DELAY : Float = 3.0F

///|
priv struct CubemapAsset {
  path : String
  required_format : Int
}

///|
fn CubemapAsset::new(path : String, required_format : Int) -> CubemapAsset {
  CubemapAsset::{ path, required_format }
}

///|
let cubemaps : Array[CubemapAsset] = [
  CubemapAsset::new(
    "textures/Ryfjallet_cubemap.png",
    @asset.COMPRESSED_IMAGE_FORMAT_NONE,
  ),
  CubemapAsset::new(
    "textures/Ryfjallet_cubemap_astc4x4.ktx2",
    @asset.COMPRESSED_IMAGE_FORMAT_ASTC_LDR,
  ),
  CubemapAsset::new(
    "textures/Ryfjallet_cubemap_bc7.ktx2",
    @asset.COMPRESSED_IMAGE_FORMAT_BC,
  ),
  CubemapAsset::new(
    "textures/Ryfjallet_cubemap_etc2.ktx2",
    @asset.COMPRESSED_IMAGE_FORMAT_ETC2,
  ),
]

///|
priv struct Cubemap {
  mut is_loaded : Bool
  mut index : Int
  mut image_handle : @asset.Handle[@asset.Image]
}

///|
fn Cubemap::new(
  is_loaded~ : Bool,
  index~ : Int,
  image_handle~ : @asset.Handle[@asset.Image],
) -> Cubemap {
  Cubemap::{ is_loaded, index, image_handle }
}

///|
let cubemap_resource_key : @ecs.ResourceKey[Cubemap] = @ecs.register_resource(
  debug_name="examples.skybox.Cubemap",
)

///|
impl @app.Resource for Cubemap with fn resource() {
  cubemap_resource_key
}

///|
fn cubemap_asset(index : Int) -> CubemapAsset {
  if index >= 0 && index < cubemaps.length() {
    cubemaps[index]
  } else {
    cubemaps[0]
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@color.Color::white(), 32_000.0F, true),
        @transform.Transform::from_xyz(0.0F, 2.0F, 0.0F).with_rotation(
          @math.Quat::from_rotation_x(-PI / 4.0F),
        ),
      ),
    ),
  )

  let skybox_handle = asset_server.get().load_image(cubemaps[0].path)
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @pbr.Msaa::Off,
        @post_process.TemporalAntiAliasing::TemporalAntiAliasing(),
        @post_process.ScreenSpaceAmbientOcclusion::ScreenSpaceAmbientOcclusion(),
        @transform.Transform::from_xyz(0.0F, 0.0F, 8.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.FreeCamera::FreeCamera(),
        @pbr.Skybox::new(skybox_handle, 1000.0F),
      ),
    ),
  )

  commands.insert_resource(
    @pbr.GlobalAmbientLight::new(
      @color.Color::new(210.0F / 255.0F, 220.0F / 255.0F, 240.0F / 255.0F, 1.0F),
      1.0F,
    ),
  )

  commands.insert_resource(
    Cubemap::new(is_loaded=false, index=0, image_handle=skybox_handle),
  )
}

///|
fn cycle_cubemap_asset(
  time : @app.Res[@time.Time[Unit]],
  next_swap : @app.Local[Float],
  cubemap : @app.ResMut[Cubemap],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let now = time.get().elapsed_seconds()
  if next_swap.get() == 0.0F {
    next_swap.set(now + CUBEMAP_SWAP_DELAY)
    return
  } else if now < next_swap.get() {
    return
  }
  next_swap.set(next_swap.get() + CUBEMAP_SWAP_DELAY)

  let supported_compressed_formats = @asset.asset_supported_compressed_image_formats()
  let mut new_index = cubemap.peek().index
  for _ in 0..<cubemaps.length() {
    new_index = (new_index + 1) % cubemaps.length()
    if @asset.asset_compressed_image_formats_contains(
        supported_compressed_formats,
        cubemap_asset(new_index).required_format,
      ) {
      break
    }
    println(
      "Skipping format which is not supported by current hardware: \{cubemap_asset(new_index).path}",
    )
  }

  if new_index == cubemap.peek().index {
    return
  }

  cubemap.modify(fn(state) {
    state.index = new_index
    state.image_handle = asset_server
      .get()
      .load_image(cubemap_asset(new_index).path)
    state.is_loaded = false
  })
}

///|
fn asset_loaded(
  asset_server : @app.Res[@asset.AssetServer],
  images : @app.ResMut[@asset.Assets[@asset.Image]],
  cubemap : @app.ResMut[Cubemap],
  skyboxes : @ecs.Query[@ecs.Write[@pbr.Skybox], @ecs.All],
) -> Unit {
  let cubemap_value = cubemap.peek()
  if cubemap_value.is_loaded {
    return
  }
  if !(asset_server.get().load_state(cubemap_value.image_handle)
    is @asset.LoadState::Loaded) {
    return
  }

  let image_ready = images.modify(fn(store) {
    match store.get_mut(cubemap_value.image_handle) {
      Some(image) => {
        if image.array_layout() is None {
          let layers = image.height() / image.width()
          if image.reinterpret_stacked_2d_as_array(layers) {
            image.set_texture_view_dimension(
              Some(@asset.ImageTextureViewDimension::Cube),
            )
          } else {
            abort(
              "skybox image must be a stacked 2D texture with evenly divisible layers",
            )
          }
        }
        true
      }
      None => false
    }
  })
  if !image_ready {
    return
  }

  println("Swapping to \{cubemap_asset(cubemap_value.index).path}")
  try! skyboxes.view(fn(_entity, skybox) {
    skybox.set(skybox.peek().with_image(Some(cubemap_value.image_handle)))
  })
  cubemap.modify(fn(state) { state.is_loaded = true })
}

///|
fn animate_light_direction(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@pbr.DirectionalLight],
  ],
) -> Unit {
  let delta = time.get().delta_secs() * 0.5F
  try! query.view(fn(_entity, transform) {
    transform.set(
      transform
      .peek()
      .with_rotation(
        transform.peek().rotation
        .mul(@math.Quat::from_rotation_y(delta))
        .normalize(),
      ),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@pbr.FreeCameraPlugin::FreeCameraPlugin())
  .add_systems_param2(@app.Startup, setup)
  .add_systems_param4(@app.Update, cycle_cubemap_asset)
  .add_systems_param4(@app.Update, asset_loaded)
  .add_systems_param2(@app.Update, animate_light_direction)
  .run()
}
