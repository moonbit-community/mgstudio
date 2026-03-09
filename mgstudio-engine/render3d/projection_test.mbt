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
fn projection_approx_eq(a : Float, b : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
fn[T : CameraProjection3d] generic_projection_far(projection : T) -> Float {
  projection.far()
}

///|
test "render3d: perspective projection getters expose configured values" {
  let projection = PerspectiveProjection3d::default()
  projection.fov = 1.2F
  projection.near = 0.3F
  projection.far = 250.0F
  projection.aspect_ratio = 1.6F
  projection.near_clip_plane = @math.Vec4::new(0.0F, 0.0F, -1.0F, -0.3F)
  inspect(projection_approx_eq(projection.fov, 1.2F), content="true")
  inspect(projection_approx_eq(projection.near, 0.3F), content="true")
  inspect(projection_approx_eq(projection.far, 250.0F), content="true")
  inspect(projection_approx_eq(projection.aspect_ratio, 1.6F), content="true")
  inspect(
    projection_approx_eq(projection.near_clip_plane.z, -1.0F),
    content="true",
  )
  inspect(
    projection_approx_eq(projection.near_clip_plane.w, -0.3F),
    content="true",
  )
}

///|
test "render3d: perspective with_near keeps default clip plane in sync and preserves custom planes" {
  let synced = PerspectiveProjection3d::default().with_near(0.75F)
  let preserved = PerspectiveProjection3d::default()
    .with_near_clip_plane(@math.Vec4::new(0.0F, -1.0F, 0.0F, -2.0F))
    .with_near(0.75F)
  inspect(
    projection_approx_eq(synced.near_clip_plane().w, -0.75F),
    content="true",
  )
  inspect(
    projection_approx_eq(preserved.near_clip_plane().y, -1.0F),
    content="true",
  )
  inspect(
    projection_approx_eq(preserved.near_clip_plane().w, -2.0F),
    content="true",
  )
}

///|
test "render3d: custom projection default stores perspective default payload" {
  let custom = CustomProjection3d::default()
  let perspective : PerspectiveProjection3d? = custom.get()
  let ok = match perspective {
    Some(perspective) =>
      projection_approx_eq(custom.far(), 1000.0F) &&
      projection_approx_eq(perspective.fov, @math.pi_half() * 0.5F) &&
      projection_approx_eq(perspective.near, 0.1F) &&
      projection_approx_eq(perspective.aspect_ratio, 1.0F)
    None => false
  }
  inspect(ok, content="true")
}

///|
test "render3d: projection preserves configured orthographic values" {
  let orthographic = OrthographicProjection3d::default_3d()
    .with_scale(2.5F)
    .with_scaling_mode(FixedVertical(7.5F))
  let projection = Projection::Orthographic(orthographic)
  let ok = match projection {
    Projection::Orthographic(value) => {
      let scaling_mode_ok = match value.scaling_mode {
        FixedVertical(height) => projection_approx_eq(height, 7.5F)
        _ => false
      }
      projection_approx_eq(value.scale, 2.5F) && scaling_mode_ok
    }
    Projection::Perspective(_) => false
    Projection::Custom(_) => false
  }
  inspect(ok, content="true")
}

///|
test "render3d: orthographic projection update matches Bevy fixed vertical area" {
  let orthographic = OrthographicProjection3d::default_3d()
    .with_scaling_mode(FixedVertical(6.0F))
    .update(1600.0F, 800.0F)
  let area = orthographic.area
  let ok = projection_approx_eq(orthographic.near, 0.0F) &&
    projection_approx_eq(area.min.x, -6.0F) &&
    projection_approx_eq(area.max.x, 6.0F) &&
    projection_approx_eq(area.min.y, -3.0F) &&
    projection_approx_eq(area.max.y, 3.0F)
  inspect(ok, content="true")
}

///|
test "render3d: orthographic projection update matches Bevy auto min area" {
  let orthographic = OrthographicProjection3d::default_3d()
    .with_scaling_mode(AutoMin(10.0F, 6.0F))
    .update(1200.0F, 600.0F)
  let area = orthographic.area
  let ok = projection_approx_eq(area.min.x, -6.0F) &&
    projection_approx_eq(area.max.x, 6.0F) &&
    projection_approx_eq(area.min.y, -3.0F) &&
    projection_approx_eq(area.max.y, 3.0F)
  inspect(ok, content="true")
}

///|
test "render3d: standard material stores full affine uv transform" {
  let uv_transform = @transform.Affine2::from_translation(
    @math.Vec2::new(0.25F, -0.5F),
  ).mul(@transform.Affine2::from_scale(@math.Vec2::new(2.0F, 3.0F)))
  let material = StandardMaterial::default().with_uv_transform(uv_transform)
  let point = material.uv_transform.transform_point2(
    @math.Vec2::new(0.5F, 0.25F),
  )
  inspect(projection_approx_eq(point.x, 1.25F), content="true")
  inspect(projection_approx_eq(point.y, 0.25F), content="true")
}

///|
struct TestCustomProjection3d {
  view_width : Float
  view_height : Float
  far_plane : Float
}

///|
fn test_custom_projection_matrix(
  view_width : Float,
  view_height : Float,
  sub_bias_x : Float,
) -> ProjectionMatrix3d {
  let safe_width = if view_width <= 0.0F { 1.0F } else { view_width }
  let safe_height = if view_height <= 0.0F { 1.0F } else { view_height }
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(2.0F / safe_width, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 2.0F / safe_height, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(sub_bias_x, 0.0F, 0.0F, 1.0F),
  )
}

///|
impl CameraProjection3d for TestCustomProjection3d with get_clip_from_view(self) {
  test_custom_projection_matrix(self.view_width, self.view_height, 0.0F)
}

///|
impl CameraProjection3d for TestCustomProjection3d with get_clip_from_view_for_sub(
  _self,
  sub_view,
) {
  test_custom_projection_matrix(
    Float::from_double(sub_view.size.x.to_double()),
    Float::from_double(sub_view.size.y.to_double()),
    sub_view.offset.x,
  )
}

///|
impl CameraProjection3d for TestCustomProjection3d with update(
  self,
  width,
  height,
) {
  { ..self, view_width: width, view_height: height }
}

///|
impl CameraProjection3d for TestCustomProjection3d with far(self) {
  self.far_plane
}

///|
impl CameraProjection3d for TestCustomProjection3d with get_frustum_corners(
  self : TestCustomProjection3d,
  z_near : Float,
  z_far : Float,
) {
  [
    @math.Vec3::new(self.view_width, self.view_height, z_near),
    @math.Vec3::new(self.view_width, self.view_height, z_near),
    @math.Vec3::new(self.view_width, self.view_height, z_near),
    @math.Vec3::new(self.view_width, self.view_height, z_near),
    @math.Vec3::new(self.view_width, self.view_height, z_far),
    @math.Vec3::new(self.view_width, self.view_height, z_far),
    @math.Vec3::new(self.view_width, self.view_height, z_far),
    @math.Vec3::new(self.view_width, self.view_height, z_far),
  ]
}

///|
test "render3d: custom projection stores typed payload and updates lifecycle state" {
  let initial = Projection::custom(TestCustomProjection3d::{
    view_width: 1.0F,
    view_height: 1.0F,
    far_plane: 500.0F,
  })
  let sub_view = SubCameraView3d::new(
    @math.IVec2::new(640, 320),
    @math.Vec2::new(12.0F, 6.0F),
    @math.IVec2::new(160, 80),
  )
  let updated = initial.update(640.0F, 320.0F)
  let ok = match updated {
    Projection::Custom(custom) => {
      let payload : TestCustomProjection3d? = custom.get()
      let payload_ok = match payload {
        Some(payload) =>
          projection_approx_eq(payload.view_width, 640.0F) &&
          projection_approx_eq(payload.view_height, 320.0F) &&
          projection_approx_eq(payload.far_plane, 500.0F)
        None => false
      }
      let sub_matrix = custom.get_clip_from_view_for_sub(sub_view)
      let frustum = custom.get_frustum_corners(0.25F, 25.0F)
      payload_ok &&
      projection_approx_eq(custom.far(), 500.0F) &&
      projection_approx_eq(sub_matrix.w_axis.x, 12.0F) &&
      frustum.length() == 8 &&
      projection_approx_eq(frustum[0].x, 640.0F) &&
      projection_approx_eq(frustum[4].z, 25.0F)
    }
    Projection::Perspective(_) => false
    Projection::Orthographic(_) => false
  }
  inspect(ok, content="true")
}

///|
test "render3d: projection and custom projection satisfy CameraProjection3d forwarding surface" {
  let custom = CustomProjection3d::new(TestCustomProjection3d::{
    view_width: 3.0F,
    view_height: 2.0F,
    far_plane: 321.0F,
  })
  let projection = Projection::custom(TestCustomProjection3d::{
    view_width: 4.0F,
    view_height: 3.0F,
    far_plane: 654.0F,
  })
  let updated_projection = generic_projection_far(
    projection.update(128.0F, 64.0F),
  )
  let ok = projection_approx_eq(generic_projection_far(custom), 321.0F) &&
    projection_approx_eq(updated_projection, 654.0F)
  inspect(ok, content="true")
}

///|
test "render3d: camera helper projection APIs respect custom runtime updates" {
  let camera = @render2d.Camera::default()
  let projection = Projection::custom(TestCustomProjection3d::{
    view_width: 1.0F,
    view_height: 1.0F,
    far_plane: 1000.0F,
  })
  let transform = @math.Transform::identity()
  let target_size = @math.IVec2::new(200, 100)
  inspect(
    render3d_camera_world_to_viewport(
      @math.Vec3::new(50.0F, 25.0F, 0.0F),
      camera,
      projection,
      transform,
      target_size,
      1.0F,
    ).map(fn(value) {
      projection_approx_eq(value.x, 150.0F) &&
      projection_approx_eq(value.y, 25.0F)
    }),
    content="Some(true)",
  )
  inspect(
    render3d_camera_viewport_to_world_ray(
      @math.Vec2::new(100.0F, 50.0F),
      camera,
      projection,
      transform,
      target_size,
      1.0F,
    ).map(fn(value) {
      let origin = value.0
      let direction = value.1
      projection_approx_eq(origin.x, 0.0F) &&
      projection_approx_eq(origin.y, 0.0F) &&
      projection_approx_eq(origin.z, 1.0F) &&
      projection_approx_eq(direction.x, 0.0F) &&
      projection_approx_eq(direction.y, 0.0F) &&
      projection_approx_eq(direction.z, -1.0F)
    }),
    content="Some(true)",
  )
}
