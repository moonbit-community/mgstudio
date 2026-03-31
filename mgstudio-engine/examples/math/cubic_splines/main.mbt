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

///|
enum SplineMode {
  Hermite
  Cardinal
  B
} derive(Eq, Show)

///|
impl Default for SplineMode with default() {
  SplineMode::Hermite
}

///|
enum CyclingMode {
  NotCyclic
  Cyclic
} derive(Eq, Show)

///|
impl Default for CyclingMode with default() {
  CyclingMode::NotCyclic
}

///|
struct Curve {
  value : @math.CubicCurve[@math.Vec2]?
}

///|
struct ControlPoints {
  points_and_tangents : Array[(@math.Vec2, @math.Vec2)]
}

///|
struct MouseEditMove {
  mut start : @math.Vec2?
}

///|
struct MousePosition {
  mut position : @math.Vec2?
}

///|
struct SplineModeTextHandle {
  entity : @core.Entity
}

///|
struct CyclingModeTextHandle {
  entity : @core.Entity
}

///|
let spline_mode_resource_key : @ecs.ResourceKey[SplineMode] = @ecs.register_resource(
  debug_name="examples.math.cubic_splines.SplineMode",
)

///|
let cycling_mode_resource_key : @ecs.ResourceKey[CyclingMode] = @ecs.register_resource(
  debug_name="examples.math.cubic_splines.CyclingMode",
)

///|
let curve_resource_key : @ecs.ResourceKey[Curve] = @ecs.register_resource(
  debug_name="examples.math.cubic_splines.Curve",
)

///|
let control_points_resource_key : @ecs.ResourceKey[ControlPoints] = @ecs.register_resource(
  debug_name="examples.math.cubic_splines.ControlPoints",
)

///|
let mouse_edit_move_resource_key : @ecs.ResourceKey[MouseEditMove] = @ecs.register_resource(
  debug_name="examples.math.cubic_splines.MouseEditMove",
)

///|
let mouse_position_resource_key : @ecs.ResourceKey[MousePosition] = @ecs.register_resource(
  debug_name="examples.math.cubic_splines.MousePosition",
)

///|
let spline_mode_text_handle_resource_key : @ecs.ResourceKey[
  SplineModeTextHandle,
] = @ecs.register_resource(
  debug_name="examples.math.cubic_splines.SplineModeTextHandle",
)

///|
let cycling_mode_text_handle_resource_key : @ecs.ResourceKey[
  CyclingModeTextHandle,
] = @ecs.register_resource(
  debug_name="examples.math.cubic_splines.CyclingModeTextHandle",
)

///|
impl @app.Resource for SplineMode with resource() {
  spline_mode_resource_key
}

///|
impl @app.Resource for CyclingMode with resource() {
  cycling_mode_resource_key
}

///|
impl @app.Resource for Curve with resource() {
  curve_resource_key
}

///|
impl @app.Resource for ControlPoints with resource() {
  control_points_resource_key
}

///|
impl @app.Resource for MouseEditMove with resource() {
  mouse_edit_move_resource_key
}

///|
impl @app.Resource for MousePosition with resource() {
  mouse_position_resource_key
}

///|
impl @app.Resource for SplineModeTextHandle with resource() {
  spline_mode_text_handle_resource_key
}

///|
impl @app.Resource for CyclingModeTextHandle with resource() {
  cycling_mode_text_handle_resource_key
}

///|
let cubic_splines_input_set : @app.SystemSet = @app.system_set(
  "examples.math.cubic_splines.input",
)

///|
let cubic_splines_curve_set : @app.SystemSet = @app.system_set(
  "examples.math.cubic_splines.curve",
)

///|
let cubic_splines_ui_set : @app.SystemSet = @app.system_set(
  "examples.math.cubic_splines.ui",
)

///|
let cubic_splines_draw_set : @app.SystemSet = @app.system_set(
  "examples.math.cubic_splines.draw",
)

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .configure_set(@app.Update, cubic_splines_curve_set, after=[
    cubic_splines_input_set,
  ])
  .configure_set(@app.Update, cubic_splines_ui_set, after=[
    cubic_splines_input_set,
  ])
  .configure_set(@app.Update, cubic_splines_draw_set, after=[
    cubic_splines_curve_set, cubic_splines_ui_set,
  ])
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(handle_keypress)).in_set(
      cubic_splines_input_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(handle_mouse_move)).in_set(
      cubic_splines_input_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(handle_mouse_press)).in_set(
      cubic_splines_input_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(update_curve)).in_set(
      cubic_splines_curve_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_spline_mode_text)).in_set(
      cubic_splines_ui_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_cycling_mode_text)).in_set(
      cubic_splines_ui_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(draw_edit_move)).in_set(
      cubic_splines_draw_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(draw_curve)).in_set(cubic_splines_draw_set),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(draw_control_points)).in_set(
      cubic_splines_draw_set,
    ),
  )
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  let spline_mode = SplineMode::default()
  let cycling_mode = CyclingMode::default()
  let control_points = default_control_points()
  let curve = form_curve(control_points, spline_mode, cycling_mode)

  world.insert_resource(spline_mode_resource_key, spline_mode)
  world.insert_resource(cycling_mode_resource_key, cycling_mode)
  world.insert_resource(control_points_resource_key, control_points)
  world.insert_resource(curve_resource_key, curve)
  world.insert_resource(mouse_position_resource_key, MousePosition::{
    position: None,
  })
  world.insert_resource(mouse_edit_move_resource_key, MouseEditMove::{
    start: None,
  })

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_font = @text.TextFont::default()
    .with_font(font)
    .with_font_size(18.0F)

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F))
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_row_gap(@ui.Val::Px(20.0F)),
  )

  spawn_ui_text_line(world, root, text_font, instructions_text()) |> ignore

  let spline_handle = spawn_ui_text_line(
    world,
    root,
    text_font,
    "Spline: " + spline_mode_label(spline_mode),
  )
  let cycling_handle = spawn_ui_text_line(
    world,
    root,
    text_font,
    cycling_mode_label(cycling_mode),
  )
  world.insert_resource(spline_mode_text_handle_resource_key, SplineModeTextHandle::{
    entity: spline_handle,
  })
  world.insert_resource(cycling_mode_text_handle_resource_key, CyclingModeTextHandle::{
    entity: cycling_handle,
  })
}

///|
fn update_curve(
  control_points : @app.Res[ControlPoints],
  spline_mode : @app.Res[SplineMode],
  cycling_mode : @app.Res[CyclingMode],
  curve : @app.ResMut[Curve],
) -> Unit {
  curve.get_ref().val = form_curve(
    control_points.get(),
    spline_mode.get(),
    cycling_mode.get(),
  )
}

///|
fn draw_curve(
  curve : @app.Res[Curve],
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  guard curve.get().value is Some(curve_value) else { return }
  let resolution = 100 * curve_value.segments().length()
  gizmos.linestrip_2d(
    curve_value.iter_positions(resolution),
    @sprite.Color::white(),
  )
}

///|
fn draw_control_points(
  control_points : @app.Res[ControlPoints],
  spline_mode : @app.Res[SplineMode],
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  let green = @sprite.Color::srgb(0.0F, 1.0F, 0.0F)
  let red = @sprite.Color::srgb(1.0F, 0.0F, 0.0F)
  for pair in control_points.get().points_and_tangents {
    let point = pair.0
    let tangent = pair.1
    gizmos.circle_2d(@sprite.Isometry2d::new(point, 0.0F), 10.0F, green)
    |> ignore
    if spline_mode.get() == SplineMode::Hermite {
      gizmos.arrow_2d(point, point.add(tangent), red) |> ignore
    }
  }
}

///|
fn form_curve(
  control_points : ControlPoints,
  spline_mode : SplineMode,
  cycling_mode : CyclingMode,
) -> Curve {
  let points : Array[@math.Vec2] = []
  let tangents : Array[@math.Vec2] = []
  for pair in control_points.points_and_tangents {
    points.push(pair.0)
    tangents.push(pair.1)
  }
  match spline_mode {
    Hermite => {
      let spline = @math.CubicHermite::new(points, tangents)
      let curve = try {
        if cycling_mode == CyclingMode::Cyclic {
          spline.to_curve_cyclic()
        } else {
          spline.to_curve()
        }
      } catch {
        _ => return Curve::{ value: None }
      }
      Curve::{ value: Some(curve) }
    }
    Cardinal => {
      let spline = @math.CubicCardinalSpline::new_catmull_rom(points)
      let curve = try {
        if cycling_mode == CyclingMode::Cyclic {
          spline.to_curve_cyclic()
        } else {
          spline.to_curve()
        }
      } catch {
        _ => return Curve::{ value: None }
      }
      Curve::{ value: Some(curve) }
    }
    B => {
      let spline = @math.CubicBSpline::new(points)
      let curve = try {
        if cycling_mode == CyclingMode::Cyclic {
          spline.to_curve_cyclic()
        } else {
          spline.to_curve()
        }
      } catch {
        _ => return Curve::{ value: None }
      }
      Curve::{ value: Some(curve) }
    }
  }
}

///|
fn update_spline_mode_text(
  spline_mode : @app.Res[SplineMode],
  handle : @app.Res[SplineModeTextHandle],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  guard (world.get_by_key(handle.get().entity, @text.ecs_key_text) catch {
      _ => None
    })
    is Some(text_value) else {
    return
  }
  text_value.content = "Spline: " + spline_mode_label(spline_mode.get())
  ignore(
    world.replace(handle.get().entity, @text.ecs_key_text, text_value) catch {
      _ => false
    },
  )
}

///|
fn update_cycling_mode_text(
  cycling_mode : @app.Res[CyclingMode],
  handle : @app.Res[CyclingModeTextHandle],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  guard (world.get_by_key(handle.get().entity, @text.ecs_key_text) catch {
      _ => None
    })
    is Some(text_value) else {
    return
  }
  text_value.content = cycling_mode_label(cycling_mode.get())
  ignore(
    world.replace(handle.get().entity, @text.ecs_key_text, text_value) catch {
      _ => false
    },
  )
}

///|
fn handle_mouse_move(
  cursor_moved_reader : @ecs.MessageReader[@window.CursorMoved],
  mouse_position : @app.ResMut[MousePosition],
) -> Unit {
  let mouse_position_ref = mouse_position.get_ref()
  for event in (try! cursor_moved_reader.read()) {
    mouse_position_ref.val.position = Some(event.position)
  }
}

///|
fn handle_mouse_press(
  mouse_button_input_reader : @ecs.MessageReader[@input.MouseButtonInput],
  mouse_position : @app.Res[MousePosition],
  edit_move : @app.ResMut[MouseEditMove],
  control_points : @app.ResMut[ControlPoints],
) -> Unit {
  guard mouse_position.get().position is Some(mouse_pos) else { return }
  let edit_move_ref = edit_move.get_ref()
  let control_points_ref = control_points.get_ref()
  for event in (try! mouse_button_input_reader.read()) {
    match event.button {
      Left =>
        match event.state {
          Pressed =>
            if edit_move_ref.val.start is None {
              edit_move_ref.val.start = Some(mouse_pos)
            }
          Released =>
            if edit_move_ref.val.start is Some(start) {
              if screen_to_world(start) is Some(point) {
                if screen_to_world(mouse_pos) is Some(end_point) {
                  control_points_ref.val.points_and_tangents.push(
                    (point, end_point.sub(point)),
                  )
                  edit_move_ref.val.start = None
                }
              }
            }
        }
      _ => ()
    }
  }
}

///|
fn draw_edit_move(
  edit_move : @app.Res[MouseEditMove],
  mouse_position : @app.Res[MousePosition],
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  guard edit_move.get().start is Some(start) else { return }
  guard mouse_position.get().position is Some(mouse_pos) else { return }
  guard screen_to_world(start) is Some(world_start) else { return }
  guard screen_to_world(mouse_pos) is Some(world_end) else { return }

  let preview = @sprite.Color::srgb(0.0F, 1.0F, 0.7F)
  gizmos.circle_2d(@sprite.Isometry2d::new(world_start, 0.0F), 10.0F, preview)
  |> ignore
  gizmos.circle_2d(@sprite.Isometry2d::new(world_start, 0.0F), 7.0F, preview)
  |> ignore
  gizmos.arrow_2d(world_start, world_end, @sprite.Color::srgb(1.0F, 0.0F, 0.7F))
  |> ignore
}

///|
fn handle_keypress(
  keyboard : @input.ButtonInput[@window.KeyCode],
  spline_mode : @app.ResMut[SplineMode],
  cycling_mode : @app.ResMut[CyclingMode],
  control_points : @app.ResMut[ControlPoints],
) -> Unit {
  if keyboard.just_pressed(KeyS) {
    let spline_mode_ref = spline_mode.get_ref()
    spline_mode_ref.val = next_spline_mode(spline_mode_ref.val)
  }
  if keyboard.just_pressed(KeyC) {
    let cycling_mode_ref = cycling_mode.get_ref()
    cycling_mode_ref.val = next_cycling_mode(cycling_mode_ref.val)
  }
  if keyboard.just_pressed(KeyR) {
    let control_points_ref = control_points.get_ref()
    if control_points_ref.val.points_and_tangents.length() > 0 {
      control_points_ref.val.points_and_tangents.pop() |> ignore
    }
  }
}

///|
fn next_spline_mode(mode : SplineMode) -> SplineMode {
  match mode {
    Hermite => Cardinal
    Cardinal => B
    B => Hermite
  }
}

///|
fn next_cycling_mode(mode : CyclingMode) -> CyclingMode {
  match mode {
    NotCyclic => Cyclic
    Cyclic => NotCyclic
  }
}

///|
fn spline_mode_label(mode : SplineMode) -> String {
  match mode {
    Hermite => "Hermite"
    Cardinal => "Cardinal"
    B => "B"
  }
}

///|
fn cycling_mode_label(mode : CyclingMode) -> String {
  match mode {
    NotCyclic => "Not Cyclic"
    Cyclic => "Cyclic"
  }
}

///|
fn default_control_points() -> ControlPoints {
  ControlPoints::{
    points_and_tangents: [
      (@math.Vec2::new(-500.0F, -200.0F), @math.Vec2::new(0.0F, 200.0F)),
      (@math.Vec2::new(-250.0F, 250.0F), @math.Vec2::new(200.0F, 0.0F)),
      (@math.Vec2::new(250.0F, 250.0F), @math.Vec2::new(0.0F, -200.0F)),
      (@math.Vec2::new(500.0F, -200.0F), @math.Vec2::new(-200.0F, 0.0F)),
    ],
  }
}

///|
fn spawn_ui_text_line(
  world : @ecs.World,
  parent : @core.Entity,
  font : @text.TextFont,
  content : String,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(
    entity,
    @ui.ecs_key_node,
    @ui.Node::default().with_width(@ui.Val::Auto).with_height(@ui.Val::Auto),
  )
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::new(content))
  try! world.set_by_key(entity, @text.ecs_key_text_font, font)
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(entity, @text.ecs_key_text_font, font)
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
  entity
}

///|
fn current_world_abort() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None => abort("Missing current world for cubic_splines example")
  }
}

///|
fn screen_to_world(position : @math.Vec2) -> @math.Vec2? {
  @sprite_render.render2d_viewport_to_world_2d(current_world_abort(), position)
}

///|
fn instructions_text() -> String {
  "Click and drag to add control points and their tangents\n" +
  "R: Remove the last control point\n" +
  "S: Cycle the spline construction being used\n" +
  "C: Toggle cyclic curve construction"
}
