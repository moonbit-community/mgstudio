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

///|
const COLOR_EPSILON : Float = 0.0001F

///|
priv struct WireframeState {
  mut controls_text : @core.Entity?
}

///|
let wireframe_state : Ref[WireframeState] = Ref::new({ controls_text: None })

///|
fn color_white() -> @sprite.Color {
  @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F)
}

///|
fn color_deep_pink() -> @sprite.Color {
  @sprite.Color::new(1.0F, 0.08F, 0.58F, 1.0F)
}

///|
fn color_lime() -> @sprite.Color {
  @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_red() -> @sprite.Color {
  @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
}

///|
fn color_orange() -> @sprite.Color {
  @sprite.Color::new(1.0F, 0.65F, 0.0F, 1.0F)
}

///|
fn color_blue() -> @sprite.Color {
  @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F)
}

///|
fn color_black() -> @sprite.Color {
  @sprite.Color::new(0.0F, 0.0F, 0.0F, 1.0F)
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
fn color_approx_eq(a : @sprite.Color, b : @sprite.Color) -> Bool {
  absf(a.r - b.r) <= COLOR_EPSILON &&
  absf(a.g - b.g) <= COLOR_EPSILON &&
  absf(a.b - b.b) <= COLOR_EPSILON &&
  absf(a.a - b.a) <= COLOR_EPSILON
}

///|
fn color_label(color : @sprite.Color) -> String {
  if color_approx_eq(color, color_white()) {
    "White"
  } else if color_approx_eq(color, color_deep_pink()) {
    "DeepPink"
  } else {
    "rgba(" +
    color.r.to_string() +
    ", " +
    color.g.to_string() +
    ", " +
    color.b.to_string() +
    ", " +
    color.a.to_string() +
    ")"
  }
}

///|
fn setup_wireframe_config(world : @ecs.World) -> Unit {
  let wireframe_config = @pbr.WireframeConfig::new(true, color_white())
  world.insert_resource(@pbr.ecs_key_wireframe_config, wireframe_config)
}

///|
fn setup_ui(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font : @asset.Handle[@asset.Font] = asset_server.load_font(
    "fonts/FiraSans-Bold.ttf",
  )

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(100).with_clear_color_none(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  let controls_entity = world.spawn_empty()
  try! world.set_by_key(
    controls_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    controls_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    controls_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text,
    @text.Text::new(""),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(14.0F),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  try! world.set_by_key(
    controls_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
  wireframe_state.val.controls_text = Some(controls_entity)
}

///|
fn update_controls_text(world : @ecs.World) -> Unit {
  guard wireframe_state.val.controls_text is Some(text_entity) else { return }
  let config = try world.get_resource(@pbr.ecs_key_wireframe_config) catch {
    _ => @pbr.WireframeConfig::default()
  } noraise {
    Some(value) => value
    None => @pbr.WireframeConfig::default()
  }
  guard (try! world.get_by_key(text_entity, @text.ecs_key_text))
    is Some(text_value) else {
    return
  }
  text_value.content = "Controls\n---------------\n" +
    "Z - Toggle global\n" +
    "X - Change global color\n" +
    "C - Change color of the green cube wireframe\n\n" +
    "WireframeConfig\n-------------\n" +
    "Global: " +
    config.global.to_string() +
    "\nColor: " +
    color_label(config.default_color)
  ignore(try! world.replace(text_entity, @text.ecs_key_text, text_value))
}

///|
fn setup_scene(world : @ecs.World) -> Unit {
  wireframe_state.val.controls_text = None
  setup_wireframe_config(world)

  let red_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(@pbr.StandardMaterial::from_color(color_red())),
    ),
    @transform.Transform::from_xyz(-1.0F, 0.5F, -1.0F),
  ).spawn(world)
  try! world.set_by_key(
    red_cube,
    @pbr.ecs_key_no_wireframe,
    @pbr.NoWireframe::default(),
  )

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(color_orange()),
      ),
    ),
    @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let green_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(color_lime()),
      ),
    ),
    @transform.Transform::from_xyz(1.0F, 0.5F, 1.0F),
  ).spawn(world)
  try! world.set_by_key(
    green_cube,
    @pbr.ecs_key_wireframe,
    @pbr.Wireframe::default(),
  )
  try! world.set_by_key(
    green_cube,
    @pbr.ecs_key_wireframe_color,
    @pbr.WireframeColor::new(color_lime()),
  )

  let plane = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(5.0F, 5.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
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
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::default(),
  )
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::default(),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(2.0F, 4.0F, 2.0F),
  )

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
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
  let mut config = try world.get_resource(@pbr.ecs_key_wireframe_config) catch {
    _ => @pbr.WireframeConfig::default()
  } noraise {
    Some(value) => value
    None => @pbr.WireframeConfig::default()
  }
  let mut config_changed = false
  if @input.key_just_pressed(@window.KeyCode::KeyZ) {
    config = config.with_global(!config.global)
    config_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyX) {
    let next = if color_approx_eq(config.default_color, color_white()) {
      color_deep_pink()
    } else {
      color_white()
    }
    config = config.with_default_color(next)
    config_changed = true
  }
  if config_changed {
    world.insert_resource(@pbr.ecs_key_wireframe_config, config)
  }

  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    let updates : Array[(@core.Entity, @pbr.WireframeColor)] = []
    world.for_each_component(@pbr.ecs_key_wireframe_color, fn(entity, color) {
      if (try! world.get_by_key(entity, @pbr.ecs_key_wireframe)) is Some(_) {
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

  update_controls_text(world)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([@pbr.wireframe_plugin])
  .add_systems(@app.Startup, @app.system(setup_scene))
  .add_systems(@app.Update, @app.system(update_colors))
  .run()
}
