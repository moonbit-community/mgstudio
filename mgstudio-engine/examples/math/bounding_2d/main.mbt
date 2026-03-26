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
const OFFSET_X : Float = 125.0F

///|
const OFFSET_Y : Float = 75.0F

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
  Rectangle(@sprite.Rectangle)
  Circle(@sprite.Circle)
  Triangle(@sprite.Triangle2d)
  Line(@sprite.Segment2d)
  Capsule(@sprite.Capsule2d)
  Polygon(@sprite.RegularPolygon)
}

///|
priv enum DesiredVolume {
  Aabb
  Circle
}

///|
priv enum CurrentVolume {
  Aabb(@math.Aabb2d)
  Circle(@math.BoundingCircle)
}

///|
priv struct VolumeIntersectionData {
  volume : CurrentVolume
  intersects : Bool
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
impl @ecs.Component for Spin with component() {
  spin_key
}

///|
impl @ecs.Component for Shape with component() {
  shape_key
}

///|
impl @ecs.Component for DesiredVolume with component() {
  desired_volume_key
}

///|
impl @ecs.QueryData for VolumeIntersectionData with matches(world, entity) {
  @ecs.query_data_component_matches(world, entity, current_volume_key) &&
  @ecs.query_data_component_matches(world, entity, intersects_key)
}

///|
impl @ecs.QueryData for VolumeIntersectionData with fetch(world, entity) {
  {
    volume: try! @ecs.query_data_component_fetch(
      world, entity, current_volume_key,
    ),
    intersects: (try! world.get_by_key(entity, intersects_key)).unwrap(),
  }
}

///|
impl @ecs.QueryData for VolumeIntersectionData with mentions_component(
  component_id,
) {
  component_id == current_volume_key.id() || component_id == intersects_key.id()
}

///|
impl @ecs.QueryData for VolumeIntersectionData with iteration_anchor_component() {
  Some(current_volume_key.id())
}

///|
impl @ecs.QueryData for VolumeIntersectionData with contiguous_compatible() {
  true
}

///|
let overlay_text_entity : Ref[@core.Entity?] = Ref::new(None)

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
    @app.system(@app.system_param(render_shapes))
    .after(SYSTEM_SET_UPDATE_VOLUMES)
    .in_set(SYSTEM_SET_RENDER_SHAPES),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(@app.system_param(aabb_intersection_system))
    .after(SYSTEM_SET_RENDER_SHAPES)
    .before(SYSTEM_SET_RENDER_VOLUMES)
    .run_if(@app.in_state(Test::AabbSweep)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(@app.system_param(circle_intersection_system))
    .after(SYSTEM_SET_RENDER_SHAPES)
    .before(SYSTEM_SET_RENDER_VOLUMES)
    .run_if(@app.in_state(Test::CircleSweep)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(@app.system_param(ray_cast_system))
    .after(SYSTEM_SET_RENDER_SHAPES)
    .before(SYSTEM_SET_RENDER_VOLUMES)
    .run_if(@app.in_state(Test::RayCast)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(@app.system_param(aabb_cast_system))
    .after(SYSTEM_SET_RENDER_SHAPES)
    .before(SYSTEM_SET_RENDER_VOLUMES)
    .run_if(@app.in_state(Test::AabbCast)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(@app.system_param(bounding_circle_cast_system))
    .after(SYSTEM_SET_RENDER_SHAPES)
    .before(SYSTEM_SET_RENDER_VOLUMES)
    .run_if(@app.in_state(Test::CircleCast)),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(@app.system_param(render_volumes)).in_set(
      SYSTEM_SET_RENDER_VOLUMES,
    ),
  )
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  overlay_text_entity.val = None

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  spawn_shape_entity(
    world,
    @transform.Transform::from_xyz(-OFFSET_X, OFFSET_Y, 0.0F),
    Shape::Circle(@sprite.Circle::new(45.0F)),
    DesiredVolume::Aabb,
    false,
  )

  spawn_shape_entity(
    world,
    @transform.Transform::from_xyz(0.0F, OFFSET_Y, 0.0F),
    Shape::Rectangle(@sprite.Rectangle::new(80.0F, 80.0F)),
    DesiredVolume::Circle,
    true,
  )

  spawn_shape_entity(
    world,
    @transform.Transform::from_xyz(OFFSET_X, OFFSET_Y, 0.0F),
    Shape::Triangle(
      @sprite.Triangle2d::new(
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
    @transform.Transform::from_xyz(-OFFSET_X, -OFFSET_Y, 0.0F),
    Shape::Line(
      @sprite.Segment2d::new(
        @math.Vec2::new(-half_line.x, -half_line.y),
        @math.Vec2::new(half_line.x, half_line.y),
      ),
    ),
    DesiredVolume::Circle,
    true,
  )

  spawn_shape_entity(
    world,
    @transform.Transform::from_xyz(0.0F, -OFFSET_Y, 0.0F),
    Shape::Capsule(@sprite.Capsule2d::new(25.0F, 100.0F).with_segments(16)),
    DesiredVolume::Aabb,
    true,
  )

  spawn_shape_entity(
    world,
    @transform.Transform::from_xyz(OFFSET_X, -OFFSET_Y, 0.0F),
    Shape::Polygon(@sprite.RegularPolygon::new(50.0F, 6)),
    DesiredVolume::Circle,
    true,
  )

  spawn_help_overlay(world)
}

///|
fn spawn_shape_entity(
  world : @ecs.World,
  transform : @transform.Transform,
  shape : Shape,
  desired_volume : DesiredVolume,
  spinning : Bool,
) -> Unit {
  let entity = world.spawn_empty()
  try! world.set_by_key(entity, @transform.Transform::component(), transform)
  try! world.set_by_key(entity, shape_key, shape)
  try! world.set_by_key(entity, desired_volume_key, desired_volume)
  try! world.set_by_key(entity, intersects_key, false)
  if spinning {
    try! world.set_by_key(entity, spin_key, Spin::{  })
  }
}

///|
fn spawn_help_overlay(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )
  let text_entity = world.spawn_empty()
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(overlay_text(read_current_test(world))),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(18.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(color_white()),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
  overlay_text_entity.val = Some(text_entity)
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
  guard overlay_text_entity.val is Some(text_entity) else { return }
  guard (try! world.get_by_key(text_entity, @text.ecs_key_text))
    is Some(text_value) else {
    return
  }
  text_value.content = overlay_text(read_current_test(world))
  try! world.set_by_key(text_entity, @text.ecs_key_text, text_value)
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
  let updates : Array[(@core.Entity, @math.Quat)] = []
  let query : @ecs.Query[
    (@ecs.Comp[Spin], @ecs.Comp[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    let (_spin, transform) = data
    let next = transform.value().rotation.mul(rotation_step).normalize()
    updates.push((entity, next))
  })
  for update in updates {
    let (entity, next_rotation) = update
    ignore(
      try! world.update_by_key(entity, @transform.Transform::component(), fn(
        transform,
      ) {
        { ..transform, rotation: next_rotation }
      }),
    )
  }
}

///|
fn update_volumes(world : @ecs.World) -> Unit {
  let query : @ecs.Query[
    (
      @ecs.Comp[DesiredVolume],
      @ecs.Comp[Shape],
      @ecs.Comp[@transform.Transform],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    let (desired_volume, shape, transform) = data
    let isometry = transform_math_isometry(transform.value())
    let volume = match desired_volume.value() {
      DesiredVolume::Aabb =>
        CurrentVolume::Aabb(shape_aabb(shape.value(), isometry))
      DesiredVolume::Circle =>
        CurrentVolume::Circle(shape_bounding_circle(shape.value(), isometry))
    }
    try! world.set_by_key(entity, current_volume_key, volume)
  })
}

///|
fn render_shapes(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let query : @ecs.Query[
    (@ecs.Comp[Shape], @ecs.Comp[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(_entity, data) {
    let (shape, transform) = data
    draw_shape_outline(
      gizmos,
      shape.value(),
      transform_sprite_isometry(transform.value()),
      color_gray(),
    )
  })
}

///|
fn render_volumes(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let query : @ecs.Query[VolumeIntersectionData, @ecs.All] = @ecs.query(world)
  try! query.view(fn(_entity, data) {
    let color = if data.intersects { color_aqua() } else { color_orange_red() }
    match data.volume {
      CurrentVolume::Aabb(aabb) =>
        gizmos.rect_2d(
          @sprite.Isometry2d::new(aabb.center(), 0.0F),
          aabb.half_size().mul_scalar(2.0F),
          color,
        )
      CurrentVolume::Circle(circle) =>
        gizmos.circle_2d(
          @sprite.Isometry2d::new(circle.center, 0.0F),
          circle.radius(),
          color,
        )
        |> ignore
    }
  })
}

///|
fn aabb_intersection_system(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let time = world_time(world)

  let center = get_intersection_position(time)
  let aabb = @math.Aabb2d::new(center, @math.Vec2::new(50.0F, 50.0F))
  gizmos.rect_2d(
    @sprite.Isometry2d::new(center, 0.0F),
    aabb.half_size().mul_scalar(2.0F),
    color_yellow(),
  )

  let updates : Array[(@core.Entity, Bool)] = []
  let query : @ecs.Query[VolumeIntersectionData, @ecs.All] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    let hit = match data.volume {
      CurrentVolume::Aabb(other) => aabb.intersects_aabb(other)
      CurrentVolume::Circle(circle) => aabb.intersects_circle(circle)
    }
    updates.push((entity, hit))
  })
  for update in updates {
    let (entity, hit) = update
    try! world.set_by_key(entity, intersects_key, hit)
  }
}

///|
fn circle_intersection_system(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let time = world_time(world)

  let center = get_intersection_position(time)
  let circle = @math.BoundingCircle::new(center, 50.0F)
  gizmos.circle_2d(
    @sprite.Isometry2d::new(center, 0.0F),
    circle.radius(),
    color_yellow(),
  )
  |> ignore

  let updates : Array[(@core.Entity, Bool)] = []
  let query : @ecs.Query[VolumeIntersectionData, @ecs.All] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    let hit = match data.volume {
      CurrentVolume::Aabb(aabb) => aabb.intersects_circle(circle)
      CurrentVolume::Circle(other) => circle.intersects_circle(other)
    }
    updates.push((entity, hit))
  })
  for update in updates {
    let (entity, hit) = update
    try! world.set_by_key(entity, intersects_key, hit)
  }
}

///|
fn ray_cast_system(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let time = world_time(world)

  let ray_cast = get_and_draw_ray(gizmos, time)
  let updates : Array[(@core.Entity, Bool)] = []
  let query : @ecs.Query[VolumeIntersectionData, @ecs.All] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    let toi = match data.volume {
      CurrentVolume::Aabb(aabb) => ray_cast.aabb_intersection_at(aabb)
      CurrentVolume::Circle(circle) => ray_cast.circle_intersection_at(circle)
    }
    updates.push((entity, toi is Some(_)))
    if toi is Some(hit_time) {
      draw_filled_circle(gizmos, ray_cast.ray.get_point(hit_time), color_lime())
    }
  })
  for update in updates {
    let (entity, hit) = update
    try! world.set_by_key(entity, intersects_key, hit)
  }
}

///|
fn aabb_cast_system(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let time = world_time(world)

  let ray_cast = get_and_draw_ray(gizmos, time)
  let cast = @math.AabbCast2d::from_ray(
    @math.Aabb2d::new(@math.Vec2::zero(), @math.Vec2::new(15.0F, 15.0F)),
    ray_cast.ray,
    ray_cast.max,
  )

  let updates : Array[(@core.Entity, Bool)] = []
  let query : @ecs.Query[VolumeIntersectionData, @ecs.All] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    let toi = match data.volume {
      CurrentVolume::Aabb(aabb) => cast.aabb_collision_at(aabb)
      CurrentVolume::Circle(_) => None
    }
    updates.push((entity, toi is Some(_)))
    if toi is Some(hit_time) {
      let center = cast.ray.ray.get_point(hit_time)
      let hit_aabb = @math.Aabb2d::new(center, cast.aabb.half_size())
      gizmos.rect_2d(
        @sprite.Isometry2d::new(hit_aabb.center(), 0.0F),
        hit_aabb.half_size().mul_scalar(2.0F),
        color_lime(),
      )
    }
  })
  for update in updates {
    let (entity, hit) = update
    try! world.set_by_key(entity, intersects_key, hit)
  }
}

///|
fn bounding_circle_cast_system(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let time = world_time(world)

  let ray_cast = get_and_draw_ray(gizmos, time)
  let cast = @math.BoundingCircleCast::from_ray(
    @math.BoundingCircle::new(@math.Vec2::zero(), 15.0F),
    ray_cast.ray,
    ray_cast.max,
  )

  let updates : Array[(@core.Entity, Bool)] = []
  let query : @ecs.Query[VolumeIntersectionData, @ecs.All] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    let toi = match data.volume {
      CurrentVolume::Aabb(_) => None
      CurrentVolume::Circle(circle) => cast.circle_collision_at(circle)
    }
    updates.push((entity, toi is Some(_)))
    if toi is Some(hit_time) {
      let center = cast.ray.ray.get_point(hit_time)
      gizmos.circle_2d(
        @sprite.Isometry2d::new(center, 0.0F),
        cast.circle.radius(),
        color_lime(),
      )
      |> ignore
    }
  })
  for update in updates {
    let (entity, hit) = update
    try! world.set_by_key(entity, intersects_key, hit)
  }
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in bounding_2d example")
  }
}

///|
fn get_and_draw_ray(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
  time : @time.Time[Unit],
) -> @math.RayCast2d {
  let elapsed = time.elapsed_secs()
  let ray_direction = @math.Vec2::new(@math.cos(elapsed), @math.sin(elapsed))
  let distance = 150.0F + absf(@math.sin(0.5F * elapsed)) * 500.0F
  let ray = @math.Ray2d::new(
    ray_direction.mul_scalar(250.0F),
    direction_or_fallback(ray_direction.mul_scalar(-1.0F)),
  )
  let ray_cast = @math.RayCast2d::from_ray(ray, distance - 20.0F)

  gizmos.line_2d(
    ray_cast.ray.origin,
    ray_cast.ray.get_point(ray_cast.max),
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
fn transform_math_isometry(
  transform : @transform.Transform,
) -> @math.Isometry2d {
  @math.Isometry2d::new(
    @math.Vec2::new(transform.translation.x, transform.translation.y),
    @math.Rot2::radians(transform.rotation_z()),
  )
}

///|
fn transform_sprite_isometry(
  transform : @transform.Transform,
) -> @sprite.Isometry2d {
  @sprite.Isometry2d::new(
    @math.Vec2::new(transform.translation.x, transform.translation.y),
    transform.rotation_z(),
  )
}

///|
fn draw_shape_outline(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
  shape : Shape,
  isometry : @sprite.Isometry2d,
  color : @sprite.Color,
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
fn shape_aabb(shape : Shape, isometry : @math.Isometry2d) -> @math.Aabb2d {
  match shape {
    Shape::Rectangle(rectangle) => rectangle.aabb_2d(isometry)
    Shape::Circle(circle) => circle.aabb_2d(isometry)
    Shape::Triangle(triangle) => triangle.aabb_2d(isometry)
    Shape::Line(line) => line.aabb_2d(isometry)
    Shape::Capsule(capsule) => capsule.aabb_2d(isometry)
    Shape::Polygon(polygon) => polygon.aabb_2d(isometry)
  }
}

///|
fn shape_bounding_circle(
  shape : Shape,
  isometry : @math.Isometry2d,
) -> @math.BoundingCircle {
  match shape {
    Shape::Rectangle(rectangle) => rectangle.bounding_circle(isometry)
    Shape::Circle(circle) => circle.bounding_circle(isometry)
    Shape::Triangle(triangle) => triangle.bounding_circle(isometry)
    Shape::Line(line) => line.bounding_circle(isometry)
    Shape::Capsule(capsule) => capsule.bounding_circle(isometry)
    Shape::Polygon(polygon) => polygon.bounding_circle(isometry)
  }
}

///|
fn transformed_points(
  points : Array[@math.Vec2],
  isometry : @sprite.Isometry2d,
) -> Array[@math.Vec2] {
  let transformed : Array[@math.Vec2] = []
  for point in points {
    transformed.push(isometry.transform_point(point))
  }
  transformed
}

///|
fn polygon_points_local(polygon : @sprite.RegularPolygon) -> Array[@math.Vec2] {
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
fn capsule_points_local(capsule : @sprite.Capsule2d) -> Array[@math.Vec2] {
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
fn draw_filled_circle(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
  position : @math.Vec2,
  color : @sprite.Color,
) -> Unit {
  gizmos.circle_2d(@sprite.Isometry2d::new(position, 0.0F), 1.0F, color)
  |> ignore
  gizmos.circle_2d(@sprite.Isometry2d::new(position, 0.0F), 2.0F, color)
  |> ignore
  gizmos.circle_2d(@sprite.Isometry2d::new(position, 0.0F), 3.0F, color)
  |> ignore
}

///|
fn direction_or_fallback(vector : @math.Vec2) -> @math.Dir2 {
  match @math.Dir2::new(vector) {
    Ok(direction) => direction
    Err(_) => @math.Dir2::x()
  }
}

///|
fn normalize_or_fallback(vector : @math.Vec2) -> @math.Vec2 {
  match @math.Dir2::new(vector) {
    Ok(direction) => direction.as_vec2()
    Err(_) => @math.Dir2::x().as_vec2()
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
fn color_gray() -> @sprite.Color {
  @sprite.Color::new(0.5F, 0.5F, 0.5F, 1.0F)
}

///|
fn color_aqua() -> @sprite.Color {
  @sprite.Color::new(0.0F, 1.0F, 1.0F, 1.0F)
}

///|
fn color_orange_red() -> @sprite.Color {
  @sprite.Color::new(1.0F, 0.27058825F, 0.0F, 1.0F)
}

///|
fn color_yellow() -> @sprite.Color {
  @sprite.Color::new(1.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_white() -> @sprite.Color {
  @sprite.Color::white()
}

///|
fn color_fuchsia() -> @sprite.Color {
  @sprite.Color::new(1.0F, 0.0F, 1.0F, 1.0F)
}

///|
fn color_lime() -> @sprite.Color {
  @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
}
