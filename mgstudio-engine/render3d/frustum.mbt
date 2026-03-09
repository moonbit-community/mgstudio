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
pub struct HalfSpace {
  normal_d : @math.Vec4
} derive(Eq, ToJson, FromJson)

///|
fn half_space_normal3(normal_d : @math.Vec4) -> @math.Vec3 {
  @math.Vec3::new(normal_d.x, normal_d.y, normal_d.z)
}

///|
fn half_space_normalize(normal_d : @math.Vec4) -> @math.Vec4 {
  let normal = half_space_normal3(normal_d)
  let length = normal.length()
  if length <= 1.0e-12F || length.is_nan() || length.is_inf() {
    normal_d
  } else {
    let inv_length = 1.0F / length
    @math.Vec4::new(
      normal_d.x * inv_length,
      normal_d.y * inv_length,
      normal_d.z * inv_length,
      normal_d.w * inv_length,
    )
  }
}

///|
pub fn HalfSpace::new(normal_d : @math.Vec4) -> HalfSpace {
  HalfSpace::{ normal_d: half_space_normalize(normal_d) }
}

///|
pub fn HalfSpace::normal(self : HalfSpace) -> @math.Vec3 {
  half_space_normal3(self.normal_d)
}

///|
pub fn HalfSpace::d(self : HalfSpace) -> Float {
  self.normal_d.w
}

///|
pub fn HalfSpace::normal_d(self : HalfSpace) -> @math.Vec4 {
  self.normal_d
}

///|
pub fn HalfSpace::intersection_point(
  a : HalfSpace,
  b : HalfSpace,
  c : HalfSpace,
) -> @math.Vec3? {
  let an = a.normal()
  let bn = b.normal()
  let cn = c.normal()
  let x = @math.Vec3::new(an.x, bn.x, cn.x)
  let y = @math.Vec3::new(an.y, bn.y, cn.y)
  let z = @math.Vec3::new(an.z, bn.z, cn.z)
  let d = @math.Vec3::new(-a.d(), -b.d(), -c.d())
  let u = y.cross(z)
  let v = x.cross(d)
  let denom = x.dot(u)
  if half_space_normal3(a.normal_d).length() <= 1.0e-12F ||
    half_space_normal3(b.normal_d).length() <= 1.0e-12F ||
    half_space_normal3(c.normal_d).length() <= 1.0e-12F ||
    denom.is_nan() ||
    denom.is_inf() ||
    (if denom < 0.0F { -denom } else { denom }) <= 1.0e-12F {
    None
  } else {
    Some(@math.Vec3::new(d.dot(u) / denom, z.dot(v) / denom, -y.dot(v) / denom))
  }
}

///|
pub struct ViewFrustum {
  half_spaces : Array[HalfSpace]
} derive(Eq, ToJson, FromJson)

///|
pub const VIEW_FRUSTUM_NEAR_PLANE_IDX : Int = 4

///|
pub const VIEW_FRUSTUM_FAR_PLANE_IDX : Int = 5

///|
fn view_frustum_assert_half_spaces(half_spaces : Array[HalfSpace]) -> Unit {
  if half_spaces.length() != 6 {
    abort("ViewFrustum requires exactly 6 half spaces")
  }
}

///|
pub fn ViewFrustum::new(half_spaces : Array[HalfSpace]) -> ViewFrustum {
  view_frustum_assert_half_spaces(half_spaces)
  ViewFrustum::{ half_spaces, }
}

///|
fn view_frustum_vec4_add(a : @math.Vec4, b : @math.Vec4) -> @math.Vec4 {
  @math.Vec4::new(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
}

///|
fn view_frustum_vec4_sub(a : @math.Vec4, b : @math.Vec4) -> @math.Vec4 {
  @math.Vec4::new(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)
}

///|
pub fn ViewFrustum::from_clip_from_world(
  clip_from_world : ProjectionMatrix3d,
) -> ViewFrustum {
  let row0 = clip_from_world.row(0)
  let row1 = clip_from_world.row(1)
  let row2 = clip_from_world.row(2)
  let row3 = clip_from_world.row(3)
  ViewFrustum::new([
    HalfSpace::new(view_frustum_vec4_add(row3, row0)),
    HalfSpace::new(view_frustum_vec4_sub(row3, row0)),
    HalfSpace::new(view_frustum_vec4_add(row3, row1)),
    HalfSpace::new(view_frustum_vec4_sub(row3, row1)),
    HalfSpace::new(view_frustum_vec4_add(row3, row2)),
    HalfSpace::new(row2),
  ])
}

///|
pub fn ViewFrustum::from_clip_from_world_custom_far(
  clip_from_world : ProjectionMatrix3d,
  view_translation : @math.Vec3,
  view_backward : @math.Vec3,
  far : Float,
) -> ViewFrustum {
  let row0 = clip_from_world.row(0)
  let row1 = clip_from_world.row(1)
  let row2 = clip_from_world.row(2)
  let row3 = clip_from_world.row(3)
  let far_center = view_translation.sub(view_backward.mul_scalar(far))
  ViewFrustum::new([
    HalfSpace::new(view_frustum_vec4_add(row3, row0)),
    HalfSpace::new(view_frustum_vec4_sub(row3, row0)),
    HalfSpace::new(view_frustum_vec4_add(row3, row1)),
    HalfSpace::new(view_frustum_vec4_sub(row3, row1)),
    HalfSpace::new(view_frustum_vec4_add(row3, row2)),
    HalfSpace::new(
      @math.Vec4::new(
        view_backward.x,
        view_backward.y,
        view_backward.z,
        -view_backward.dot(far_center),
      ),
    ),
  ])
}

///|
pub fn ViewFrustum::corners(self : ViewFrustum) -> Array[@math.Vec3]? {
  view_frustum_assert_half_spaces(self.half_spaces)
  let left = self.half_spaces[0]
  let right = self.half_spaces[1]
  let top = self.half_spaces[2]
  let bottom = self.half_spaces[3]
  let near = self.half_spaces[4]
  let far = self.half_spaces[5]
  guard HalfSpace::intersection_point(top, left, near) is Some(near_top_left) else {
    return None
  }
  guard HalfSpace::intersection_point(top, right, near) is Some(near_top_right) else {
    return None
  }
  guard HalfSpace::intersection_point(bottom, right, near)
    is Some(near_bottom_right) else {
    return None
  }
  guard HalfSpace::intersection_point(bottom, left, near)
    is Some(near_bottom_left) else {
    return None
  }
  guard HalfSpace::intersection_point(top, left, far) is Some(far_top_left) else {
    return None
  }
  guard HalfSpace::intersection_point(top, right, far) is Some(far_top_right) else {
    return None
  }
  guard HalfSpace::intersection_point(bottom, right, far)
    is Some(far_bottom_right) else {
    return None
  }
  guard HalfSpace::intersection_point(bottom, left, far)
    is Some(far_bottom_left) else {
    return None
  }
  Some([
    near_top_left, near_top_right, near_bottom_right, near_bottom_left, far_top_left,
    far_top_right, far_bottom_right, far_bottom_left,
  ])
}

///|
pub struct Frustum {
  half_spaces : Array[HalfSpace]
} derive(Eq, ToJson, FromJson)

///|
pub fn Frustum::new(view_frustum : ViewFrustum) -> Frustum {
  view_frustum_assert_half_spaces(view_frustum.half_spaces)
  Frustum::{ half_spaces: view_frustum.half_spaces }
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
pub fn ProjectionMatrix3d::row(
  self : ProjectionMatrix3d,
  index : Int,
) -> @math.Vec4 {
  match index {
    0 =>
      @math.Vec4::new(
        self.x_axis.x,
        self.y_axis.x,
        self.z_axis.x,
        self.w_axis.x,
      )
    1 =>
      @math.Vec4::new(
        self.x_axis.y,
        self.y_axis.y,
        self.z_axis.y,
        self.w_axis.y,
      )
    2 =>
      @math.Vec4::new(
        self.x_axis.z,
        self.y_axis.z,
        self.z_axis.z,
        self.w_axis.z,
      )
    3 =>
      @math.Vec4::new(
        self.x_axis.w,
        self.y_axis.w,
        self.z_axis.w,
        self.w_axis.w,
      )
    _ => abort("ProjectionMatrix3d::row index out of bounds")
  }
}

///|
fn render3d_compute_frustum(
  clip_from_view : ProjectionMatrix3d,
  camera_transform : @math.Transform,
  far : Float,
) -> Frustum {
  let clip_from_world = clip_from_view.mul(
    render3d_view_from_world_matrix(camera_transform),
  )
  Frustum::new(
    ViewFrustum::from_clip_from_world_custom_far(
      clip_from_world,
      camera_transform.translation,
      camera_transform.back(),
      far,
    ),
  )
}

///|
pub fn PerspectiveProjection3d::compute_frustum(
  self : PerspectiveProjection3d,
  camera_transform : @math.Transform,
) -> Frustum {
  render3d_compute_frustum(
    self.get_clip_from_view(),
    camera_transform,
    self.far,
  )
}

///|
pub fn OrthographicProjection3d::compute_frustum(
  self : OrthographicProjection3d,
  camera_transform : @math.Transform,
) -> Frustum {
  render3d_compute_frustum(
    self.get_clip_from_view(),
    camera_transform,
    self.far,
  )
}

///|
pub fn CustomProjection3d::compute_frustum(
  self : CustomProjection3d,
  camera_transform : @math.Transform,
) -> Frustum {
  render3d_compute_frustum(
    self.get_clip_from_view(),
    camera_transform,
    self.far(),
  )
}

///|
pub fn Projection::compute_frustum(
  self : Projection,
  camera_transform : @math.Transform,
) -> Frustum {
  match self {
    Perspective(projection) => projection.compute_frustum(camera_transform)
    Orthographic(projection) => projection.compute_frustum(camera_transform)
    Custom(projection) => projection.compute_frustum(camera_transform)
  }
}

///|
pub fn render3d_update_frusta_system(world : @ecs.World) -> Unit {
  let frustum_store = get_frustum_store(world)
  let tick = world.read_change_tick()
  let query = world.query2_filtered(
    @math.ecs_key_transform,
    ecs_key_projection,
    @ecs.Or::new(
      (
        @ecs.Changed::new(@math.ecs_key_transform),
        @ecs.Changed::new(ecs_key_projection),
        @ecs.Without::new(ecs_key_frustum),
      ),
    ),
  )
  try! query.view(fn(entity, transform, projection) {
    let next = projection.compute_frustum(transform)
    if frustum_store.contains(entity) {
      if frustum_store.get(entity) is Some(current) {
        if current != next {
          frustum_store.set(entity, next, tick) |> ignore
        }
      } else {
        frustum_store.insert(entity, next, tick)
      }
    } else {
      frustum_store.insert(entity, next, tick)
    }
  })
}
