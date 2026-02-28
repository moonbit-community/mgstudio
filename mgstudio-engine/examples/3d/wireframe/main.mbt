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
fn color_white() -> @render2d.Color {
  @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F)
}

///|
fn color_deep_pink() -> @render2d.Color {
  @render2d.Color::new(1.0F, 0.08F, 0.58F, 1.0F)
}

///|
fn color_lime() -> @render2d.Color {
  @render2d.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_red() -> @render2d.Color {
  @render2d.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
}

///|
fn color_orange() -> @render2d.Color {
  @render2d.Color::new(1.0F, 0.65F, 0.0F, 1.0F)
}

///|
fn color_blue() -> @render2d.Color {
  @render2d.Color::new(0.0F, 0.0F, 1.0F, 1.0F)
}

///|
fn color_black() -> @render2d.Color {
  @render2d.Color::new(0.0F, 0.0F, 0.0F, 1.0F)
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
fn color_approx_eq(a : @render2d.Color, b : @render2d.Color) -> Bool {
  absf(a.r - b.r) <= COLOR_EPSILON &&
  absf(a.g - b.g) <= COLOR_EPSILON &&
  absf(a.b - b.b) <= COLOR_EPSILON &&
  absf(a.a - b.a) <= COLOR_EPSILON
}

///|
fn color_label(color : @render2d.Color) -> String {
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
  color : @render2d.Color,
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
fn setup_wireframe_config(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let wireframe_config = @render3d.WireframeConfig::new(true, color_white())
  if world.get_wireframe_config_resource().get_ref_mut(tick) is Some(config_ref) {
    config_ref.val = wireframe_config
  } else {
    world.get_wireframe_config_resource().insert(wireframe_config, tick)
  }
}

///|
fn setup_ui(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font : @asset.Handle[@asset.Font] = asset_server.load_font(
    "fonts/FiraSans-Bold.ttf",
  )

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default().with_order(100).with_clear_color_none(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.get_ui_root_store().insert(root, @ui.UiRoot::default(), tick)
  world
  .get_node_store()
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
    @render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F),
  )
  let controls_entity = world.spawn_empty()
  world
  .get_parent_store()
  .insert(controls_entity, @hierarchy.Parent::new(root), tick)
  world
  .get_node_store()
  .insert(
    controls_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .get_ui_text_store()
  .insert(controls_entity, @ui.UiText::new(controls_text_handle), tick)
  wireframe_state.val.controls_text = Some(controls_text_handle)
}

///|
fn update_controls_text(world : @ecs_world.World) -> Unit {
  guard wireframe_state.val.controls_text is Some(text_handle) else { return }
  let config = if world.get_wireframe_config_resource().get_ref()
    is Some(config_ref) {
    config_ref.val
  } else {
    @render3d.WireframeConfig::default()
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
fn setup_scene(world : @ecs_world.World) -> Unit {
  wireframe_state.val.controls_text = None
  setup_wireframe_config(world)

  let tick = world.read_change_tick()
  let red_cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(color_red()),
      ),
    ),
    @math.Transform::from_xyz(-1.0F, 0.5F, -1.0F),
  ).spawn(world)
  world
  .get_no_wireframe_store()
  .insert(red_cube, @render3d.NoWireframe::default(), tick)

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(color_orange()),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let green_cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(color_lime()),
      ),
    ),
    @math.Transform::from_xyz(1.0F, 0.5F, 1.0F),
  ).spawn(world)
  world
  .get_wireframe_store()
  .insert(green_cube, @render3d.Wireframe::default(), tick)
  world
  .get_wireframe_color_store()
  .insert(green_cube, @render3d.WireframeColor::new(color_lime()), tick)

  let plane = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(5.0F, 5.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(color_blue()),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .get_wireframe_color_store()
  .insert(plane, @render3d.WireframeColor::new(color_black()), tick)

  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(light, @render3d.PointLight::default(), tick)
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(2.0F, 4.0F, 2.0F), tick)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
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
fn update_colors(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  if world.get_wireframe_config_resource().get_ref_mut(tick) is Some(config_ref) {
    if @input.key_just_pressed(@window.KeyCode::KeyZ) {
      config_ref.val = config_ref.val.with_global(!config_ref.val.global)
    }
    if @input.key_just_pressed(@window.KeyCode::KeyX) {
      let next = if color_approx_eq(config_ref.val.default_color, color_white()) {
        color_deep_pink()
      } else {
        color_white()
      }
      config_ref.val = config_ref.val.with_default_color(next)
    }
  }

  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    let updates : Array[(@core.Entity, @render3d.WireframeColor)] = []
    let wireframe_store = world.get_wireframe_store()
    world
    .get_wireframe_color_store()
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
      let wireframe_color_store = world.get_wireframe_color_store()
      for pair in updates {
        wireframe_color_store.set(pair.0, pair.1, tick) |> ignore
      }
    }
  }

  update_controls_text(world)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_plugins([@render3d.wireframe_plugin])
  .add_startup_system(setup_scene)
  .add_system(update_colors)
  .run()
}
