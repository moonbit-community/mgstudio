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
const COLOR_EPSILON : Float = 0.0001F

///|
priv struct ColorToggleCube {}

///|
let color_toggle_cube_component_key : @ecs.ComponentKey[ColorToggleCube] = @ecs.register_component(
  debug_name="examples.3d.wireframe.ColorToggleCube",
)

///|
priv struct ControlsText {}

///|
let controls_text_component_key : @ecs.ComponentKey[ControlsText] = @ecs.register_component(
  debug_name="examples.3d.wireframe.ControlsText",
)

///|
fn color_white() -> @color.Color {
  @color.Color::srgba(1.0F, 1.0F, 1.0F, 1.0F)
}

///|
fn color_deep_pink() -> @color.Color {
  @color.Color::srgba(1.0F, 0.078F, 0.576F, 1.0F)
}

///|
fn color_lime() -> @color.Color {
  @color.Color::srgba(0.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_red() -> @color.Color {
  @color.Color::srgba(1.0F, 0.0F, 0.0F, 1.0F)
}

///|
fn color_orange() -> @color.Color {
  @color.Color::srgba(1.0F, 0.647F, 0.0F, 1.0F)
}

///|
fn color_blue() -> @color.Color {
  @color.Color::srgba(0.0F, 0.0F, 1.0F, 1.0F)
}

///|
fn color_black() -> @color.Color {
  @color.Color::srgba(0.0F, 0.0F, 0.0F, 1.0F)
}

///|
fn color_purple() -> @color.Color {
  @color.Color::srgba(0.502F, 0.0F, 0.502F, 1.0F)
}

///|
fn color_yellow() -> @color.Color {
  @color.Color::srgba(1.0F, 1.0F, 0.0F, 1.0F)
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
fn color_approx_eq(a : @color.Color, b : @color.Color) -> Bool {
  absf(a.r - b.r) <= COLOR_EPSILON &&
  absf(a.g - b.g) <= COLOR_EPSILON &&
  absf(a.b - b.b) <= COLOR_EPSILON &&
  absf(a.a - b.a) <= COLOR_EPSILON
}

///|
fn color_label(color : @color.Color) -> String {
  if color_approx_eq(color, color_white()) {
    "White"
  } else if color_approx_eq(color, color_deep_pink()) {
    "DeepPink"
  } else {
    "rgba(\{color.r.to_string()}, \{color.g.to_string()}, \{color.b.to_string()}, \{color.a.to_string()})"
  }
}

///|
fn topology_label(topology : @pbr.WireframeTopology) -> String {
  match topology {
    Triangles => "Triangles"
    Quads => "Quads"
  }
}

///|
fn float_text_1(value : Float) -> String {
  let rounded = (value * 10.0F).round().to_int()
  let whole = rounded / 10
  let fractional = rounded.abs() % 10
  "\{whole}.\{fractional}"
}

///|
fn setup_wireframe_config(world : @ecs.World) -> Unit {
  let wireframe_config = @pbr.WireframeConfig::new(true, color_white())
  world.insert_resource(@pbr.ecs_key_wireframe_config, wireframe_config)
}

///|
#warnings("-unnecessary_annotation")
fn setup_ui(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font : @asset.Handle[@asset.Font] = asset_server.load_font(
    "fonts/FiraSans-Bold.ttf",
  )

  try! (world.spawn_bundle(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera().with_order(100).with_clear_color_none(),
      @transform.Transform::identity(),
    ),
  )
  |> ignore)

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, UiRoot())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::Node().with_width(Percent(100.0F)).with_height(Percent(100.0F)),
  )

  let controls_entity = world.spawn_empty()
  try! world.set_by_key(
    controls_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(controls_entity, controls_text_component_key, ControlsText::{

  })
  try! world.set_by_key(
    controls_entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_position_type(Absolute)
    .with_left(Px(12.0F))
    .with_top(Px(12.0F)),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text,
    @text.Text::new(""),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font(font).with_font_size(14.0F),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@color.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(Left),
  )
}

///|
fn update_controls_text(world : @ecs.World) -> Unit {
  let config = match world.get_resource(@pbr.ecs_key_wireframe_config) {
    Some(value) => value
    None => WireframeConfig()
  }
  let mut current_width = 1.0F
  world.for_each_component(@pbr.ecs_key_wireframe_line_width, fn(_, width) {
    current_width = width.width
  })
  let mut text_entity : @core.Entity? = None
  world.for_each_component(controls_text_component_key, fn(entity, _) {
    text_entity = Some(entity)
  })
  guard text_entity is Some(text_entity) else { return }
  guard (try! world.get_by_key(text_entity, @text.ecs_key_text))
    is Some(text_value) else {
    return
  }
  text_value.content = "Controls\n---------------\nZ - Toggle global\nX - Change global color\nC - Change color of the green cube wireframe\nV - Line width (current: \{float_text_1(current_width)}px)\nB - Toggle topology (current: \{topology_label(config.default_topology)})\n\nWireframeConfig\n-------------\nGlobal: \{config.global.to_string()}\nColor: \{color_label(config.default_color)}"
  ignore(try! world.replace(text_entity, @text.ecs_key_text, text_value))
}

///|
#warnings("-unnecessary_annotation")
fn setup_scene(world : @ecs.World) -> Unit {
  setup_wireframe_config(world)

  let red_cube = @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F))
      }),
    ),
    @pbr.MeshMaterial3dTyped::new(
      @pbr.standard_material_add(@pbr.StandardMaterial::from_color(color_red())),
    ),
    @transform.Transform::from_xyz(-1.5F, 0.5F, -1.5F),
  ).spawn(world)
  try! world.set_by_key(red_cube, @pbr.ecs_key_no_wireframe, NoWireframe())

  @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F))
      }),
    ),
    @pbr.MeshMaterial3dTyped::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(color_orange()),
      ),
    ),
    @transform.Transform::from_xyz(-0.5F, 0.5F, -0.5F),
  ).spawn(world)
  |> ignore

  let green_cube = @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F))
      }),
    ),
    @pbr.MeshMaterial3dTyped::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(color_lime()),
      ),
    ),
    @transform.Transform::from_xyz(0.5F, 0.5F, 0.5F),
  ).spawn(world)
  try! world.set_by_key(green_cube, @pbr.ecs_key_wireframe, Wireframe())
  try! world.set_by_key(
    green_cube,
    @pbr.ecs_key_wireframe_color,
    @pbr.WireframeColor::new(color_lime()),
  )
  try! world.set_by_key(green_cube, color_toggle_cube_component_key, ColorToggleCube::{

  })

  let purple_cube = @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F))
      }),
    ),
    @pbr.MeshMaterial3dTyped::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(color_purple()),
      ),
    ),
    @transform.Transform::from_xyz(1.5F, 0.5F, 1.5F),
  ).spawn(world)
  try! world.set_by_key(purple_cube, @pbr.ecs_key_wireframe, Wireframe())
  try! world.set_by_key(
    purple_cube,
    @pbr.ecs_key_wireframe_color,
    @pbr.WireframeColor::new(color_yellow()),
  )
  try! world.set_by_key(
    purple_cube,
    @pbr.ecs_key_wireframe_line_width,
    @pbr.WireframeLineWidth::new(3.0F),
  )
  try! world.set_by_key(purple_cube, @pbr.ecs_key_wireframe_topology, Quads)

  let plane = @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets
        |> @pbr.add_mesh(
          @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
            @math.Vec2::new(5.0F, 5.0F),
          ).build(),
        )
      }),
    ),
    @pbr.MeshMaterial3dTyped::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(color_blue()),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  try! world.set_by_key(
    plane,
    @pbr.ecs_key_wireframe_color,
    @pbr.WireframeColor::new(color_black()),
  )

  let light = world.spawn_empty()
  try! world.set_by_key(light, @pbr.ecs_key_point_light, PointLight())
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(2.0F, 4.0F, 2.0F),
  )

  @pbr.Camera3dBundle::new(
    Camera(),
    @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  setup_ui(world)
  update_controls_text(world)
}

///|
fn update_colors(world : @ecs.World) -> Unit {
  let mut config = match world.get_resource(@pbr.ecs_key_wireframe_config) {
    Some(value) => value
    None => WireframeConfig()
  }
  update_controls_text(world)
  let mut config_changed = false
  if @input.key_just_pressed(KeyZ) {
    config = config.with_global(!config.global)
    config_changed = true
  }
  if @input.key_just_pressed(KeyX) {
    let next = if color_approx_eq(config.default_color, color_white()) {
      color_deep_pink()
    } else {
      color_white()
    }
    config = config.with_default_color(next)
    config_changed = true
  }
  if @input.key_just_pressed(KeyC) {
    let updates : Array[(@core.Entity, @pbr.WireframeColor)] = []
    world.for_each_component(@pbr.ecs_key_wireframe_color, fn(entity, color) {
      if (try! world.get_by_key(entity, color_toggle_cube_component_key))
        is Some(_) {
        let next = if color_approx_eq(color.color, color_lime()) {
          color_red()
        } else {
          color_lime()
        }
        updates.push((entity, color.with_color(next)))
      }
    })
    if updates.length() > 0 {
      for pair in updates {
        try! (world.replace(pair.0, @pbr.ecs_key_wireframe_color, pair.1)
        |> ignore)
      }
    }
  }

  if @input.key_just_pressed(KeyV) {
    let updates : Array[(@core.Entity, @pbr.WireframeLineWidth)] = []
    world.for_each_component(@pbr.ecs_key_wireframe_line_width, fn(
      entity,
      width,
    ) {
      let width_pixels = width.width.to_int()
      let next_width = if width_pixels <= 2 {
        3.0F
      } else if width_pixels <= 4 {
        5.0F
      } else if width_pixels <= 7 {
        10.0F
      } else {
        2.0F
      }
      updates.push((entity, width.with_width(next_width)))
    })
    for pair in updates {
      ignore(
        try! world.replace(pair.0, @pbr.ecs_key_wireframe_line_width, pair.1),
      )
    }
  }

  if @input.key_just_pressed(KeyB) {
    let next_topology = match config.default_topology {
      Triangles => @pbr.WireframeTopology::Quads
      Quads => Triangles
    }
    config = config.with_default_topology(next_topology)
    config_changed = true
  }

  if config_changed {
    world.insert_resource(@pbr.ecs_key_wireframe_config, config)
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@pbr.WireframePlugin::WireframePlugin())
  .add_systems_world(Startup, setup_scene)
  .add_systems_world(Update, update_colors)
  .run()
}
