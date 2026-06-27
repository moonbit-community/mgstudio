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
// Bevy source: `bevy/crates/bevy_camera/src/primitives.rs`.

///|
pub struct Aabb {
  inner : @math.Aabb3d
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/primitives.rs::Sphere`.
pub struct Sphere {
  center : @math.Vec3
  radius : Float
}

///|
pub fn Sphere::Sphere() -> Sphere {
  Sphere::{ center: @math.Vec3::zero(), radius: 0.0F }
}

///|
pub fn Sphere::new(center : @math.Vec3, radius : Float) -> Sphere {
  Sphere::{ center, radius }
}

///|
pub fn Sphere::center(self : Sphere) -> @math.Vec3 {
  self.center
}

///|
pub fn Sphere::radius(self : Sphere) -> Float {
  self.radius
}

///|
pub type HalfSpace = @math.HalfSpace

///|
pub const VIEW_FRUSTUM_NEAR_PLANE_IDX : Int = @math.VIEW_FRUSTUM_NEAR_PLANE_IDX

///|
pub const VIEW_FRUSTUM_FAR_PLANE_IDX : Int = @math.VIEW_FRUSTUM_FAR_PLANE_IDX

///|
pub struct ViewFrustum {
  inner : @math.ViewFrustum
} derive(Eq, ToJson, FromJson)

///|
pub fn ViewFrustum::new(half_spaces : Array[HalfSpace]) -> ViewFrustum {
  ViewFrustum::{ inner: @math.ViewFrustum::new(half_spaces) }
}

///|
pub fn ViewFrustum::half_spaces(self : ViewFrustum) -> Array[HalfSpace] {
  self.inner.half_spaces
}

///|
pub fn ViewFrustum::corners(self : ViewFrustum) -> Array[@math.Vec3]? {
  @math.ViewFrustum::corners(self.inner)
}

///|
pub struct Frustum {
  half_spaces : Array[HalfSpace]
} derive(Eq, ToJson, FromJson)

///|
pub fn Frustum::new(view_frustum : ViewFrustum) -> Frustum {
  Frustum::{ half_spaces: view_frustum.half_spaces() }
}

///|
pub fn Frustum::Frustum() -> Frustum {
  Frustum::{ half_spaces: [] }
}

///|
pub fn Frustum::default_2d() -> Frustum {
  Frustum::new(
    ViewFrustum::new([
      HalfSpace::new(@math.Vec4::new(1.0F, 0.0F, 0.0F, 1.0F)),
      HalfSpace::new(@math.Vec4::new(-1.0F, 0.0F, 0.0F, 1.0F)),
      HalfSpace::new(@math.Vec4::new(0.0F, 1.0F, 0.0F, 1.0F)),
      HalfSpace::new(@math.Vec4::new(0.0F, -1.0F, 0.0F, 1.0F)),
      HalfSpace::new(@math.Vec4::new(0.0F, 0.0F, 1.0F, 1000.0F)),
      HalfSpace::new(@math.Vec4::new(0.0F, 0.0F, -1.0F, 1000.0F)),
    ]),
  )
}

///|
pub fn Frustum::view_frustum(self : Frustum) -> ViewFrustum {
  ViewFrustum::new(self.half_spaces)
}

///|
pub fn Frustum::corners(self : Frustum) -> Array[@math.Vec3]? {
  self.view_frustum().corners()
}

///|
fn camera_primitives_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn camera_primitives_relative_radius(
  aabb : Aabb,
  plane_normal : @math.Vec3,
  world_from_local : @math.Affine3,
) -> Float {
  let half_extents = aabb.half_size()
  let transformed = @math.Vec3::new(
    plane_normal.dot(world_from_local.matrix3.x_axis),
    plane_normal.dot(world_from_local.matrix3.y_axis),
    plane_normal.dot(world_from_local.matrix3.z_axis),
  )
  camera_primitives_abs(transformed.x) * half_extents.x +
  camera_primitives_abs(transformed.y) * half_extents.y +
  camera_primitives_abs(transformed.z) * half_extents.z
}

///|
fn camera_primitives_signed_distance(
  half_space : HalfSpace,
  point : @math.Vec3,
) -> Float {
  half_space.normal().dot(point) + half_space.d()
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/primitives.rs::Frustum::intersects_sphere`.
pub fn Frustum::intersects_sphere(
  self : Frustum,
  sphere : Sphere,
  intersect_far : Bool,
) -> Bool {
  if self.half_spaces.length() == 0 {
    return true
  }
  let max_plane = if intersect_far {
    VIEW_FRUSTUM_FAR_PLANE_IDX
  } else {
    VIEW_FRUSTUM_NEAR_PLANE_IDX
  }
  let last = if max_plane < self.half_spaces.length() {
    max_plane
  } else {
    self.half_spaces.length() - 1
  }
  for index in 0..<=last {
    let half_space = self.half_spaces[index]
    if camera_primitives_signed_distance(half_space, sphere.center()) +
      sphere.radius() <=
      0.0F {
      return false
    }
  }
  true
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/primitives.rs::Frustum::intersects_obb`.
pub fn Frustum::intersects_obb(
  self : Frustum,
  aabb : Aabb,
  world_from_local : @math.Affine3,
  intersect_near : Bool,
  intersect_far : Bool,
) -> Bool {
  let center_world = world_from_local.transform_point3(aabb.center())
  for index in 0..<self.half_spaces.length() {
    if (index == VIEW_FRUSTUM_NEAR_PLANE_IDX && !intersect_near) ||
      (index == VIEW_FRUSTUM_FAR_PLANE_IDX && !intersect_far) {
      continue
    }
    let half_space = self.half_spaces[index]
    let plane_normal = half_space.normal()
    let relative_radius = camera_primitives_relative_radius(
      aabb, plane_normal, world_from_local,
    )
    if camera_primitives_signed_distance(half_space, center_world) +
      relative_radius <=
      0.0F {
      return false
    }
  }
  true
}

///|
pub let ecs_key_aabb : @ecs.ComponentKey[Aabb] = @ecs.register_component(
  debug_name="mgstudio_camera::Aabb",
)

///|
pub let ecs_key_sphere : @ecs.ComponentKey[Sphere] = @ecs.register_component(
  debug_name="mgstudio_camera::Sphere",
)

///|
pub let ecs_key_frustum : @ecs.ComponentKey[Frustum] = @ecs.register_component(
  debug_name="mgstudio_camera::Frustum",
)

///|
pub impl @ecs.Component for Aabb with fn component() {
  ecs_key_aabb
}

///|
pub impl @ecs.Component for Sphere with fn component() {
  ecs_key_sphere
}

///|
pub impl @ecs.Component for Frustum with fn component() {
  ecs_key_frustum
}

///|
pub fn Aabb::from_math(inner : @math.Aabb3d) -> Aabb {
  Aabb::{ inner, }
}

///|
pub fn Aabb::to_math(self : Aabb) -> @math.Aabb3d {
  self.inner
}

///|
pub fn Aabb::from_min_max(min : @math.Vec3, max : @math.Vec3) -> Aabb {
  Aabb::from_math(@math.Aabb3d::from_min_max(min, max))
}

///|
pub fn Aabb::center(self : Aabb) -> @math.Vec3 {
  self.inner.center()
}

///|
pub fn Aabb::half_size(self : Aabb) -> @math.Vec3 {
  self.inner.half_size()
}

///|
pub(open) trait MeshAabb {
  fn compute_aabb(self : Self) -> Aabb?
}

///|
fn mesh2d_geometry_compute_aabb(geometry : @mesh.Mesh2dGeometry) -> Aabb? {
  guard geometry.flatten_positions_xy() is Some(positions_xy) else {
    return None
  }
  if positions_xy.length() < 2 {
    return None
  }
  let mut min_x = Float::from_double(positions_xy[0])
  let mut min_y = Float::from_double(positions_xy[1])
  let mut max_x = min_x
  let mut max_y = min_y
  let mut index = 2
  while index + 1 < positions_xy.length() {
    let x = Float::from_double(positions_xy[index])
    let y = Float::from_double(positions_xy[index + 1])
    if x < min_x {
      min_x = x
    }
    if y < min_y {
      min_y = y
    }
    if x > max_x {
      max_x = x
    }
    if y > max_y {
      max_y = y
    }
    index = index + 2
  }
  Some(
    Aabb::from_min_max(
      @math.Vec3::new(min_x, min_y, 0.0F),
      @math.Vec3::new(max_x, max_y, 0.0F),
    ),
  )
}

///|
fn mesh3d_geometry_compute_aabb(geometry : @mesh.Mesh3dGeometry) -> Aabb? {
  let vertex_count = geometry.vertex_count()
  if vertex_count == 0 {
    return None
  }
  guard geometry.vertex_position(0) is Some(first) else { return None }
  let mut min_x = first.x
  let mut min_y = first.y
  let mut min_z = first.z
  let mut max_x = first.x
  let mut max_y = first.y
  let mut max_z = first.z
  for index in 1..<vertex_count {
    guard geometry.vertex_position(index) is Some(position) else { continue }
    if position.x < min_x {
      min_x = position.x
    }
    if position.y < min_y {
      min_y = position.y
    }
    if position.z < min_z {
      min_z = position.z
    }
    if position.x > max_x {
      max_x = position.x
    }
    if position.y > max_y {
      max_y = position.y
    }
    if position.z > max_z {
      max_z = position.z
    }
  }
  Some(
    Aabb::from_min_max(
      @math.Vec3::new(min_x, min_y, min_z),
      @math.Vec3::new(max_x, max_y, max_z),
    ),
  )
}

///|
pub impl MeshAabb for @mesh.Mesh2dGeometry with fn compute_aabb(self) {
  mesh2d_geometry_compute_aabb(self)
}

///|
pub impl MeshAabb for @mesh.Mesh3dGeometry with fn compute_aabb(self) {
  mesh3d_geometry_compute_aabb(self)
}

///|
pub impl MeshAabb for @mesh.Mesh with fn compute_aabb(self) {
  match self.as_2d_geometry() {
    Some(geometry) => mesh2d_geometry_compute_aabb(geometry)
    None =>
      match self.as_3d_geometry() {
        Some(geometry) => mesh3d_geometry_compute_aabb(geometry)
        None => None
      }
  }
}

///|
pub fn mesh_compute_aabb(mesh : @mesh.Mesh) -> Aabb? {
  match mesh.as_2d_geometry() {
    Some(geometry) => mesh2d_geometry_compute_aabb(geometry)
    None =>
      match mesh.as_3d_geometry() {
        Some(geometry) => mesh3d_geometry_compute_aabb(geometry)
        None => None
      }
  }
}

///|
fn visibility_write_aabb(
  world : @ecs.World,
  entity : @core.Entity,
  aabb : Aabb,
) -> Unit {
  if (try! world.contains_by_key(entity, ecs_key_aabb)) {
    try! (world.replace(entity, ecs_key_aabb, aabb) |> ignore)
  } else {
    try! world.set_by_key(entity, ecs_key_aabb, aabb)
  }
}

///|
fn visibility_vec3_eq(lhs : @math.Vec3, rhs : @math.Vec3) -> Bool {
  lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
}

///|
fn visibility_aabb_eq(lhs : Aabb, rhs : Aabb) -> Bool {
  visibility_vec3_eq(lhs.center(), rhs.center()) &&
  visibility_vec3_eq(lhs.half_size(), rhs.half_size())
}

///|
priv struct SkinnedMeshBoundsTraceCounters {
  mut skinned_entities : Int
  mut joint_bounds_processed : Int
  mut joint_transform_cache_hits : Int
  mut joint_transform_cache_misses : Int
  mut aabb_writes : Int
}

///|
fn SkinnedMeshBoundsTraceCounters::SkinnedMeshBoundsTraceCounters() -> SkinnedMeshBoundsTraceCounters {
  {
    skinned_entities: 0,
    joint_bounds_processed: 0,
    joint_transform_cache_hits: 0,
    joint_transform_cache_misses: 0,
    aabb_writes: 0,
  }
}

///|
fn skinned_mesh_bounds_trace_emit(
  counters : SkinnedMeshBoundsTraceCounters,
) -> Unit {
  @mesh.skinned_mesh_bounds_trace_emit_counters(
    counters.skinned_entities,
    counters.joint_bounds_processed,
    counters.joint_transform_cache_hits,
    counters.joint_transform_cache_misses,
    counters.aabb_writes,
  )
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::calculate_bounds`.
pub fn calculate_bounds_system(world : @ecs.World) -> Unit {
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let mesh_assets = match world.get_resource(mesh_assets_key) {
    Some(assets) => assets
    None => return
  }
  let tick = world.get_tick_context().ticks()
  let changed_mesh3d = @utils.IntBitSet::new()
  for entity in world.changed_components(@mesh.ecs_key_mesh3d, tick).read() {
    changed_mesh3d.insert(entity.id)
  }
  world.for_each_component(@mesh.ecs_key_mesh3d, fn(entity, mesh3d) {
    if (try! world.contains_by_key(
        entity, @visibility.ecs_key_no_frustum_culling,
      )) ||
      (try! world.contains_by_key(entity, @visibility.ecs_key_no_auto_aabb)) {
      return
    }
    let has_aabb = try! world.contains_by_key(entity, ecs_key_aabb)
    if has_aabb && !changed_mesh3d.contains(entity.id) {
      return
    }
    guard mesh_assets.get(mesh3d.mesh()) is Some(mesh) else { return }
    guard mesh_compute_aabb(mesh) is Some(aabb) else { return }
    visibility_write_aabb(world, entity, aabb)
  })
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::update_skinned_mesh_bounds`.
pub fn update_skinned_mesh_bounds_system(world : @ecs.World) -> Unit {
  let inverse_bindposes_assets_key : @ecs.ResourceKey[
    @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  ] = @asset.assets_resource_key()
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let inverse_bindposes_assets = match
    world.get_resource(inverse_bindposes_assets_key) {
    Some(assets) => assets
    None => return
  }
  let mesh_assets = match world.get_resource(mesh_assets_key) {
    Some(assets) => assets
    None => return
  }
  let aabb_column = world.component_column(ecs_key_aabb)
  let mesh3d_column = world.component_column(@mesh.ecs_key_mesh3d)
  let skinned_mesh_column = world.component_column(@mesh.ecs_key_skinned_mesh)
  let dynamic_bounds_column = world.component_column(
    @mesh.ecs_key_dynamic_skinned_mesh_bounds,
  )
  let global_transform_column = world.component_column(
    @transform.ecs_key_global_transform,
  )
  guard dynamic_bounds_column is Some(dynamic_bounds_column) else { return }
  guard mesh3d_column is Some(mesh3d_column) else { return }
  guard skinned_mesh_column is Some(skinned_mesh_column) else { return }
  guard aabb_column is Some(aabb_column) else { return }
  guard global_transform_column is Some(global_transforms) else { return }
  let write_tick : @core.Tick = {
    let tick = world.read_change_tick()
    if tick > 0 {
      tick
    } else {
      1
    }
  }
  let counters = SkinnedMeshBoundsTraceCounters::SkinnedMeshBoundsTraceCounters()
  mesh3d_column.for_each2_with2_markers_fast_table_row(
    skinned_mesh_column,
    dynamic_bounds_column,
    aabb_column,
    fn(entity, table_id, row_index, mesh3d, skinned_mesh) {
      counters.skinned_entities = counters.skinned_entities + 1
      guard mesh_assets.get(mesh3d.mesh()) is Some(mesh_asset) else { return }
      guard inverse_bindposes_assets.get(skinned_mesh.inverse_bindposes())
        is Some(inverse_bindposes_asset) else {
        return
      }
      let world_from_entity = if table_id >= 0 && row_index >= 0 {
        global_transforms.table_value_at_cached_entity_row(
          entity, table_id, row_index,
        )
      } else {
        global_transforms.get_fast(entity)
      }
      try {
        let (
          skinned_aabb,
          joint_bounds_processed,
          joint_transform_cache_hits,
          joint_transform_cache_misses,
        ) = @mesh.entity_aabb_from_skinned_mesh_bounds_cached_counted(
          global_transforms, mesh_asset, skinned_mesh, inverse_bindposes_asset, world_from_entity,
        )
        counters.joint_bounds_processed = counters.joint_bounds_processed +
          joint_bounds_processed
        counters.joint_transform_cache_hits = counters.joint_transform_cache_hits +
          joint_transform_cache_hits
        counters.joint_transform_cache_misses = counters.joint_transform_cache_misses +
          joint_transform_cache_misses
        let next_aabb = Aabb::from_math(skinned_aabb)
        let changed = if table_id >= 0 && row_index >= 0 {
          match aabb_column.table_value_at_row(table_id, row_index) {
            Some(current_aabb) => !visibility_aabb_eq(current_aabb, next_aabb)
            None => true
          }
        } else {
          match aabb_column.get_fast(entity) {
            Some(current_aabb) => !visibility_aabb_eq(current_aabb, next_aabb)
            None => true
          }
        }
        if changed {
          let wrote = aabb_column.set_tick_only_hot_at_table_row_value(
            table_id, row_index, next_aabb, write_tick,
          )
          if !wrote {
            visibility_write_aabb(world, entity, next_aabb)
          }
          counters.aabb_writes = counters.aabb_writes + 1
        }
      } catch {
        _ => ()
      }
    },
  )
  skinned_mesh_bounds_trace_emit(counters)
}
