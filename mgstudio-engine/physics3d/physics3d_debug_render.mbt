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
/// First-pass 3D debug-render plugin aligned with Bevy Rapier's plugin purpose:
/// visualize physics colliders directly from the physics world.
///
/// Notes:
/// - Lines are rendered as thin unlit cuboid meshes.
/// - Collider shape coverage matches current `ColliderShape3d` support
///   (`Ball` and `Cuboid`).

///|
pub struct Physics3dDebugRenderContext {
  mut enabled : Bool
}

///|
pub fn Physics3dDebugRenderContext::default() -> Physics3dDebugRenderContext {
  { enabled: true }
}

///|
priv struct Physics3dDebugRenderState {
  mut line_mesh : @pbr.Mesh3d?
  mut dynamic_material : @pbr.MeshMaterial3d?
  mut fixed_material : @pbr.MeshMaterial3d?
  mut kinematic_material : @pbr.MeshMaterial3d?
  mut parentless_material : @pbr.MeshMaterial3d?
  mut sensor_material : @pbr.MeshMaterial3d?
  line_entities : Array[@core.Entity]
}

///|
let physics3d_debug_render_context : Ref[Physics3dDebugRenderContext] = Ref::new(
  Physics3dDebugRenderContext::default(),
)

///|
let physics3d_debug_render_state : Ref[Physics3dDebugRenderState] = Ref::new({
  line_mesh: None,
  dynamic_material: None,
  fixed_material: None,
  kinematic_material: None,
  parentless_material: None,
  sensor_material: None,
  line_entities: [],
})

///|
const DEBUG_LINE_THICKNESS : Float = 0.04F

///|
fn physics3d_debug_make_material(color : @sprite.Color) -> @pbr.MeshMaterial3d {
  let standard = @pbr.StandardMaterial::from_color(color)
    .with_unlit(true)
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
  @pbr.MeshMaterial3d::new(@pbr.standard_material_add(standard))
}

///|
fn physics3d_debug_min_extent(value : Float) -> Float {
  if value > 0.01F {
    value
  } else {
    0.01F
  }
}

///|
fn physics3d_debug_material_for(
  rb3d : RigidBody3d?,
  sensor : Bool,
) -> @pbr.MeshMaterial3d? {
  let state = physics3d_debug_render_state.val
  if sensor {
    return state.sensor_material
  }
  match rb3d {
    Some(rb) =>
      match rb.body_type {
        @dynamics.RigidBodyType::Dynamic => state.dynamic_material
        @dynamics.RigidBodyType::Fixed => state.fixed_material
        @dynamics.RigidBodyType::KinematicPositionBased =>
          state.kinematic_material
        @dynamics.RigidBodyType::KinematicVelocityBased =>
          state.kinematic_material
      }
    None => state.parentless_material
  }
}

///|
fn physics3d_debug_ensure_assets() -> Unit {
  let state = physics3d_debug_render_state.val
  if state.line_mesh is Some(_) {
    return
  }
  state.line_mesh = Some(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
  )
  state.dynamic_material = Some(
    physics3d_debug_make_material(@sprite.Color::new(0.94F, 0.22F, 0.34F, 0.9F)),
  )
  state.fixed_material = Some(
    physics3d_debug_make_material(@sprite.Color::new(0.98F, 0.56F, 0.18F, 0.9F)),
  )
  state.kinematic_material = Some(
    physics3d_debug_make_material(@sprite.Color::new(0.98F, 0.34F, 0.20F, 0.9F)),
  )
  state.parentless_material = Some(
    physics3d_debug_make_material(@sprite.Color::new(0.82F, 0.82F, 0.84F, 0.9F)),
  )
  state.sensor_material = Some(
    physics3d_debug_make_material(@sprite.Color::new(0.22F, 0.82F, 0.98F, 0.9F)),
  )
}

///|
pub fn physics3d_debug_render_set_enabled(enabled : Bool) -> Unit {
  physics3d_debug_render_context.val.enabled = enabled
}

///|
pub fn physics3d_debug_render_enabled() -> Bool {
  physics3d_debug_render_context.val.enabled
}

///|
fn physics3d_debug_clear_lines(world : @ecs.World) -> Unit {
  let ecs_world = world
  let state = physics3d_debug_render_state.val
  while state.line_entities.length() > 0 {
    let entity = state.line_entities.pop().unwrap()
    try! (ecs_world.despawn(entity) |> ignore)
  }
}

///|
priv struct DebugLine3d {
  start : @math.Vec3
  end : @math.Vec3
  material : @pbr.MeshMaterial3d
}

///|
fn physics3d_debug_quat_rotate_vec3(
  q : @math.Quat,
  v : @math.Vec3,
) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn physics3d_debug_transform_point(
  transform : @transform.Transform,
  point_local : @math.Vec3,
) -> @math.Vec3 {
  transform.translation.add(
    physics3d_debug_quat_rotate_vec3(transform.rotation, point_local),
  )
}

///|
fn physics3d_debug_quat_from_x_axis_to(direction : @math.Vec3) -> @math.Quat {
  let dir = direction.normalize_or_zero()
  let dot = dir.x
  if dot > 0.9999F {
    return @math.Quat::identity()
  }
  if dot < -0.9999F {
    return @math.Quat::from_axis_angle(
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      3.141592653589793F,
    )
  }
  let axis = @math.Vec3::new(0.0F, -dir.z, dir.y)
  let s = @math.sqrt((1.0F + dot) * 2.0F)
  let inv = 1.0F / s
  @math.Quat::new(s * 0.5F, axis.x * inv, axis.y * inv, axis.z * inv).normalize()
}

///|
fn physics3d_debug_line_transform(
  start : @math.Vec3,
  end : @math.Vec3,
) -> @transform.Transform {
  let delta = end.sub(start)
  let length = delta.length()
  let center = start.add(delta.mul_scalar(0.5F))
  @transform.Transform::new(
    center,
    physics3d_debug_quat_from_x_axis_to(delta),
    @math.Vec3::new(length, DEBUG_LINE_THICKNESS, DEBUG_LINE_THICKNESS),
  )
}

///|
fn physics3d_debug_add_line(
  lines : Array[DebugLine3d],
  start : @math.Vec3,
  end : @math.Vec3,
  material : @pbr.MeshMaterial3d,
) -> Unit {
  if end.sub(start).length() <= 0.0001F {
    return
  }
  lines.push(DebugLine3d::{ start, end, material })
}

///|
fn physics3d_debug_emit_cuboid_lines(
  lines : Array[DebugLine3d],
  transform : @transform.Transform,
  hx : Float,
  hy : Float,
  hz : Float,
  material : @pbr.MeshMaterial3d,
) -> Unit {
  let x = physics3d_debug_min_extent(hx)
  let y = physics3d_debug_min_extent(hy)
  let z = physics3d_debug_min_extent(hz)
  let corners = [
    @math.Vec3::new(-x, -y, -z),
    @math.Vec3::new(x, -y, -z),
    @math.Vec3::new(x, y, -z),
    @math.Vec3::new(-x, y, -z),
    @math.Vec3::new(-x, -y, z),
    @math.Vec3::new(x, -y, z),
    @math.Vec3::new(x, y, z),
    @math.Vec3::new(-x, y, z),
  ]
  let world_corners : Array[@math.Vec3] = []
  for corner in corners {
    world_corners.push(physics3d_debug_transform_point(transform, corner))
  }
  let edges : Array[(Int, Int)] = [
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 0),
    (4, 5),
    (5, 6),
    (6, 7),
    (7, 4),
    (0, 4),
    (1, 5),
    (2, 6),
    (3, 7),
  ]
  for edge in edges {
    let i0 = edge.0
    let i1 = edge.1
    physics3d_debug_add_line(
      lines,
      world_corners[i0],
      world_corners[i1],
      material,
    )
  }
}

///|
fn physics3d_debug_emit_ball_lines(
  lines : Array[DebugLine3d],
  transform : @transform.Transform,
  radius : Float,
  material : @pbr.MeshMaterial3d,
) -> Unit {
  let r = physics3d_debug_min_extent(radius)
  let segments = 24
  let tau = 6.283185307179586F
  let segf = Float::from_int(segments)
  for i in 0..<segments {
    let i0 = Float::from_int(i)
    let i1 = Float::from_int(i + 1)
    let a0 = tau * i0 / segf
    let a1 = tau * i1 / segf
    let xy0 = @math.Vec3::new(@math.cos(a0) * r, @math.sin(a0) * r, 0.0F)
    let xy1 = @math.Vec3::new(@math.cos(a1) * r, @math.sin(a1) * r, 0.0F)
    let yz0 = @math.Vec3::new(0.0F, @math.cos(a0) * r, @math.sin(a0) * r)
    let yz1 = @math.Vec3::new(0.0F, @math.cos(a1) * r, @math.sin(a1) * r)
    let xz0 = @math.Vec3::new(@math.cos(a0) * r, 0.0F, @math.sin(a0) * r)
    let xz1 = @math.Vec3::new(@math.cos(a1) * r, 0.0F, @math.sin(a1) * r)
    physics3d_debug_add_line(
      lines,
      physics3d_debug_transform_point(transform, xy0),
      physics3d_debug_transform_point(transform, xy1),
      material,
    )
    physics3d_debug_add_line(
      lines,
      physics3d_debug_transform_point(transform, yz0),
      physics3d_debug_transform_point(transform, yz1),
      material,
    )
    physics3d_debug_add_line(
      lines,
      physics3d_debug_transform_point(transform, xz0),
      physics3d_debug_transform_point(transform, xz1),
      material,
    )
  }
}

///|
fn physics3d_debug_ensure_line_pool(
  world : @ecs.World,
  desired_count : Int,
) -> Unit {
  let ecs_world = world
  let state = physics3d_debug_render_state.val
  guard state.line_mesh is Some(mesh) else { return }
  guard state.dynamic_material is Some(default_material) else { return }
  while state.line_entities.length() < desired_count {
    let entity = @pbr.MeshMaterial3dBundle::new(
      mesh,
      default_material,
      @transform.Transform::identity(),
    ).spawn(world)
    state.line_entities.push(entity)
  }
  while state.line_entities.length() > desired_count {
    let entity = state.line_entities.pop().unwrap()
    try! (ecs_world.despawn(entity) |> ignore)
  }
}

///|
pub fn physics3d_debug_render_sync_system(world : @ecs.World) -> Unit {
  physics3d_debug_ensure_assets()
  let state = physics3d_debug_render_state.val
  if !physics3d_debug_render_context.val.enabled {
    if state.line_entities.length() > 0 {
      physics3d_debug_clear_lines(world)
    }
    return
  }

  let tick = world.read_change_tick()
  let ecs_world = world
  let transform_store = @transform.get_transform_store(ecs_world)
  let collider_store = get_collider3d_store(ecs_world)
  let rigid_body_store = get_rigid_body3d_store(ecs_world)
  let mesh_material_store = @pbr.get_mesh_material3d_store(ecs_world)
  let lines : Array[DebugLine3d] = []

  collider_store.for_each(fn(entity, collider) {
    guard physics3d_debug_material_for(
        rigid_body_store.get(entity),
        collider.sensor,
      )
      is Some(material) else {
      return
    }
    let source_transform = transform_store
      .get(entity)
      .unwrap_or(@transform.Transform::identity())
    match collider.shape {
      Ball(radius) =>
        physics3d_debug_emit_ball_lines(
          lines, source_transform, radius, material,
        )
      Cuboid(hx, hy, hz) =>
        physics3d_debug_emit_cuboid_lines(
          lines, source_transform, hx, hy, hz, material,
        )
    }
  })

  physics3d_debug_ensure_line_pool(world, lines.length())
  for i in 0..<lines.length() {
    let line = lines[i]
    let entity = state.line_entities[i]
    transform_store.set(
      entity,
      physics3d_debug_line_transform(line.start, line.end),
      tick,
    )
    |> ignore
    mesh_material_store.set(entity, line.material, tick) |> ignore
  }
}

///|
pub let physics3d_set_debug_render_sync : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.debug_render.sync",
)

///|
pub fn physics3d_debug_render_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .add_fixed_update_system_config(
    @app.system(physics3d_debug_render_sync_system).in_set(
      physics3d_set_debug_render_sync,
    ),
  )
  .configure_set(@app.FixedUpdate, physics3d_set_debug_render_sync, after=[
    physics3d_set_writeback,
  ])
}
