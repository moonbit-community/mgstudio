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
pub impl @ecs.Component for WireframeHelpText with fn component() {
  wireframe_help_text_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(
    @sprite_render_mesh2d_wireframe2d.Wireframe2dPlugin::Wireframe2dPlugin(),
  )
  .insert_resource(
    @sprite_render_mesh2d_wireframe2d.Wireframe2dConfig::new(
      true,
      color_default_white(),
    ),
  )
  .add_systems_param4(@app.Startup, setup)
  .add_systems_param4(@app.Update, update_colors)
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
fn color_close(a : @color.Color, b : @color.Color) -> Bool {
  absf(a.r - b.r) < 0.0001F &&
  absf(a.g - b.g) < 0.0001F &&
  absf(a.b - b.b) < 0.0001F &&
  absf(a.a - b.a) < 0.0001F
}

///|
fn color_red() -> @color.Color {
  @color.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
}

///|
fn color_green() -> @color.Color {
  @color.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_default_white() -> @color.Color {
  @color.Color::white()
}

///|
fn wireframe_color_text(color : @color.Color) -> String {
  if color_close(color, color_red()) {
    "Srgba { red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0 }"
  } else if color_close(color, color_green()) {
    "Srgba { red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0 }"
  } else {
    "Srgba { red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0 }"
  }
}

///|
fn wireframe_overlay_text(
  config : @sprite_render_mesh2d_wireframe2d.Wireframe2dConfig,
) -> String {
  let global_value = if config.global { "true" } else { "false" }
  "Controls\n---------------\nZ - Toggle global\nX - Change global color\nC - Change color of the circle wireframe\n\nWireframe2dConfig\n-------------\nGlobal: \{global_value}\nColor: \{wireframe_color_text(config.default_color)}"
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[
    @asset.Assets[@sprite_render_mesh2d_color_material.ColorMaterial],
  ],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let black = @color.Color::black()

  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(
          meshes
          .peek()
          .add(
            @mesh_primitives.triangle_to_mesh2d_geometry(
              @math.Triangle2d::new(
                @math.Vec2::new(0.0F, 50.0F),
                @math.Vec2::new(-50.0F, -50.0F),
                @math.Vec2::new(50.0F, -50.0F),
              ),
            ).to_mesh(),
          ),
        ),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials.modify(fn(materials) {
            materials.add(
              @sprite_render_mesh2d_color_material.ColorMaterial::from_color(
                black,
              ),
            )
          }),
        ),
        @transform.Transform::from_xyz(-150.0F, 0.0F, 0.0F),
        @sprite_render_mesh2d_wireframe2d.NoWireframe2d::NoWireframe2d(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(
          meshes
          .peek()
          .add(
            @mesh_primitives.rectangle_to_mesh2d_geometry(
              @math.Rectangle::new(100.0F, 100.0F),
            ).to_mesh(),
          ),
        ),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials.modify(fn(materials) {
            materials.add(
              @sprite_render_mesh2d_color_material.ColorMaterial::from_color(
                black,
              ),
            )
          }),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(
          meshes
          .peek()
          .add(
            @mesh_primitives.circle_to_mesh2d_geometry(@math.Circle::new(50.0F)).to_mesh(),
          ),
        ),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials.modify(fn(materials) {
            materials.add(
              @sprite_render_mesh2d_color_material.ColorMaterial::from_color(
                black,
              ),
            )
          }),
        ),
        @transform.Transform::from_xyz(150.0F, 0.0F, 0.0F),
        @sprite_render_mesh2d_wireframe2d.Wireframe2d::Wireframe2d(),
        @sprite_render_mesh2d_wireframe2d.Wireframe2dColor::new(color_green()),
      ),
    ),
  )

  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
        @text.Text::new(""),
        @text.TextFont::TextFont().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@color.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
        WireframeHelpText::{  },
      ),
    ),
  )
}

///|
fn update_colors(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  config : @app.ResMut[@sprite_render_mesh2d_wireframe2d.Wireframe2dConfig],
  wireframe_colors : @ecs.Query[
    @ecs.Write[@sprite_render_mesh2d_wireframe2d.Wireframe2dColor],
    @ecs.All,
  ],
  text : @app.Single[@ecs.Write[@text.Text], @ecs.With[WireframeHelpText]],
) -> Unit {
  text
  .get()
  .modify(fn(value) { value.content = wireframe_overlay_text(config.peek()) })

  if keyboard_input.just_pressed(@window.KeyCode::KeyZ) {
    let current = config.peek()
    config.set(current.with_global(!current.global))
  }

  if keyboard_input.just_pressed(@window.KeyCode::KeyX) {
    let current = config.peek()
    let next_color = if color_close(
        current.default_color,
        color_default_white(),
      ) {
      color_red()
    } else {
      color_default_white()
    }
    config.set(current.with_default_color(next_color))
  }

  if keyboard_input.just_pressed(@window.KeyCode::KeyC) {
    try! wireframe_colors.view(fn(_entity, color) {
      let current = color.value()
      let next = if color_close(current.color, color_green()) {
        color_red()
      } else {
        color_green()
      }
      color.set(current.with_color(next))
    })
  }
}
