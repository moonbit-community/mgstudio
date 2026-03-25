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
fn circle_line_mesh(radius : Float, segments : Int) -> @pbr.Mesh3d {
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
  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new_with_topology(
          points,
          uvs,
          None,
          @mesh.Mesh3dPrimitiveTopology::LineStrip,
        ),
      ),
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
fn normalized_ground_up(ground_transform : @transform.Transform) -> @math.Vec3 {
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
  let ground = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(20.0F, 20.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.3F, 0.5F, 0.3F)),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  viewport_to_world_3d_state.val.ground = Some(ground)

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::default(),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(1.0F, 1.0F, 1.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(15.0F, 5.0F, 15.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  viewport_to_world_3d_state.val.camera = Some(camera)

  let cursor_marker = @pbr.MeshMaterial3dBundle::new(
    circle_line_mesh(CURSOR_RADIUS, CURSOR_SEGMENTS),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_unlit(
          true,
        ),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  viewport_to_world_3d_state.val.cursor_marker = Some(cursor_marker)

  try! (world.replace(
    cursor_marker,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Hidden,
  )
  |> ignore)
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

  let mut cursor_hit : (@math.Vec3, @math.Vec3)? = None
  if @input.mouse_position() is Some(screen_pos) {
    if (try! world.get_by_key(camera_entity, @transform.ecs_key_transform))
      is Some(camera_transform) {
      if (try! world.get_by_key(camera_entity, @sprite.ecs_key_camera))
        is Some(camera) {
        if (try! world.get_by_key(camera_entity, @pbr.ecs_key_projection))
          is Some(projection) {
          if (try! world.get_by_key(ground_entity, @transform.ecs_key_transform))
            is Some(ground_transform) {
            let target_size = @math.IVec2::new(
              @window.window_width(),
              @window.window_height(),
            )
            let scale_factor = @window.window_scale_factor()
            if @pbr.render3d_camera_viewport_to_world_ray(
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

  if cursor_hit is Some((point, ground_up)) {
    try! (world.replace(
      cursor_entity,
      @transform.ecs_key_transform,
      @transform.Transform::new(
        point.add(ground_up.mul_scalar(CURSOR_HEIGHT_OFFSET)),
        quat_from_rotation_arc(@math.Vec3::new(0.0F, 0.0F, 1.0F), ground_up),
        @math.Vec3::splat(1.0F),
      ),
    )
    |> ignore)
    try! (world.replace(
      cursor_entity,
      @visibility.ecs_key_visibility,
      @visibility.Visibility::Visible,
    )
    |> ignore)
  } else {
    try! (world.replace(
      cursor_entity,
      @visibility.ecs_key_visibility,
      @visibility.Visibility::Hidden,
    )
    |> ignore)
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
