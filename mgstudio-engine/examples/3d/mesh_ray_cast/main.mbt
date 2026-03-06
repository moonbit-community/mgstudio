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
/// Port of `bevy/examples/3d/mesh_ray_cast.rs`.
///
/// Parity notes:
/// - Uses `@render3d.MeshRayCastSettings` + `@render3d.mesh_ray_cast_first`
///   shim APIs for Bevy-like ray hit queries.
/// - 3D `Gizmos` still use mesh-primitive fallback visualization in this
///   runtime (line segments + hit markers).

///|
const PI : Float = 3.141592653589793F

///|
const HALF_PI : Float = 1.5707963267948966F

///|
const MAX_BOUNCES : Int = 64

///|
const LASER_SPEED : Float = 0.03F

///|
const RAY_EPSILON : Float = 0.0001F

///|
const LINE_THICKNESS : Float = 0.01F

///|
const HIT_MARKER_SCALE : Float = 0.02F

///|
const ORIGIN_MARKER_SCALE : Float = 0.08F

///|
priv struct BeamPrimitive {
  entity : @core.Entity
  material : @asset.Handle[@render3d.StandardMaterial]
}

///|
priv struct BeamPool {
  segments : Array[BeamPrimitive]
  markers : Array[BeamPrimitive]
}

///|
priv struct RaycastState {
  mut camera : @render2d.Camera
  mut camera_projection : @render3d.CameraProjection3d
  mut camera_transform : @math.Transform
  collider_entities : Array[@core.Entity]
  mut red_pool : BeamPool?
  mut green_pool : BeamPool?
  mut origin_marker : BeamPrimitive?
}

///|
let raycast_state : Ref[RaycastState] = Ref::new({
  camera: @render2d.Camera::default(),
  camera_projection: @render3d.CameraProjection3d::default(),
  camera_transform: @math.Transform::identity(),
  collider_entities: [],
  red_pool: None,
  green_pool: None,
  origin_marker: None,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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
fn set_visibility(
  world : @ecs.World,
  entity : @core.Entity,
  visible : Bool,
) -> Unit {
  let tick = world.read_change_tick()
  let value = if visible {
    @visibility.Visibility::Inherited
  } else {
    @visibility.Visibility::Hidden
  }
  let visibility_store = world.component(@visibility.ecs_key_visibility)
  if visibility_store.contains(entity) {
    visibility_store.set(entity, value, tick) |> ignore
  } else {
    visibility_store.insert(entity, value, tick)
  }
}

///|
fn set_primitive_color(
  primitive : BeamPrimitive,
  color : @render2d.Color,
) -> Unit {
  if @render3d.standard_material_get(primitive.material) is Some(material) {
    @render3d.standard_material_set(
      primitive.material,
      material.with_base_color(color).with_emissive(color),
    )
    |> ignore
  }
}

///|
fn set_primitive_transform(
  world : @ecs.World,
  primitive : BeamPrimitive,
  transform : @math.Transform,
) -> Unit {
  let tick = world.read_change_tick()
  world
  .component(@math.ecs_key_transform)
  .set(primitive.entity, transform, tick)
  |> ignore
}

///|
fn quat_from_x_axis(direction : @math.Vec3) -> @math.Quat {
  let x_axis = @math.Vec3::new(1.0F, 0.0F, 0.0F)
  let dir = direction.normalize_or_zero()
  let axis = x_axis.cross(dir)
  let sin_theta = axis.length()
  if sin_theta <= 0.00001F {
    if x_axis.dot(dir) >= 0.0F {
      return @math.Quat::identity()
    }
    return @math.Quat::from_rotation_y(PI)
  }
  let cos_theta = clampf(x_axis.dot(dir), -1.0F, 1.0F)
  let angle = @math.atan2(sin_theta, cos_theta)
  @math.Quat::from_axis_angle(axis.mul_scalar(1.0F / sin_theta), angle)
}

///|
fn line_transform(start : @math.Vec3, end_ : @math.Vec3) -> @math.Transform {
  let delta = end_.sub(start)
  let length = delta.length()
  let center = start.add(end_).mul_scalar(0.5F)
  let safe_length = if length < 0.00001F { 0.00001F } else { length }
  @math.Transform::from_xyz(center.x, center.y, center.z)
  .with_rotation(quat_from_x_axis(delta))
  .with_scale(@math.Vec3::new(safe_length, LINE_THICKNESS, LINE_THICKNESS))
}

///|
fn marker_transform(position : @math.Vec3, scale : Float) -> @math.Transform {
  @math.Transform::from_xyz(position.x, position.y, position.z).with_scale(
    @math.Vec3::splat(scale),
  )
}

///|
fn hide_pool(world : @ecs.World, pool : BeamPool) -> Unit {
  for segment in pool.segments {
    set_visibility(world, segment.entity, false)
  }
  for marker in pool.markers {
    set_visibility(world, marker.entity, false)
  }
}

///|
fn reflect_direction(direction : @math.Vec3, normal : @math.Vec3) -> @math.Vec3 {
  direction
  .sub(normal.mul_scalar(2.0F * direction.dot(normal)))
  .normalize_or_zero()
}

///|
fn spawn_box_plane(
  world : @ecs.World,
  plane_mesh : @render3d.Mesh3d,
  plane_material : @asset.Handle[@render3d.StandardMaterial],
  translation : @math.Vec3,
  rotation : @math.Quat,
) -> @core.Entity {
  @render3d.MeshMaterial3dBundle::new(
    plane_mesh,
    @render3d.MeshMaterial3d::new(plane_material),
    @math.Transform::from_xyz(translation.x, translation.y, translation.z).with_rotation(
      rotation,
    ),
  ).spawn(world)
}

///|
fn spawn_beam_pool(
  world : @ecs.World,
  line_mesh : @render3d.Mesh3d,
  marker_mesh : @render3d.Mesh3d,
  base_color : @render2d.Color,
) -> BeamPool {
  let segments : Array[BeamPrimitive] = []
  let markers : Array[BeamPrimitive] = []

  for _i in 0..<MAX_BOUNCES {
    let segment_material = @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(base_color).with_unlit(true),
    )
    let segment_entity = @render3d.MeshMaterial3dBundle::new(
      line_mesh,
      @render3d.MeshMaterial3d::new(segment_material),
      @math.Transform::identity(),
    ).spawn(world)
    set_visibility(world, segment_entity, false)
    segments.push({ entity: segment_entity, material: segment_material })

    let marker_material = @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(base_color).with_unlit(true),
    )
    let marker_entity = @render3d.MeshMaterial3dBundle::new(
      marker_mesh,
      @render3d.MeshMaterial3d::new(marker_material),
      @math.Transform::identity(),
    ).spawn(world)
    set_visibility(world, marker_entity, false)
    markers.push({ entity: marker_entity, material: marker_material })
  }

  { segments, markers }
}

///|
fn setup(world : @ecs.World) -> Unit {
  raycast_state.val.camera = @render2d.Camera::default().with_clear_color(
    @render2d.Color::black(),
  )
  raycast_state.val.camera_projection = @render3d.CameraProjection3d::default()
  raycast_state.val.camera_transform = @math.Transform::from_xyz(
    1.5F, 1.5F, 1.5F,
  ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  raycast_state.val.collider_entities.clear()
  raycast_state.val.red_pool = None
  raycast_state.val.green_pool = None
  raycast_state.val.origin_marker = None

  let plane_mesh = @render3d.Mesh3d::from_plane(1.0F, 1.0F)
  let plane_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.5F, 0.5F, 0.5F, 0.05F),
    ).with_alpha_mode(@render3d.AlphaMode3d::Blend),
  )

  // Inward-facing box planes (same topology as Bevy example).
  raycast_state.val.collider_entities.push(
    spawn_box_plane(
      world,
      plane_mesh,
      plane_material,
      @math.Vec3::new(0.0F, 0.5F, 0.0F),
      @math.Quat::from_rotation_x(PI),
    ),
  )
  raycast_state.val.collider_entities.push(
    spawn_box_plane(
      world,
      plane_mesh,
      plane_material,
      @math.Vec3::new(0.0F, -0.5F, 0.0F),
      @math.Quat::identity(),
    ),
  )
  raycast_state.val.collider_entities.push(
    spawn_box_plane(
      world,
      plane_mesh,
      plane_material,
      @math.Vec3::new(0.5F, 0.0F, 0.0F),
      @math.Quat::from_rotation_z(HALF_PI),
    ),
  )
  raycast_state.val.collider_entities.push(
    spawn_box_plane(
      world,
      plane_mesh,
      plane_material,
      @math.Vec3::new(-0.5F, 0.0F, 0.0F),
      @math.Quat::from_rotation_z(-HALF_PI),
    ),
  )
  raycast_state.val.collider_entities.push(
    spawn_box_plane(
      world,
      plane_mesh,
      plane_material,
      @math.Vec3::new(0.0F, 0.0F, 0.5F),
      @math.Quat::from_rotation_x(-HALF_PI),
    ),
  )
  raycast_state.val.collider_entities.push(
    spawn_box_plane(
      world,
      plane_mesh,
      plane_material,
      @math.Vec3::new(0.0F, 0.0F, -0.5F),
      @math.Quat::from_rotation_x(HALF_PI),
    ),
  )

  let directional_light = world.spawn_empty()
  let tick = world.read_change_tick()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    directional_light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 12_000.0F, true),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    directional_light,
    @math.Transform::from_xyz(0.0F, 2.0F, 2.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  @render3d.Camera3dBundle::new(
    raycast_state.val.camera,
    raycast_state.val.camera_transform,
  ).spawn(world)
  |> ignore

  let line_mesh = @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F)
  let marker_mesh = @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F)

  raycast_state.val.red_pool = Some(
    spawn_beam_pool(
      world,
      line_mesh,
      marker_mesh,
      @render2d.Color::new(1.0F, 0.1F, 0.1F, 1.0F),
    ),
  )
  raycast_state.val.green_pool = Some(
    spawn_beam_pool(
      world,
      line_mesh,
      marker_mesh,
      @render2d.Color::new(0.15F, 1.0F, 0.15F, 1.0F),
    ),
  )

  let origin_marker_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white()).with_unlit(
      true,
    ),
  )
  let origin_marker_entity = @render3d.MeshMaterial3dBundle::new(
    marker_mesh,
    @render3d.MeshMaterial3d::new(origin_marker_material),
    @math.Transform::identity(),
  ).spawn(world)
  set_visibility(world, origin_marker_entity, true)
  raycast_state.val.origin_marker = Some({
    entity: origin_marker_entity,
    material: origin_marker_material,
  })

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  @text.Text2dBundle::new(
    @text.Text2d::new(
      "mesh_ray_cast (Adapted)\n" +
      "Red: automatic bouncing ray\n" +
      "Green: cursor ray bounce\n" +
      "MAX_BOUNCES = 64",
    ),
    @text.TextFont::default().with_font(font).with_font_size(16.0F),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-390.0F, 320.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=50.0F,
    ),
  )
  .with_anchor(@render2d.Anchor::top_left())
  .with_bounds(@text.TextBounds::new_horizontal(780.0F))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .with_color(
    @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore
}

///|
fn bounce_ray(
  world : @ecs.World,
  ray_origin : @math.Vec3,
  ray_direction : @math.Vec3,
  pool : BeamPool,
  base_color : @render2d.Color,
  ray_cast_settings : @render3d.MeshRayCastSettings,
) -> Unit {
  let mut current_origin = ray_origin
  let mut current_direction = ray_direction.normalize_or_zero()
  let max_bounces_f = float_from_int(MAX_BOUNCES)
  let mut used = 0

  for i in 0..<MAX_BOUNCES {
    guard @render3d.mesh_ray_cast_first(
        world, current_origin, current_direction, ray_cast_settings,
      )
      is Some((_entity, hit)) else {
      break
    }
    let hit_point = hit.point
    let hit_normal = hit.normal

    let brightness = 1.0F + 10.0F * (1.0F - float_from_int(i) / max_bounces_f)
    let line_color = @render2d.Color::new(
      base_color.r * brightness,
      base_color.g * brightness,
      base_color.b * brightness,
      1.0F,
    )
    let marker_color = @render2d.Color::new(
      base_color.r * brightness * 1.4F,
      base_color.g * brightness * 1.4F,
      base_color.b * brightness * 1.4F,
      1.0F,
    )

    set_visibility(world, pool.segments[i].entity, true)
    set_primitive_transform(
      world,
      pool.segments[i],
      line_transform(current_origin, hit_point),
    )
    set_primitive_color(pool.segments[i], line_color)

    set_visibility(world, pool.markers[i].entity, true)
    set_primitive_transform(
      world,
      pool.markers[i],
      marker_transform(hit_point, HIT_MARKER_SCALE),
    )
    set_primitive_color(pool.markers[i], marker_color)

    used = i + 1
    current_direction = reflect_direction(current_direction, hit_normal)
    current_origin = hit_point.add(current_direction.mul_scalar(RAY_EPSILON))
  }

  for i in used..<MAX_BOUNCES {
    set_visibility(world, pool.segments[i].entity, false)
    set_visibility(world, pool.markers[i].entity, false)
  }
}

///|
fn bouncing_raycast(world : @ecs.World) -> Unit {
  guard raycast_state.val.red_pool is Some(red_pool) else { return }
  guard raycast_state.val.green_pool is Some(green_pool) else { return }
  let ray_cast_settings = @render3d.MeshRayCastSettings::default()
    .with_max_hits(1)
    .with_only_entities(Some(raycast_state.val.collider_entities))

  let elapsed = @time.time_elapsed_seconds()
  let phase_time = if elapsed > 4.0F { elapsed - 4.0F } else { 0.0F }
  let t = @math.cos(phase_time * LASER_SPEED) * PI
  let auto_origin = @math.Vec3::new(
    @math.sin(t),
    @math.cos(3.0F * t) * 0.5F,
    @math.cos(t),
  ).mul_scalar(0.5F)
  let auto_direction = auto_origin.neg().normalize_or_zero()

  if raycast_state.val.origin_marker is Some(origin_marker) {
    set_visibility(world, origin_marker.entity, true)
    set_primitive_transform(
      world,
      origin_marker,
      marker_transform(auto_origin, ORIGIN_MARKER_SCALE),
    )
    set_primitive_color(origin_marker, @render2d.Color::white())
  }

  bounce_ray(
    world,
    auto_origin,
    auto_direction,
    red_pool,
    @render2d.Color::new(1.0F, 0.1F, 0.1F, 1.0F),
    ray_cast_settings,
  )

  if @input.primary_pointer_position() is Some(cursor) {
    let target_size = @math.IVec2::new(
      @window.window_width(),
      @window.window_height(),
    )
    let scale_factor = @window.window_scale_factor()
    if @render3d.render3d_camera_viewport_to_world_ray(
        cursor,
        raycast_state.val.camera,
        raycast_state.val.camera_projection,
        raycast_state.val.camera_transform,
        target_size,
        scale_factor,
      )
      is Some((cursor_origin, cursor_direction)) {
      bounce_ray(
        world,
        cursor_origin,
        cursor_direction.normalize_or_zero(),
        green_pool,
        @render2d.Color::new(0.15F, 1.0F, 0.15F, 1.0F),
        ray_cast_settings,
      )
    } else {
      hide_pool(world, green_pool)
    }
  } else {
    hide_pool(world, green_pool)
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(bouncing_raycast)
  .run()
}
