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
fn[T : @camera_projection3d.CameraProjection3d] generic_projection_far(
  projection : T,
) -> Float {
  projection.far()
}

///|
fn[T : @camera_projection3d.CameraProjection3d] generic_projection_frustum(
  projection : T,
  camera_transform : @transform.Transform,
) -> Frustum {
  projection.compute_frustum(camera_transform)
}

///|
test "render3d: perspective projection getters expose configured values" {
  let projection = @pbr_render.PerspectiveProjection3d::PerspectiveProjection3d()
  projection.fov = 1.2F
  projection.near = 0.3F
  projection.far = 250.0F
  projection.aspect_ratio = 1.6F
  projection.near_clip_plane = @math.Vec4::new(0.0F, 0.0F, -1.0F, -0.3F)
  debug_inspect(projection_approx_eq(projection.fov, 1.2F), content="true")
  debug_inspect(projection_approx_eq(projection.near, 0.3F), content="true")
  debug_inspect(projection_approx_eq(projection.far, 250.0F), content="true")
  debug_inspect(
    projection_approx_eq(projection.aspect_ratio, 1.6F),
    content="true",
  )
  debug_inspect(
    projection_approx_eq(projection.near_clip_plane.z, -1.0F),
    content="true",
  )
  debug_inspect(
    projection_approx_eq(projection.near_clip_plane.w, -0.3F),
    content="true",
  )
}

///|
test "render3d: perspective with_near keeps default clip plane in sync and preserves custom planes" {
  let synced = @pbr_render.PerspectiveProjection3d::PerspectiveProjection3d().with_near(
    0.75F,
  )
  let preserved = @pbr_render.PerspectiveProjection3d::PerspectiveProjection3d()
    .with_near_clip_plane(@math.Vec4::new(0.0F, -1.0F, 0.0F, -2.0F))
    .with_near(0.75F)
  debug_inspect(
    projection_approx_eq(synced.near_clip_plane().w, -0.75F),
    content="true",
  )
  debug_inspect(
    projection_approx_eq(preserved.near_clip_plane().y, -1.0F),
    content="true",
  )
  debug_inspect(
    projection_approx_eq(preserved.near_clip_plane().w, -2.0F),
    content="true",
  )
}

///|
test "render3d: perspective viewport center produces forward ray" {
  let target_size = @math.IVec2::new(1600, 900)
  debug_inspect(
    render3d_camera_viewport_to_world_ray(
      @math.Vec2::new(800.0F, 450.0F),
      Camera(),
      Projection::default(),
      @transform.Transform::identity(),
      target_size,
      1.0F,
    ).map(fn(ray) {
      let origin = ray.0
      let direction = ray.1
      projection_approx_eq(origin.x, 0.0F) &&
      projection_approx_eq(origin.y, 0.0F) &&
      projection_approx_eq(origin.z, -0.1F) &&
      projection_approx_eq(direction.x, 0.0F) &&
      projection_approx_eq(direction.y, 0.0F) &&
      projection_approx_eq(direction.z, -1.0F)
    }),
    content="Some(true)",
  )
}

///|
test "render3d: custom projection default stores perspective behavior" {
  let custom = CustomProjection3d::CustomProjection3d()
  let perspective = PerspectiveProjection3d::PerspectiveProjection3d()
  let custom_matrix = custom.get_clip_from_view()
  let perspective_matrix = perspective.get_clip_from_view()
  let ok = projection_approx_eq(custom.far(), perspective.far) &&
    projection_approx_eq(custom_matrix.x_axis.x, perspective_matrix.x_axis.x) &&
    projection_approx_eq(custom_matrix.y_axis.y, perspective_matrix.y_axis.y) &&
    projection_approx_eq(custom_matrix.z_axis.z, perspective_matrix.z_axis.z)
  debug_inspect(ok, content="true")
}

///|
test "render3d: projection preserves configured orthographic values" {
  let orthographic = OrthographicProjection3d::default_3d()
    .with_scale(2.5F)
    .with_scaling_mode(FixedVertical(7.5F))
  let projection = Projection::Orthographic(orthographic)
  let ok = match projection {
    Orthographic(value) => {
      let scaling_mode_ok = match value.scaling_mode {
        FixedVertical(height) => projection_approx_eq(height, 7.5F)
        _ => false
      }
      projection_approx_eq(value.scale, 2.5F) && scaling_mode_ok
    }
    Perspective(_) => false
    Custom(_) => false
  }
  debug_inspect(ok, content="true")
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
  debug_inspect(ok, content="true")
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
  debug_inspect(ok, content="true")
}

///|
test "render3d: projection compute_frustum uses camera transform and custom far plane" {
  let perspective = @pbr_render.PerspectiveProjection3d::PerspectiveProjection3d().with_far(
    10.0F,
  )
  let frustum = Projection::Perspective(perspective).compute_frustum(
    @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F),
  )
  let far_plane = frustum.half_spaces[VIEW_FRUSTUM_FAR_PLANE_IDX].normal_d()
  debug_inspect(frustum.half_spaces.length(), content="6")
  debug_inspect(projection_approx_eq(far_plane.x, 0.0F), content="true")
  debug_inspect(projection_approx_eq(far_plane.y, 0.0F), content="true")
  debug_inspect(projection_approx_eq(far_plane.z, 1.0F), content="true")
  debug_inspect(projection_approx_eq(far_plane.w, 7.0F), content="true")
}

///|
test "render3d: standard material stores full affine uv transform" {
  let uv_transform = @transform.Affine2::from_translation(
    @math.Vec2::new(0.25F, -0.5F),
  ).mul(@transform.Affine2::from_scale(@math.Vec2::new(2.0F, 3.0F)))
  let material = @material.StandardMaterial::StandardMaterial().with_uv_transform(
    uv_transform,
  )
  let point = material.uv_transform.transform_point2(
    @math.Vec2::new(0.5F, 0.25F),
  )
  debug_inspect(projection_approx_eq(point.x, 1.25F), content="true")
  debug_inspect(projection_approx_eq(point.y, 0.25F), content="true")
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
impl @camera_projection3d.CameraProjection3d for TestCustomProjection3d with fn get_clip_from_view(
  self,
) {
  test_custom_projection_matrix(self.view_width, self.view_height, 0.0F)
}

///|
impl @camera_projection3d.CameraProjection3d for TestCustomProjection3d with fn get_clip_from_view_for_sub(
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
impl @camera_projection3d.CameraProjection3d for TestCustomProjection3d with fn update(
  self,
  width,
  height,
) {
  { ..self, view_width: width, view_height: height }
}

///|
impl @camera_projection3d.CameraProjection3d for TestCustomProjection3d with fn far(
  self,
) {
  self.far_plane
}

///|
impl @camera_projection3d.CameraProjection3d for TestCustomProjection3d with fn compute_frustum(
  self,
  camera_transform,
) {
  Projection::custom(self).compute_frustum(camera_transform)
}

///|
impl @camera_projection3d.CameraProjection3d for TestCustomProjection3d with fn get_frustum_corners(
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
test "render3d: custom projection stores typed behavior and updates lifecycle state" {
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
    Custom(custom) => {
      let clip_matrix = custom.get_clip_from_view()
      let sub_matrix = custom.get_clip_from_view_for_sub(sub_view)
      let frustum = custom.get_frustum_corners(0.25F, 25.0F)
      projection_approx_eq(clip_matrix.x_axis.x, 2.0F / 640.0F) &&
      projection_approx_eq(clip_matrix.y_axis.y, 2.0F / 320.0F) &&
      projection_approx_eq(custom.far(), 500.0F) &&
      projection_approx_eq(sub_matrix.w_axis.x, 12.0F) &&
      frustum.length() == 8 &&
      projection_approx_eq(frustum[0].x, 640.0F) &&
      projection_approx_eq(frustum[4].z, 25.0F)
    }
    Perspective(_) => false
    Orthographic(_) => false
  }
  debug_inspect(ok, content="true")
}

///|
test "render3d: projection and custom projection satisfy @camera_projection3d.CameraProjection3d forwarding surface" {
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
  debug_inspect(ok, content="true")
}

///|
test "render3d: @camera_projection3d.CameraProjection3d trait exposes compute_frustum" {
  let custom = CustomProjection3d::new(TestCustomProjection3d::{
    view_width: 12.0F,
    view_height: 6.0F,
    far_plane: 321.0F,
  })
  let frustum = generic_projection_frustum(
    custom,
    @transform.Transform::identity(),
  )
  debug_inspect(frustum.half_spaces.length(), content="6")
}

///|
test "render3d: camera helper projection APIs respect custom runtime updates" {
  let camera = @camera_camera.Camera::Camera()
  let projection = Projection::custom(TestCustomProjection3d::{
    view_width: 1.0F,
    view_height: 1.0F,
    far_plane: 1000.0F,
  })
  let transform = @transform.Transform::identity()
  let target_size = @math.IVec2::new(200, 100)
  debug_inspect(
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
  debug_inspect(
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
