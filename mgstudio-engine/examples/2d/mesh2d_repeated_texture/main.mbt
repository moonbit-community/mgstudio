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
priv struct ExampleState {
  mut label_font : @asset.Handle[@asset.Font]?
  mut labels_spawned : Bool
}

///|
let example_state : Ref[ExampleState] = Ref::new(ExampleState::{
  label_font: None,
  labels_spawned: false,
})

///|
fn spawn_panel(
  world : @ecs.World,
  x : Float,
  texture : @asset.Handle[@asset.Image],
  uv_scale : @math.Vec2,
) -> Unit {
  let mesh = @sprite.Mesh2d::from_rectangle(
    @sprite.Rectangle::new(RECTANGLE_SIDE, RECTANGLE_SIDE),
  )
  let material = @sprite.ColorMaterial::from_image(texture).with_uv_scale(
    uv_scale,
  )
  @sprite.Mesh2dBundle::new(
    mesh,
    material,
    @math.Transform::from_xyz(x, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_label(
  content : String,
  x : Float,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let style = @text.TextFont::default().with_font(font)
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    style,
    @math.Transform::from_xyz(x, LABEL_OFFSET, 0.0F),
  )
  .with_bounds(@text.TextBounds::new_horizontal(RECTANGLE_SIDE))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .spawn()
  |> ignore
}

///|
fn ensure_labels_system(_world : @ecs.World) -> Unit {
  if example_state.val.labels_spawned {
    return
  }
  guard example_state.val.label_font is Some(font) else { return }
  guard @asset.asset_font_read_bytes(font) is Some(_) else { return }

  spawn_label("Control", 0.0F, font)
  spawn_label("Repeat On", -RECTANGLE_OFFSET, font)
  spawn_label("Repeat Off", RECTANGLE_OFFSET, font)
  example_state.val.labels_spawned = true
}

///|
fn mesh2d_repeated_texture_setup(world : @ecs.World) -> Unit {
  // Port of `bevy/examples/2d/mesh2d_repeated_texture.rs`.
  let asset_server = @asset.AssetServer::new()
  let default_texture = asset_server.load_with_settings(
    "textures/fantasy_ui_borders/panel-border-010.png",
    fn(_settings) {  },
  )
  let repeated_texture = asset_server.load_with_settings(
    "textures/fantasy_ui_borders/panel-border-010-repeated.png",
    fn(settings) {
      settings.sampler = @asset.ImageSampler::Descriptor(
        @asset.ImageSamplerDescriptor::linear().set_address_mode(
          @asset.ImageAddressMode::Repeat,
        ),
      )
    },
  )
  example_state.val.label_font = Some(
    asset_server.load_font("fonts/FiraSans-Bold.ttf"),
  )
  example_state.val.labels_spawned = false

  // Center rectangle with default sampler.
  spawn_panel(world, 0.0F, default_texture, @math.Vec2::new(1.0F, 1.0F))
  // Left rectangle with repeated sampler and scaled UV.
  spawn_panel(
    world,
    -RECTANGLE_OFFSET,
    repeated_texture,
    @math.Vec2::new(2.0F, 3.0F),
  )
  // Right rectangle with default sampler and scaled UV.
  spawn_panel(
    world,
    RECTANGLE_OFFSET,
    default_texture,
    @math.Vec2::new(2.0F, 3.0F),
  )

  let camera_transform = @math.Transform::identity().looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  @sprite.Camera2dBundle::new(@sprite.Camera::default(), camera_transform).spawn(
    world,
  )
  |> ignore
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(mesh2d_repeated_texture_setup))
  .add_systems(@app.Update, @app.system(ensure_labels_system))
  .run()
}
