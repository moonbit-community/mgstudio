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
struct WireframeHelpText {}

///|
let wireframe_help_text_key : @ecs.ComponentKey[WireframeHelpText] = @ecs.register_component(
  debug_name="examples.2d.wireframe_2d.WireframeHelpText",
)

///|
pub impl @ecs.Component for WireframeHelpText with component() {
  wireframe_help_text_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugins([@sprite.wireframe2d_plugin])
  .insert_resource(@sprite.Wireframe2dConfig::new(true, color_default_white()))
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param4(update_colors)))
  .run()
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn color_close(a : @sprite.Color, b : @sprite.Color) -> Bool {
  absf(a.r - b.r) < 0.0001F &&
  absf(a.g - b.g) < 0.0001F &&
  absf(a.b - b.b) < 0.0001F &&
  absf(a.a - b.a) < 0.0001F
}

///|
fn color_red() -> @sprite.Color {
  @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
}

///|
fn color_green() -> @sprite.Color {
  @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_default_white() -> @sprite.Color {
  @sprite.Color::white()
}

///|
fn wireframe_color_text(color : @sprite.Color) -> String {
  if color_close(color, color_red()) {
    "Srgba { red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0 }"
  } else if color_close(color, color_green()) {
    "Srgba { red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0 }"
  } else {
    "Srgba { red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0 }"
  }
}

///|
fn wireframe_overlay_text(config : @sprite.Wireframe2dConfig) -> String {
  let global_value = if config.global { "true" } else { "false" }
  "Controls\n---------------\nZ - Toggle global\nX - Change global color\nC - Change color of the circle wireframe\n\nWireframe2dConfig\n-------------\nGlobal: " +
  global_value +
  "\nColor: " +
  wireframe_color_text(config.default_color)
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@sprite.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let black = @sprite.Color::black()

  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(
          meshes.get_ref().val.add(
            @sprite.mesh2d_geometry_triangle(
              @sprite.Triangle2d::new(
                @math.Vec2::new(0.0F, 50.0F),
                @math.Vec2::new(-50.0F, -50.0F),
                @math.Vec2::new(50.0F, -50.0F),
              ),
            ).to_mesh(),
          ),
        ),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val.add(
            @sprite.ColorMaterialAsset::from_color(black),
          ),
        ),
        @transform.Transform::from_xyz(-150.0F, 0.0F, 0.0F),
        @sprite.NoWireframe2d::default(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(
          meshes.get_ref().val.add(
            @sprite.mesh2d_geometry_rectangle(
              @sprite.Rectangle::new(100.0F, 100.0F),
            ).to_mesh(),
          ),
        ),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val.add(
            @sprite.ColorMaterialAsset::from_color(black),
          ),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(
          meshes.get_ref().val.add(
            @sprite.mesh2d_geometry_circle(@sprite.Circle::new(50.0F)).to_mesh(),
          ),
        ),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val.add(
            @sprite.ColorMaterialAsset::from_color(black),
          ),
        ),
        @transform.Transform::from_xyz(150.0F, 0.0F, 0.0F),
        @sprite.Wireframe2d::default(),
        @sprite.Wireframe2dColor::new(color_green()),
      ),
    ),
  )

  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
        @text.Text::new(""),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
        WireframeHelpText::{  },
      ),
    ),
  )
}

///|
fn update_colors(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  config : @app.ResMut[@sprite.Wireframe2dConfig],
  wireframe_colors : @ecs.Query1[@sprite.Wireframe2dColor],
  text : @ecs.Query2[WireframeHelpText, @text.Text],
) -> Unit {
  try! text.for_each(fn(_entity, _help_text, help_text) {
    help_text.content = wireframe_overlay_text(config.get_ref().val)
  })

  if keyboard_input.just_pressed(@window.KeyCode::KeyZ) {
    let config_ref = config.get_ref()
    config_ref.val = config_ref.val.with_global(!config_ref.val.global)
  }

  if keyboard_input.just_pressed(@window.KeyCode::KeyX) {
    let config_ref = config.get_ref()
    let next_color = if color_close(
        config_ref.val.default_color,
        color_default_white(),
      ) {
      color_red()
    } else {
      color_default_white()
    }
    config_ref.val = config_ref.val.with_default_color(next_color)
  }

  if keyboard_input.just_pressed(@window.KeyCode::KeyC) {
    try! wireframe_colors.view_mut(fn(_entity, color) {
      let color_ref = color.get_ref()
      let next = if color_close(color_ref.val.color, color_green()) {
        color_red()
      } else {
        color_green()
      }
      color_ref.val = color_ref.val.with_color(next)
    })
  }
}
