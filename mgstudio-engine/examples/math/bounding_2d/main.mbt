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
/// Port of `bevy/examples/math/bounding_2d.rs`.

///|
const OFFSET_X : Float = 125.0F

///|
const OFFSET_Y : Float = 75.0F

///|
const OUTLINE_SAMPLES : Int = 48

///|
const SYSTEM_SET_UPDATE_VOLUMES : String = "examples.math.bounding_2d.update_volumes"

///|
const SYSTEM_SET_RENDER_SHAPES : String = "examples.math.bounding_2d.render_shapes"

///|
const SYSTEM_SET_RENDER_VOLUMES : String = "examples.math.bounding_2d.render_volumes"

///|
pub(all) enum Test {
  AabbSweep
  CircleSweep
  RayCast
  AabbCast
  CircleCast
} derive(Eq, Show)

///|
impl @app.States for Test with debug_name(self) {
  ignore(self)
  "examples.math.bounding_2d.Test"
}

///|
priv struct Spin {}

///|
priv enum Shape {
  Rectangle(@render2d.Rectangle)
  Circle(@render2d.Circle)
  Triangle(@render2d.Triangle2d)
  Line(@render2d.Segment2d)
  Capsule(@render2d.Capsule2d)
  Polygon(@render2d.RegularPolygon)
}

///|
priv enum DesiredVolume {
  Aabb
  Circle
}

///|
priv struct Aabb2dLite {
  center : @math.Vec2
  half_size : @math.Vec2
}

///|
priv struct BoundingCircleLite {
  center : @math.Vec2
  radius : Float
}

///|
priv enum CurrentVolume {
  Aabb(Aabb2dLite)
  Circle(BoundingCircleLite)
}

///|
priv struct Ray2dLite {
  origin : @math.Vec2
  direction : @math.Vec2
}

///|
priv struct RayCast2dLite {
  ray : Ray2dLite
  max : Float
}

///|
priv struct AabbCast2dLite {
  aabb : Aabb2dLite
  ray : RayCast2dLite
}

///|
priv struct BoundingCircleCastLite {
  circle : BoundingCircleLite
  ray : RayCast2dLite
}

///|
let spin_key : @ecs.ComponentKey[Spin] = @ecs.register_component(
  debug_name="examples.math.bounding_2d.Spin",
)

///|
let shape_key : @ecs.ComponentKey[Shape] = @ecs.register_component(
  debug_name="examples.math.bounding_2d.Shape",
)

///|
let desired_volume_key : @ecs.ComponentKey[DesiredVolume] = @ecs.register_component(
  debug_name="examples.math.bounding_2d.DesiredVolume",
)

///|
let current_volume_key : @ecs.ComponentKey[CurrentVolume] = @ecs.register_component(
  debug_name="examples.math.bounding_2d.CurrentVolume",
)

///|
let intersects_key : @ecs.ComponentKey[Bool] = @ecs.register_component(
  debug_name="examples.math.bounding_2d.Intersects",
)

///|
let overlay_text_handle : Ref[@text.TextHandle?] = Ref::new(None)

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugin(@app.states_plugin(@app.StatesPlugin::default()))
  .insert_state(Test::RayCast)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(update_text))
  .add_systems(@app.Update, @app.system(spin))
  .add_systems(@app.Update, @app.system(update_test_state))
  .add_systems(
    @app.PostUpdate,
    @app.system(update_volumes).in_set(SYSTEM_SET_UPDATE_VOLUMES),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(render_shapes)
    .after(SYSTEM_SET_UPDATE_VOLUMES)
    .in_set(SYSTEM_SET_RENDER_SHAPES),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(aabb_intersection_system)
    .after(SYSTEM_SET_RENDER_SHAPES)
    .before(SYSTEM_SET_RENDER_VOLUMES)
    .run_if(@app.in_state(Test::AabbSweep)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(circle_intersection_system)
    .after(SYSTEM_SET_RENDER_SHAPES)
    .before(SYSTEM_SET_RENDER_VOLUMES)
    .run_if(@app.in_state(Test::CircleSweep)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(ray_cast_system)
    .after(SYSTEM_SET_RENDER_SHAPES)
    .before(SYSTEM_SET_RENDER_VOLUMES)
    .run_if(@app.in_state(Test::RayCast)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(aabb_cast_system)
    .after(SYSTEM_SET_RENDER_SHAPES)
    .before(SYSTEM_SET_RENDER_VOLUMES)
    .run_if(@app.in_state(Test::AabbCast)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(bounding_circle_cast_system)
    .after(SYSTEM_SET_RENDER_SHAPES)
    .before(SYSTEM_SET_RENDER_VOLUMES)
    .run_if(@app.in_state(Test::CircleCast)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(render_volumes).in_set(SYSTEM_SET_RENDER_VOLUMES),
  )
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  overlay_text_handle.val = None

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  spawn_shape_entity(
    world,
    @math.Transform::from_xyz(-OFFSET_X, OFFSET_Y, 0.0F),
    Shape::Circle(@render2d.Circle::new(45.0F)),
    DesiredVolume::Aabb,
    false,
  )

  spawn_shape_entity(
    world,
    @math.Transform::from_xyz(0.0F, OFFSET_Y, 0.0F),
    Shape::Rectangle(@render2d.Rectangle::new(80.0F, 80.0F)),
    DesiredVolume::Circle,
    true,
  )

  spawn_shape_entity(
    world,
    @math.Transform::from_xyz(OFFSET_X, OFFSET_Y, 0.0F),
    Shape::Triangle(
      @render2d.Triangle2d::new(
        @math.Vec2::new(-40.0F, -40.0F),
        @math.Vec2::new(-20.0F, 40.0F),
        @math.Vec2::new(40.0F, 50.0F),
      ),
    ),
    DesiredVolume::Aabb,
    true,
  )

  let line_direction = normalize_or_fallback(@math.Vec2::new(1.0F, 0.3F))
  let half_line = line_direction.mul_scalar(45.0F)
  spawn_shape_entity(
    world,
    @math.Transform::from_xyz(-OFFSET_X, -OFFSET_Y, 0.0F),
    Shape::Line(
      @render2d.Segment2d::new(
        @math.Vec2::new(-half_line.x, -half_line.y),
        @math.Vec2::new(half_line.x, half_line.y),
      ),
    ),
    DesiredVolume::Circle,
    true,
  )

  spawn_shape_entity(
    world,
    @math.Transform::from_xyz(0.0F, -OFFSET_Y, 0.0F),
    Shape::Capsule(@render2d.Capsule2d::new(25.0F, 50.0F, 16)),
    DesiredVolume::Aabb,
    true,
  )

  spawn_shape_entity(
    world,
    @math.Transform::from_xyz(OFFSET_X, -OFFSET_Y, 0.0F),
    Shape::Polygon(@render2d.RegularPolygon::new(50.0F, 6)),
    DesiredVolume::Circle,
    true,
  )

  spawn_help_overlay(world)
}

///|
fn spawn_shape_entity(
  world : @ecs.World,
  transform : @math.Transform,
  shape : Shape,
  desired_volume : DesiredVolume,
  spinning : Bool,
) -> Unit {
  let tick = world.read_change_tick()
  let entity = world.spawn_empty()
  world.component(@math.Transform::component()).insert(entity, transform, tick)
  world.component(shape_key).insert(entity, shape, tick)
  world.component(desired_volume_key).insert(entity, desired_volume, tick)
  world.component(intersects_key).insert(entity, false, tick)
  if spinning {
    world.component(spin_key).insert(entity, Spin::{  }, tick)
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
fn spawn_help_overlay(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = spawn_ui_text_handle(
    overlay_text(read_current_test(world)),
    font,
    18.0F,
    color_white(),
  )
  overlay_text_handle.val = Some(text_handle)

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
  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn update_test_state(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }

  let current = read_current_test(world)
  let next = match current {
    Test::AabbSweep => Test::CircleSweep
    Test::CircleSweep => Test::RayCast
    Test::RayCast => Test::AabbCast
    Test::AabbCast => Test::CircleCast
    Test::CircleCast => Test::AabbSweep
  }
  @app.set_state(next)
}

///|
fn update_text(world : @ecs.World) -> Unit {
  if overlay_text_handle.val is Some(text_handle) {
    @text.text_set_content(text_handle, overlay_text(read_current_test(world)))
  }
}

///|
fn overlay_text(current : Test) -> String {
  let tests : Array[Test] = [
    Test::AabbSweep,
    Test::CircleSweep,
    Test::RayCast,
    Test::AabbCast,
    Test::CircleCast,
  ]
  let mut content = "Intersection test:\n"
  for test_case in tests {
    let marker = if current == test_case { "*" } else { " " }
    content = content +
      " " +
      marker +
      " " +
      test_name(test_case) +
      " " +
      marker +
      "\n"
  }
  content + "\nPress space to cycle"
}

///|
fn test_name(test_case : Test) -> String {
  match test_case {
    Test::AabbSweep => "AabbSweep"
    Test::CircleSweep => "CircleSweep"
    Test::RayCast => "RayCast"
    Test::AabbCast => "AabbCast"
    Test::CircleCast => "CircleCast"
  }
}

///|
fn read_current_test(world : @ecs.World) -> Test {
  match @app.world_state(world, Test::RayCast) {
    Some(state) => state.get()
    None => Test::RayCast
  }
}

///|
fn spin(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(@time.default_time_resource_key()))
    is Some(time) else {
    return
  }

  let rotation_step = @math.Quat::from_rotation_z(time.delta_secs() / 5.0F)
  let query = world.query2_value_mut_filtered(
    spin_key,
    @math.Transform::component(),
    @ecs.All::new(),
  )
  try! query.view_mut(fn(_entity, _spin, transform) {
    let next = transform.get_ref().val.rotation.mul(rotation_step).normalize()
    transform.get_ref().val.rotation = next
  })
}

///|
fn update_volumes(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let volumes = world.component(current_volume_key)
  let query = world.query3(
    desired_volume_key,
    shape_key,
    @math.Transform::component(),
  )
  try! query.view(fn(entity, desired_volume, shape, transform) {
    let isometry = transform_isometry(transform)
    let volume = match desired_volume {
      DesiredVolume::Aabb => CurrentVolume::Aabb(shape_aabb(shape, isometry))
      DesiredVolume::Circle =>
        CurrentVolume::Circle(shape_bounding_circle(shape, isometry))
    }
    volumes.upsert(entity, volume, tick)
  })
}

///|
fn render_shapes(world : @ecs.World) -> Unit {
  let gizmos = @render2d.Gizmos::new()
  let query = world.query2(shape_key, @math.Transform::component())
  try! query.view(fn(_entity, shape, transform) {
    draw_shape_outline(
      gizmos,
      shape,
      transform_isometry(transform),
      color_gray(),
    )
  })
}

///|
fn render_volumes(world : @ecs.World) -> Unit {
  let gizmos = @render2d.Gizmos::new()
  let query = world.query2(current_volume_key, intersects_key)
  try! query.view(fn(_entity, volume, intersects) {
    let color = if intersects { color_aqua() } else { color_orange_red() }
    match volume {
      CurrentVolume::Aabb(aabb) =>
        gizmos.rect_2d(
          @render2d.Isometry2d::new(aabb.center, 0.0F),
          aabb.half_size.mul_scalar(2.0F),
          color,
        )
      CurrentVolume::Circle(circle) =>
        gizmos.circle_2d(
          @render2d.Isometry2d::new(circle.center, 0.0F),
          circle.radius,
          color,
        )
        |> ignore
    }
  })
}

///|
fn aabb_intersection_system(world : @ecs.World) -> Unit {
  guard world_time(world) is Some(time) else { return }

  let center = get_intersection_position(time)
  let aabb = { center, half_size: @math.Vec2::new(50.0F, 50.0F) }
  let gizmos = @render2d.Gizmos::new()
  gizmos.rect_2d(
    @render2d.Isometry2d::new(center, 0.0F),
    aabb.half_size.mul_scalar(2.0F),
    color_yellow(),
  )

  let query = world.query2_value_mut_filtered(
    current_volume_key,
    intersects_key,
    @ecs.All::new(),
  )
  try! query.view_mut(fn(_entity, volume, intersects) {
    let hit = match volume {
      CurrentVolume::Aabb(other) => aabb_intersects_aabb(aabb, other)
      CurrentVolume::Circle(circle) => aabb_intersects_circle(aabb, circle)
    }
    intersects.get_ref().val = hit
  })
}

///|
fn circle_intersection_system(world : @ecs.World) -> Unit {
  guard world_time(world) is Some(time) else { return }

  let center = get_intersection_position(time)
  let circle = { center, radius: 50.0F }
  let gizmos = @render2d.Gizmos::new()
  gizmos.circle_2d(
    @render2d.Isometry2d::new(center, 0.0F),
    circle.radius,
    color_yellow(),
  )
  |> ignore

  let query = world.query2_value_mut_filtered(
    current_volume_key,
    intersects_key,
    @ecs.All::new(),
  )
  try! query.view_mut(fn(_entity, volume, intersects) {
    let hit = match volume {
      CurrentVolume::Aabb(aabb) => aabb_intersects_circle(aabb, circle)
      CurrentVolume::Circle(other) => circle_intersects_circle(circle, other)
    }
    intersects.get_ref().val = hit
  })
}

///|
fn ray_cast_system(world : @ecs.World) -> Unit {
  guard world_time(world) is Some(time) else { return }

  let gizmos = @render2d.Gizmos::new()
  let ray_cast = get_and_draw_ray(gizmos, time)
  let query = world.query2_value_mut_filtered(
    current_volume_key,
    intersects_key,
    @ecs.All::new(),
  )
  try! query.view_mut(fn(_entity, volume, intersects) {
    let toi = match volume {
      CurrentVolume::Aabb(aabb) => ray_cast_aabb_intersection_at(ray_cast, aabb)
      CurrentVolume::Circle(circle) =>
        ray_cast_circle_intersection_at(ray_cast, circle)
    }
    intersects.get_ref().val = toi is Some(_)
    if toi is Some(hit_time) {
      draw_filled_circle(
        gizmos,
        ray_point_at(ray_cast.ray, hit_time),
        color_lime(),
      )
    }
  })
}

///|
fn aabb_cast_system(world : @ecs.World) -> Unit {
  guard world_time(world) is Some(time) else { return }

  let gizmos = @render2d.Gizmos::new()
  let ray_cast = get_and_draw_ray(gizmos, time)
  let cast = AabbCast2dLite::{
    aabb: {
      center: @math.Vec2::zero(),
      half_size: @math.Vec2::new(15.0F, 15.0F),
    },
    ray: ray_cast,
  }

  let query = world.query2_value_mut_filtered(
    current_volume_key,
    intersects_key,
    @ecs.All::new(),
  )
  try! query.view_mut(fn(_entity, volume, intersects) {
    let toi = match volume {
      CurrentVolume::Aabb(aabb) => aabb_cast_collision_at(cast, aabb)
      CurrentVolume::Circle(_) => None
    }
    intersects.get_ref().val = toi is Some(_)
    if toi is Some(hit_time) {
      let center = ray_point_at(cast.ray.ray, hit_time)
      let hit_aabb = Aabb2dLite::{ center, half_size: cast.aabb.half_size }
      gizmos.rect_2d(
        @render2d.Isometry2d::new(hit_aabb.center, 0.0F),
        hit_aabb.half_size.mul_scalar(2.0F),
        color_lime(),
      )
    }
  })
}

///|
fn bounding_circle_cast_system(world : @ecs.World) -> Unit {
  guard world_time(world) is Some(time) else { return }

  let gizmos = @render2d.Gizmos::new()
  let ray_cast = get_and_draw_ray(gizmos, time)
  let cast = BoundingCircleCastLite::{
    circle: { center: @math.Vec2::zero(), radius: 15.0F },
    ray: ray_cast,
  }

  let query = world.query2_value_mut_filtered(
    current_volume_key,
    intersects_key,
    @ecs.All::new(),
  )
  try! query.view_mut(fn(_entity, volume, intersects) {
    let toi = match volume {
      CurrentVolume::Aabb(_) => None
      CurrentVolume::Circle(circle) => circle_cast_collision_at(cast, circle)
    }
    intersects.get_ref().val = toi is Some(_)
    if toi is Some(hit_time) {
      let center = ray_point_at(cast.ray.ray, hit_time)
      gizmos.circle_2d(
        @render2d.Isometry2d::new(center, 0.0F),
        cast.circle.radius,
        color_lime(),
      )
      |> ignore
    }
  })
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit]? {
  try! world.get_resource(@time.default_time_resource_key())
}

///|
fn get_and_draw_ray(
  gizmos : @render2d.Gizmos,
  time : @time.Time[Unit],
) -> RayCast2dLite {
  let elapsed = time.elapsed_secs()
  let ray_direction = @math.Vec2::new(@math.cos(elapsed), @math.sin(elapsed))
  let distance = 150.0F + absf(@math.sin(0.5F * elapsed)) * 500.0F
  let ray = Ray2dLite::{
    origin: ray_direction.mul_scalar(250.0F),
    direction: normalize_or_fallback(ray_direction.mul_scalar(-1.0F)),
  }
  let ray_cast = RayCast2dLite::{ ray, max: distance - 20.0F }

  gizmos.line_2d(
    ray_cast.ray.origin,
    ray_cast.ray.origin.add(ray_cast.ray.direction.mul_scalar(ray_cast.max)),
    color_white(),
  )
  draw_filled_circle(gizmos, ray_cast.ray.origin, color_fuchsia())
  ray_cast
}

///|
fn get_intersection_position(time : @time.Time[Unit]) -> @math.Vec2 {
  @math.Vec2::new(
    @math.cos(0.8F * time.elapsed_secs()) * 250.0F,
    @math.sin(0.4F * time.elapsed_secs()) * 100.0F,
  )
}

///|
fn transform_isometry(transform : @math.Transform) -> @render2d.Isometry2d {
  @render2d.Isometry2d::new(
    @math.Vec2::new(transform.translation.x, transform.translation.y),
    transform.rotation_z(),
  )
}

///|
fn draw_shape_outline(
  gizmos : @render2d.Gizmos,
  shape : Shape,
  isometry : @render2d.Isometry2d,
  color : @render2d.Color,
) -> Unit {
  match shape {
    Shape::Rectangle(rectangle) =>
      gizmos.rect_2d(isometry, rectangle.half_size.mul_scalar(2.0F), color)
    Shape::Circle(circle) =>
      gizmos.circle_2d(isometry, circle.radius, color) |> ignore
    Shape::Triangle(triangle) =>
      gizmos.lineloop_2d(
        transformed_points([triangle.a, triangle.b, triangle.c], isometry),
        color,
      )
    Shape::Line(line) =>
      gizmos.line_2d(
        isometry.transform_point(line.start),
        isometry.transform_point(line.end),
        color,
      )
    Shape::Capsule(capsule) =>
      gizmos.lineloop_2d(
        transformed_points(capsule_points_local(capsule), isometry),
        color,
      )
    Shape::Polygon(polygon) =>
      gizmos.lineloop_2d(
        transformed_points(polygon_points_local(polygon), isometry),
        color,
      )
  }
}

///|
fn shape_aabb(shape : Shape, isometry : @render2d.Isometry2d) -> Aabb2dLite {
  match shape {
    Shape::Circle(circle) =>
      Aabb2dLite::{
        center: isometry.translation,
        half_size: @math.Vec2::new(circle.radius, circle.radius),
      }
    _ =>
      aabb_from_points(transformed_points(shape_points_local(shape), isometry))
  }
}

///|
fn shape_bounding_circle(
  shape : Shape,
  isometry : @render2d.Isometry2d,
) -> BoundingCircleLite {
  match shape {
    Shape::Circle(circle) =>
      BoundingCircleLite::{
        center: isometry.translation,
        radius: circle.radius,
      }
    _ =>
      minimal_bounding_circle(
        transformed_points(shape_points_local(shape), isometry),
      )
  }
}

///|
fn shape_points_local(shape : Shape) -> Array[@math.Vec2] {
  match shape {
    Shape::Rectangle(rectangle) => rectangle_points_local(rectangle)
    Shape::Circle(circle) => circle_points_local(circle.radius)
    Shape::Triangle(triangle) => [triangle.a, triangle.b, triangle.c]
    Shape::Line(line) => [line.start, line.end]
    Shape::Capsule(capsule) => capsule_points_local(capsule)
    Shape::Polygon(polygon) => polygon_points_local(polygon)
  }
}

///|
fn rectangle_points_local(rectangle : @render2d.Rectangle) -> Array[@math.Vec2] {
  let half = rectangle.half_size
  [
    @math.Vec2::new(-half.x, -half.y),
    @math.Vec2::new(half.x, -half.y),
    @math.Vec2::new(half.x, half.y),
    @math.Vec2::new(-half.x, half.y),
  ]
}

///|
fn circle_points_local(radius : Float) -> Array[@math.Vec2] {
  let points : Array[@math.Vec2] = []
  for i in 0..<OUTLINE_SAMPLES {
    let t = int_to_float(i) / int_to_float(OUTLINE_SAMPLES)
    let angle = t * 2.0F * @math.pi()
    points.push(
      @math.Vec2::new(@math.cos(angle) * radius, @math.sin(angle) * radius),
    )
  }
  points
}

///|
fn polygon_points_local(
  polygon : @render2d.RegularPolygon,
) -> Array[@math.Vec2] {
  let safe_sides = if polygon.sides < 3 { 3 } else { polygon.sides }
  let points : Array[@math.Vec2] = []
  for i in 0..<safe_sides {
    let angle = @math.pi_half() +
      2.0F * @math.pi() * int_to_float(i) / int_to_float(safe_sides)
    points.push(
      @math.Vec2::new(
        @math.cos(angle) * polygon.radius,
        @math.sin(angle) * polygon.radius,
      ),
    )
  }
  points
}

///|
fn capsule_points_local(capsule : @render2d.Capsule2d) -> Array[@math.Vec2] {
  let arc_segments = if capsule.segments < 12 { 12 } else { capsule.segments }
  let points : Array[@math.Vec2] = []
  for i in 0..<=arc_segments {
    let t = int_to_float(i) / int_to_float(arc_segments)
    let angle = t * @math.pi()
    points.push(
      @math.Vec2::new(
        @math.cos(angle) * capsule.radius,
        @math.sin(angle) * capsule.radius + capsule.half_length,
      ),
    )
  }
  for i in 0..<=arc_segments {
    let t = int_to_float(i) / int_to_float(arc_segments)
    let angle = @math.pi() + t * @math.pi()
    points.push(
      @math.Vec2::new(
        @math.cos(angle) * capsule.radius,
        @math.sin(angle) * capsule.radius - capsule.half_length,
      ),
    )
  }
  points
}

///|
fn transformed_points(
  points : Array[@math.Vec2],
  isometry : @render2d.Isometry2d,
) -> Array[@math.Vec2] {
  let transformed : Array[@math.Vec2] = []
  for point in points {
    transformed.push(isometry.transform_point(point))
  }
  transformed
}

///|
fn aabb_from_points(points : Array[@math.Vec2]) -> Aabb2dLite {
  guard points.length() > 0 else {
    return Aabb2dLite::{
      center: @math.Vec2::zero(),
      half_size: @math.Vec2::zero(),
    }
  }

  let first = points[0]
  let mut min_x = first.x
  let mut max_x = first.x
  let mut min_y = first.y
  let mut max_y = first.y

  for point in points {
    min_x = minf(min_x, point.x)
    max_x = maxf(max_x, point.x)
    min_y = minf(min_y, point.y)
    max_y = maxf(max_y, point.y)
  }

  let min_point = @math.Vec2::new(min_x, min_y)
  let max_point = @math.Vec2::new(max_x, max_y)
  Aabb2dLite::{
    center: min_point.add(max_point).mul_scalar(0.5F),
    half_size: max_point.sub(min_point).mul_scalar(0.5F),
  }
}

///|
fn minimal_bounding_circle(points : Array[@math.Vec2]) -> BoundingCircleLite {
  guard points.length() > 0 else {
    return BoundingCircleLite::{ center: @math.Vec2::zero(), radius: 0.0F }
  }

  let mut best : BoundingCircleLite? = None
  for point in points {
    let candidate = BoundingCircleLite::{ center: point, radius: 0.0F }
    if circle_contains_all(candidate, points) {
      best = choose_smaller_circle(best, candidate)
    }
  }

  for i in 0..<points.length() {
    for j in (i + 1)..<points.length() {
      let candidate = circle_from_diameter(points[i], points[j])
      if circle_contains_all(candidate, points) {
        best = choose_smaller_circle(best, candidate)
      }
    }
  }

  for i in 0..<points.length() {
    for j in (i + 1)..<points.length() {
      for k in (j + 1)..<points.length() {
        if circumcircle(points[i], points[j], points[k]) is Some(candidate) {
          if circle_contains_all(candidate, points) {
            best = choose_smaller_circle(best, candidate)
          }
        }
      }
    }
  }

  match best {
    Some(circle) => circle
    None => {
      let aabb = aabb_from_points(points)
      let mut radius = 0.0F
      for point in points {
        radius = maxf(radius, point.sub(aabb.center).length())
      }
      BoundingCircleLite::{ center: aabb.center, radius }
    }
  }
}

///|
fn choose_smaller_circle(
  current : BoundingCircleLite?,
  candidate : BoundingCircleLite,
) -> BoundingCircleLite? {
  match current {
    Some(best) =>
      if candidate.radius < best.radius {
        Some(candidate)
      } else {
        Some(best)
      }
    None => Some(candidate)
  }
}

///|
fn circle_from_diameter(a : @math.Vec2, b : @math.Vec2) -> BoundingCircleLite {
  let center = a.add(b).mul_scalar(0.5F)
  BoundingCircleLite::{ center, radius: a.sub(center).length() }
}

///|
fn circumcircle(
  a : @math.Vec2,
  b : @math.Vec2,
  c : @math.Vec2,
) -> BoundingCircleLite? {
  let ax = a.x
  let ay = a.y
  let bx = b.x
  let by = b.y
  let cx = c.x
  let cy = c.y
  let divisor = 2.0F * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
  if absf(divisor) < 0.00001F {
    return None
  }

  let a_sq = ax * ax + ay * ay
  let b_sq = bx * bx + by * by
  let c_sq = cx * cx + cy * cy
  let center = @math.Vec2::new(
    (a_sq * (by - cy) + b_sq * (cy - ay) + c_sq * (ay - by)) / divisor,
    (a_sq * (cx - bx) + b_sq * (ax - cx) + c_sq * (bx - ax)) / divisor,
  )
  Some(BoundingCircleLite::{ center, radius: a.sub(center).length() })
}

///|
fn circle_contains_all(
  circle : BoundingCircleLite,
  points : Array[@math.Vec2],
) -> Bool {
  let max_distance_squared = circle.radius * circle.radius + 0.001F
  for point in points {
    if point.sub(circle.center).length_squared() > max_distance_squared {
      return false
    }
  }
  true
}

///|
fn aabb_intersects_aabb(a : Aabb2dLite, b : Aabb2dLite) -> Bool {
  absf(a.center.x - b.center.x) <= a.half_size.x + b.half_size.x &&
  absf(a.center.y - b.center.y) <= a.half_size.y + b.half_size.y
}

///|
fn aabb_intersects_circle(
  aabb : Aabb2dLite,
  circle : BoundingCircleLite,
) -> Bool {
  let min_point = aabb.center.sub(aabb.half_size)
  let max_point = aabb.center.add(aabb.half_size)
  let closest = @math.Vec2::new(
    clampf(circle.center.x, min_point.x, max_point.x),
    clampf(circle.center.y, min_point.y, max_point.y),
  )
  closest.sub(circle.center).length_squared() <= circle.radius * circle.radius
}

///|
fn circle_intersects_circle(
  a : BoundingCircleLite,
  b : BoundingCircleLite,
) -> Bool {
  let radius_sum = a.radius + b.radius
  a.center.sub(b.center).length_squared() <= radius_sum * radius_sum
}

///|
fn ray_point_at(ray : Ray2dLite, distance : Float) -> @math.Vec2 {
  ray.origin.add(ray.direction.mul_scalar(distance))
}

///|
fn ray_cast_aabb_intersection_at(
  ray_cast : RayCast2dLite,
  aabb : Aabb2dLite,
) -> Float? {
  let min_point = aabb.center.sub(aabb.half_size)
  let max_point = aabb.center.add(aabb.half_size)
  guard ray_axis_interval(
      ray_cast.ray.origin.x,
      ray_cast.ray.direction.x,
      min_point.x,
      max_point.x,
      0.0F,
      ray_cast.max,
    )
    is Some((x_min, x_max)) else {
    return None
  }
  guard ray_axis_interval(
      ray_cast.ray.origin.y,
      ray_cast.ray.direction.y,
      min_point.y,
      max_point.y,
      x_min,
      x_max,
    )
    is Some((y_min, _y_max)) else {
    return None
  }
  Some(y_min)
}

///|
fn ray_axis_interval(
  origin : Float,
  direction : Float,
  min_value : Float,
  max_value : Float,
  t_min : Float,
  t_max : Float,
) -> (Float, Float)? {
  if absf(direction) < 0.00001F {
    return if origin >= min_value && origin <= max_value {
      Some((t_min, t_max))
    } else {
      None
    }
  }

  let inverse = 1.0F / direction
  let mut first = (min_value - origin) * inverse
  let mut second = (max_value - origin) * inverse
  if first > second {
    let temp = first
    first = second
    second = temp
  }

  let next_min = maxf(t_min, first)
  let next_max = minf(t_max, second)
  if next_max >= next_min && next_max >= 0.0F {
    Some((next_min, next_max))
  } else {
    None
  }
}

///|
fn ray_cast_circle_intersection_at(
  ray_cast : RayCast2dLite,
  circle : BoundingCircleLite,
) -> Float? {
  let to_origin = ray_cast.ray.origin.sub(circle.center)
  let c = to_origin.length_squared() - circle.radius * circle.radius
  if c <= 0.0F {
    return Some(0.0F)
  }

  let b = to_origin.dot(ray_cast.ray.direction)
  let discriminant = b * b - c
  if discriminant < 0.0F {
    return None
  }

  let root = @math.sqrt(discriminant)
  let first = -b - root
  if first >= 0.0F && first <= ray_cast.max {
    return Some(first)
  }

  let second = -b + root
  if second >= 0.0F && second <= ray_cast.max {
    return Some(second)
  }
  None
}

///|
fn aabb_cast_collision_at(cast : AabbCast2dLite, target : Aabb2dLite) -> Float? {
  let expanded = Aabb2dLite::{
    center: target.center,
    half_size: target.half_size.add(cast.aabb.half_size),
  }
  ray_cast_aabb_intersection_at(
    RayCast2dLite::{
      ray: Ray2dLite::{
        origin: cast.ray.ray.origin.add(cast.aabb.center),
        direction: cast.ray.ray.direction,
      },
      max: cast.ray.max,
    },
    expanded,
  )
}

///|
fn circle_cast_collision_at(
  cast : BoundingCircleCastLite,
  target : BoundingCircleLite,
) -> Float? {
  ray_cast_circle_intersection_at(
    RayCast2dLite::{
      ray: Ray2dLite::{
        origin: cast.ray.ray.origin.add(cast.circle.center),
        direction: cast.ray.ray.direction,
      },
      max: cast.ray.max,
    },
    BoundingCircleLite::{
      center: target.center,
      radius: target.radius + cast.circle.radius,
    },
  )
}

///|
fn draw_filled_circle(
  gizmos : @render2d.Gizmos,
  position : @math.Vec2,
  color : @render2d.Color,
) -> Unit {
  gizmos.circle_2d(@render2d.Isometry2d::new(position, 0.0F), 1.0F, color)
  |> ignore
  gizmos.circle_2d(@render2d.Isometry2d::new(position, 0.0F), 2.0F, color)
  |> ignore
  gizmos.circle_2d(@render2d.Isometry2d::new(position, 0.0F), 3.0F, color)
  |> ignore
}

///|
fn normalize_or_fallback(vector : @math.Vec2) -> @math.Vec2 {
  let normalized = vector.normalize_or_zero()
  if normalized.length_squared() == 0.0F {
    @math.Vec2::new(1.0F, 0.0F)
  } else {
    normalized
  }
}

///|
fn int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
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
fn minf(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn color_gray() -> @render2d.Color {
  @render2d.Color::new(0.5F, 0.5F, 0.5F, 1.0F)
}

///|
fn color_aqua() -> @render2d.Color {
  @render2d.Color::new(0.0F, 1.0F, 1.0F, 1.0F)
}

///|
fn color_orange_red() -> @render2d.Color {
  @render2d.Color::new(1.0F, 0.27058825F, 0.0F, 1.0F)
}

///|
fn color_yellow() -> @render2d.Color {
  @render2d.Color::new(1.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_white() -> @render2d.Color {
  @render2d.Color::white()
}

///|
fn color_fuchsia() -> @render2d.Color {
  @render2d.Color::new(1.0F, 0.0F, 1.0F, 1.0F)
}

///|
fn color_lime() -> @render2d.Color {
  @render2d.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
}
