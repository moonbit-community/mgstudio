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
const RECTANGLE_OFFSET : Float = 250.0F

///|
const RECTANGLE_SIDE : Float = 200.0F

///|
const LABEL_OFFSET : Float = 125.0F

///|
fn spawn_panel(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
  x : Float,
  texture : @asset.Handle[@asset.Image],
  uv_scale : @math.Vec2,
  label : String,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let panel = commands.spawn(
    (
      @sprite.Mesh2d::new(
        meshes.get_ref().val.add(
          @sprite.mesh2d_geometry_rectangle(
            @sprite.Rectangle::new(RECTANGLE_SIDE, RECTANGLE_SIDE),
          ).to_mesh(),
        ),
      ),
      @sprite.MeshMaterial2d::new(
        materials.get_ref().val.add(
          @sprite.ColorMaterialAsset::from_image(texture).with_uv_scale(
            uv_scale,
          ),
        ),
      ),
      @transform.Transform::from_xyz(x, 0.0F, 0.0F),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(panel),
        @text.Text2d::new(label),
        @text.TextFont::default().with_font(font),
        @text.TextBounds::new_horizontal(RECTANGLE_SIDE),
        @text.TextLayout::new_with_justify(@text.Justify::Center),
        @transform.Transform::from_xyz(0.0F, LABEL_OFFSET, 0.0F),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  let image_with_default_sampler = asset_server
    .get()
    .load_with_settings("textures/fantasy_ui_borders/panel-border-010.png", fn(
      _settings,
    ) {

    })
  let image_with_repeated_sampler = asset_server
    .get()
    .load_with_settings(
      "textures/fantasy_ui_borders/panel-border-010-repeated.png",
      fn(settings) {
        settings.sampler = @asset.ImageSampler::Descriptor(
          @asset.ImageSamplerDescriptor::linear().set_address_mode(
            @asset.ImageAddressMode::Repeat,
          ),
        )
      },
    )
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  spawn_panel(
    commands,
    meshes,
    materials,
    0.0F,
    image_with_default_sampler,
    @math.Vec2::new(1.0F, 1.0F),
    "Control",
    font,
  )
  spawn_panel(
    commands,
    meshes,
    materials,
    -RECTANGLE_OFFSET,
    image_with_repeated_sampler,
    @math.Vec2::new(2.0F, 3.0F),
    "Repeat On",
    font,
  )
  spawn_panel(
    commands,
    meshes,
    materials,
    RECTANGLE_OFFSET,
    image_with_default_sampler,
    @math.Vec2::new(2.0F, 3.0F),
    "Repeat Off",
    font,
  )

  ignore(
    commands.spawn(
      (
        @sprite.Camera2d::default(),
        @transform.Transform::identity().looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .run()
}
