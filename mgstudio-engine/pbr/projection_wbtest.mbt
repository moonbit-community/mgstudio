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
fn projection_approx_eq_wb(a : Float, b : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
struct TestCustomProjection3dWb {
  view_width : Float
  view_height : Float
  far_plane : Float
}

///|
fn test_custom_projection_matrix_wb(
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
impl CameraProjection3d for TestCustomProjection3dWb with get_clip_from_view(
  self,
) {
  test_custom_projection_matrix_wb(self.view_width, self.view_height, 0.0F)
}

///|
impl CameraProjection3d for TestCustomProjection3dWb with get_clip_from_view_for_sub(
  _self,
  sub_view,
) {
  test_custom_projection_matrix_wb(
    Float::from_double(sub_view.size.x.to_double()),
    Float::from_double(sub_view.size.y.to_double()),
    sub_view.offset.x,
  )
}

///|
impl CameraProjection3d for TestCustomProjection3dWb with update(
  self,
  width,
  height,
) {
  { ..self, view_width: width, view_height: height }
}

///|
impl CameraProjection3d for TestCustomProjection3dWb with far(self) {
  self.far_plane
}

///|
impl CameraProjection3d for TestCustomProjection3dWb with compute_frustum(
  self,
  camera_transform,
) {
  Projection::custom(self).compute_frustum(camera_transform)
}

///|
impl CameraProjection3d for TestCustomProjection3dWb with get_frustum_corners(
  self : TestCustomProjection3dWb,
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
test "render3d: camera pass projection keeps custom clip matrices alive" {
  let sub_view = SubCameraView3d::new(
    @math.IVec2::new(640, 320),
    @math.Vec2::new(12.0F, 6.0F),
    @math.IVec2::new(160, 80),
  )
  let pass_projection = render3d_camera_pass_projection(
    Projection::custom(TestCustomProjection3dWb::{
      view_width: 640.0F,
      view_height: 320.0F,
      far_plane: 500.0F,
    }),
    Some(sub_view),
    None,
    640,
    320,
  )
  let ok = projection_approx_eq_wb(
      pass_projection.clip_from_view.w_axis.x,
      12.0F,
    ) &&
    projection_approx_eq_wb(pass_projection.clip_from_view.x_axis.x, 0.0125F) &&
    projection_approx_eq_wb(
      pass_projection.unjittered_clip_from_view.w_axis.x,
      12.0F,
    ) &&
    projection_approx_eq_wb(pass_projection.camera_near, 0.0F) &&
    projection_approx_eq_wb(pass_projection.camera_far, 500.0F)
  debug_inspect(ok, content="true")
}

///|
test "render3d: camera pass projection applies Bevy temporal jitter" {
  let projection = Projection::Perspective(
    PerspectiveProjection3d::default()
    .with_fov(1.0F)
    .with_near(0.5F)
    .with_far(100.0F)
    .with_aspect_ratio(2.0F),
  )
  let base_clip_from_view = projection.get_clip_from_view()
  let pass_projection = render3d_camera_pass_projection(
    projection,
    None,
    Some(TemporalJitter::new(@math.Vec2::new(0.5F, -0.25F))),
    200,
    100,
  )
  let ok = projection_approx_eq_wb(
      pass_projection.clip_from_view.z_axis.x,
      base_clip_from_view.z_axis.x + 0.005F,
    ) &&
    projection_approx_eq_wb(
      pass_projection.clip_from_view.z_axis.y,
      base_clip_from_view.z_axis.y + 0.005F,
    ) &&
    projection_approx_eq_wb(
      pass_projection.unjittered_clip_from_view.z_axis.x,
      base_clip_from_view.z_axis.x,
    ) &&
    projection_approx_eq_wb(
      pass_projection.unjittered_clip_from_view.z_axis.y,
      base_clip_from_view.z_axis.y,
    )
  debug_inspect(ok, content="true")
}

///|
test "render3d: perspective clip plane rewrites third row without changing render near distance" {
  let projection = Projection::Perspective(
    PerspectiveProjection3d::default().with_near_clip_plane(
      @math.Vec4::new(0.0F, 0.0F, -1.0F, -2.0F),
    ),
  )
  let clip_from_view = projection.get_clip_from_view()
  let pass_projection = render3d_camera_pass_projection(
    projection,
    None,
    None,
    640,
    360,
  )
  let ok = projection_approx_eq_wb(clip_from_view.z_axis.z, 0.0F) &&
    projection_approx_eq_wb(clip_from_view.w_axis.z, 2.0F) &&
    projection_approx_eq_wb(pass_projection.camera_near, 0.1F)
  debug_inspect(ok, content="true")
}

///|
test "render3d: projection runtime updates changed orthographic projection at stable viewport" {
  let (runtime_projection, runtime_update) = render3d_projection_runtime_update(
    Projection::Orthographic(
      OrthographicProjection3d::default_3d()
      .with_scaling_mode(FixedVertical(6.0F))
      .with_scale(2.0F),
    ),
    Some(ProjectionRuntime3d::{
      last_view_width: 800.0F,
      last_view_height: 400.0F,
      is_orthographic: true,
      orthographic_first_slice_depth: 0.0F,
    }),
    true,
    @sprite.Camera::default(),
    @math.IVec2::new(800, 400),
    1.0F,
  )
  let runtime_is_orthographic = match runtime_update {
    Some(update) => update.is_orthographic
    None => false
  }
  let runtime_first_slice_depth = match runtime_update {
    Some(update) => update.orthographic_first_slice_depth
    None => 0.0F
  }
  let ok = match runtime_projection {
    Projection::Orthographic(orthographic) => {
      let area = orthographic.area()
      let clip_from_view = orthographic.get_clip_from_view()
      let row_two = clip_from_view.row(2)
      let expected_first_slice_depth = if row_two.z.abs() <= 1.0e-6F {
        (row_two.w - 1.0F) / 1.0e-6F
      } else {
        (row_two.w - 1.0F) / row_two.z
      }
      projection_approx_eq_wb(area.min.x, -12.0F) &&
      projection_approx_eq_wb(area.max.x, 12.0F) &&
      projection_approx_eq_wb(area.min.y, -6.0F) &&
      projection_approx_eq_wb(area.max.y, 6.0F) &&
      runtime_is_orthographic &&
      projection_approx_eq_wb(
        runtime_first_slice_depth, expected_first_slice_depth,
      )
    }
    Projection::Perspective(_) => false
    Projection::Custom(_) => false
  }
  debug_inspect(ok, content="true")
}
