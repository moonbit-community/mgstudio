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
/// Port of `bevy/examples/3d/3d_viewport_to_world.rs`.

///|
priv struct ViewportToWorld3dState {
  mut camera : @core.Entity?
  mut ground : @core.Entity?
  mut cursor_marker : @core.Entity?
}

///|
let viewport_to_world_3d_state : Ref[ViewportToWorld3dState] = Ref::new({
  camera: None,
  ground: None,
  cursor_marker: None,
})

///|
const EPSILON : Float = 1.0e-6F

///|
const PI : Float = 3.141592653589793F

///|
const TAU : Float = 6.283185307179586F

///|
const CURSOR_RADIUS : Float = 0.2F

///|
const CURSOR_HEIGHT_OFFSET : Float = 0.01F

///|
const CURSOR_SEGMENTS : Int = 64

///|
fn float_from_int(value : Int) -> Float {
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
fn circle_line_mesh(radius : Float, segments : Int) -> @render3d.Mesh3d {
  let safe_segments = if segments < 3 { 3 } else { segments }
  let points : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  for i in 0..<(safe_segments + 1) {
    let angle = TAU * float_from_int(i) / float_from_int(safe_segments)
    points.push(
      @math.Vec3::new(
        @math.cos(angle) * radius,
        @math.sin(angle) * radius,
        0.0F,
      ),
    )
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
  }
  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new_with_topology(
      points,
      uvs,
      None,
      @mesh.Mesh3dPrimitiveTopology::LineStrip,
    ),
  )
}

///|
fn quat_rotate_vec3(rotation : @math.Quat, value : @math.Vec3) -> @math.Vec3 {
  let axis = @math.Vec3::new(rotation.x, rotation.y, rotation.z)
  let axis_dot_axis = axis.dot(axis)
  let axis_dot_value = axis.dot(value)
  let term1 = axis.mul_scalar(2.0F * axis_dot_value)
  let term2 = value.mul_scalar(rotation.w * rotation.w - axis_dot_axis)
  let term3 = axis.cross(value).mul_scalar(2.0F * rotation.w)
  term1.add(term2).add(term3)
}

///|
fn fallback_rotation_arc_axis(from : @math.Vec3) -> @math.Vec3 {
  let axis = if absf(from.x) < 0.9F {
    from.cross(@math.Vec3::new(1.0F, 0.0F, 0.0F))
  } else {
    from.cross(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  if axis.length_squared() <= EPSILON {
    @math.Vec3::new(0.0F, 0.0F, 1.0F)
  } else {
    axis.normalize_or_zero()
  }
}

///|
fn quat_from_rotation_arc(from : @math.Vec3, to_ : @math.Vec3) -> @math.Quat {
  let from_unit = from.normalize_or_zero()
  let to_unit = to_.normalize_or_zero()
  if from_unit.length_squared() <= EPSILON ||
    to_unit.length_squared() <= EPSILON {
    return @math.Quat::identity()
  }
  let dot = from_unit.dot(to_unit)
  if dot >= 1.0F - EPSILON {
    return @math.Quat::identity()
  }
  if dot <= -1.0F + EPSILON {
    return @math.Quat::from_axis_angle(
      fallback_rotation_arc_axis(from_unit),
      PI,
    )
  }
  let axis = from_unit.cross(to_unit)
  let s = @math.sqrt((1.0F + dot) * 2.0F)
  if s <= EPSILON {
    return @math.Quat::identity()
  }
  let inv_s = 1.0F / s
  @math.Quat::new(axis.x * inv_s, axis.y * inv_s, axis.z * inv_s, s * 0.5F).normalize()
}

///|
fn normalized_ground_up(ground_transform : @math.Transform) -> @math.Vec3 {
  let up = quat_rotate_vec3(
    ground_transform.rotation,
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  ).normalize_or_zero()
  if up.length_squared() <= EPSILON {
    @math.Vec3::new(0.0F, 1.0F, 0.0F)
  } else {
    up
  }
}

///|
fn ray_plane_intersection(
  origin : @math.Vec3,
  direction : @math.Vec3,
  plane_origin : @math.Vec3,
  plane_normal : @math.Vec3,
) -> @math.Vec3? {
  let denominator = direction.dot(plane_normal)
  if absf(denominator) <= EPSILON {
    return None
  }
  let t = plane_origin.sub(origin).dot(plane_normal) / denominator
  if t < 0.0F {
    return None
  }
  Some(origin.add(direction.mul_scalar(t)))
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  let ground = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(20.0F, 20.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::srgb(0.3F, 0.5F, 0.3F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  viewport_to_world_3d_state.val.ground = Some(ground)

  let light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(light, @render3d.DirectionalLight::default(), tick)
  world
  .component(@math.ecs_key_transform)
  .insert(
    light,
    @math.Transform::from_xyz(1.0F, 1.0F, 1.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(15.0F, 5.0F, 15.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  viewport_to_world_3d_state.val.camera = Some(camera)

  let cursor_marker = @render3d.MeshMaterial3dBundle::new(
    circle_line_mesh(CURSOR_RADIUS, CURSOR_SEGMENTS),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(@render2d.Color::white()).with_unlit(
          true,
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  viewport_to_world_3d_state.val.cursor_marker = Some(cursor_marker)

  let tick = world.read_change_tick()
  world
  .component(@visibility.ecs_key_visibility)
  .set(cursor_marker, @visibility.Visibility::Hidden, tick)
  |> ignore
}

///|
fn draw_cursor(world : @ecs.World) -> Unit {
  guard viewport_to_world_3d_state.val.camera is Some(camera_entity) else {
    return
  }
  guard viewport_to_world_3d_state.val.ground is Some(ground_entity) else {
    return
  }
  guard viewport_to_world_3d_state.val.cursor_marker is Some(cursor_entity) else {
    return
  }

  let transform_store = world.component(@math.ecs_key_transform)
  let camera_store = world.component(@render2d.ecs_key_camera)
  let projection_store = world.component(@render3d.ecs_key_projection)
  let mut cursor_hit : (@math.Vec3, @math.Vec3)? = None
  if @input.mouse_position() is Some(screen_pos) {
    if transform_store.get(camera_entity) is Some(camera_transform) {
      if camera_store.get(camera_entity) is Some(camera) {
        if projection_store.get(camera_entity) is Some(projection) {
          if transform_store.get(ground_entity) is Some(ground_transform) {
            let target_size = @math.IVec2::new(
              @window.window_width(),
              @window.window_height(),
            )
            let scale_factor = @window.window_scale_factor()
            if @render3d.render3d_camera_viewport_to_world_ray(
                screen_pos, camera, projection, camera_transform, target_size, scale_factor,
              )
              is Some((ray_origin, ray_dir)) {
              let ground_up = normalized_ground_up(ground_transform)
              if ray_plane_intersection(
                  ray_origin,
                  ray_dir,
                  ground_transform.translation,
                  ground_up,
                )
                is Some(point) {
                cursor_hit = Some((point, ground_up))
              }
            }
          }
        }
      }
    }
  }

  let tick = world.read_change_tick()
  if cursor_hit is Some((point, ground_up)) {
    transform_store.set(
      cursor_entity,
      @math.Transform::new(
        point.add(ground_up.mul_scalar(CURSOR_HEIGHT_OFFSET)),
        quat_from_rotation_arc(@math.Vec3::new(0.0F, 0.0F, 1.0F), ground_up),
        @math.Vec3::splat(1.0F),
      ),
      tick,
    )
    |> ignore
    world
    .component(@visibility.ecs_key_visibility)
    .set(cursor_entity, @visibility.Visibility::Visible, tick)
    |> ignore
  } else {
    world
    .component(@visibility.ecs_key_visibility)
    .set(cursor_entity, @visibility.Visibility::Hidden, tick)
    |> ignore
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(draw_cursor))
  .run()
}
