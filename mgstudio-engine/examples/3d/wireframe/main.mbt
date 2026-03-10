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
/// Port of `bevy/examples/3d/wireframe.rs`.

///|
const COLOR_EPSILON : Float = 0.0001F

///|
priv struct WireframeState {
  mut controls_text : @text.TextHandle?
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
fn spawn_ui_text_handle(
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @sprite.Color,
) -> @text.TextHandle {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(font_size),
    @math.Transform::identity(),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .spawn()
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
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )

  let controls_text_handle = spawn_ui_text_handle(
    "",
    font,
    14.0F,
    @sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F),
  )
  let controls_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(controls_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    controls_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(controls_entity, @ui.UiText::new(controls_text_handle), tick)
  wireframe_state.val.controls_text = Some(controls_text_handle)
}

///|
fn update_controls_text(world : @ecs.World) -> Unit {
  guard wireframe_state.val.controls_text is Some(text_handle) else { return }
  let config = try world.get_resource(@pbr.ecs_key_wireframe_config) catch {
    _ => @pbr.WireframeConfig::default()
  } noraise {
    Some(value) => value
    None => @pbr.WireframeConfig::default()
  }
  @text.text_set_content(
    text_handle,
    "Controls\n---------------\n" +
    "Z - Toggle global\n" +
    "X - Change global color\n" +
    "C - Change color of the green cube wireframe\n\n" +
    "WireframeConfig\n-------------\n" +
    "Global: " +
    config.global.to_string() +
    "\nColor: " +
    color_label(config.default_color),
  )
}

///|
fn setup_scene(world : @ecs.World) -> Unit {
  wireframe_state.val.controls_text = None
  setup_wireframe_config(world)

  let tick = world.read_change_tick()
  let red_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(@pbr.StandardMaterial::from_color(color_red())),
    ),
    @math.Transform::from_xyz(-1.0F, 0.5F, -1.0F),
  ).spawn(world)
  world
  .component(@pbr.ecs_key_no_wireframe)
  .insert(red_cube, @pbr.NoWireframe::default(), tick)

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(color_orange()),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let green_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(color_lime()),
      ),
    ),
    @math.Transform::from_xyz(1.0F, 0.5F, 1.0F),
  ).spawn(world)
  world
  .component(@pbr.ecs_key_wireframe)
  .insert(green_cube, @pbr.Wireframe::default(), tick)
  world
  .component(@pbr.ecs_key_wireframe_color)
  .insert(green_cube, @pbr.WireframeColor::new(color_lime()), tick)

  let plane = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_plane(5.0F, 5.0F),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(color_blue()),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@pbr.ecs_key_wireframe_color)
  .insert(plane, @pbr.WireframeColor::new(color_black()), tick)

  let light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(light, @pbr.PointLight::default(), tick)
  world
  .component(@math.ecs_key_transform)
  .insert(light, @math.Transform::from_xyz(2.0F, 4.0F, 2.0F), tick)

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
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
  let tick = world.read_change_tick()

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
    let wireframe_store = world.component(@pbr.ecs_key_wireframe)
    world
    .component(@pbr.ecs_key_wireframe_color)
    .for_each(fn(entity, color) {
      if wireframe_store.get(entity) is Some(_) {
        let next = if color_approx_eq(color.color, color_lime()) {
          color_red()
        } else {
          color_lime()
        }
        updates.push((entity, color.with_color(next)))
      }
    })
    if updates.length() > 0 {
      let wireframe_color_store = world.component(@pbr.ecs_key_wireframe_color)
      for pair in updates {
        wireframe_color_store.set(pair.0, pair.1, tick) |> ignore
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
