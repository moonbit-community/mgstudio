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
fn render3d_view_test_approx_eq(a : Float, b : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
test "render3d: rotated view matrix maps camera world position to origin" {
  let transform = @transform.Transform::from_xyz(2.0F, 3.0F, -4.0F).looking_to(
    @math.Vec3::new(0.3F, -0.2F, -1.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let view_from_world = render3d_view_from_world_matrix(transform)
  let view_position = view_from_world.mul_vec4(
    @math.Vec4::new(
      transform.translation.x,
      transform.translation.y,
      transform.translation.z,
      1.0F,
    ),
  )
  debug_inspect(
    render3d_view_test_approx_eq(view_position.x, 0.0F),
    content="true",
  )
  debug_inspect(
    render3d_view_test_approx_eq(view_position.y, 0.0F),
    content="true",
  )
  debug_inspect(
    render3d_view_test_approx_eq(view_position.z, 0.0F),
    content="true",
  )
  debug_inspect(
    render3d_view_test_approx_eq(view_position.w, 1.0F),
    content="true",
  )
}

///|
test "render3d: view matrix preserves Bevy camera local axes" {
  let transform = @transform.Transform::from_xyz(2.0F, 3.0F, -4.0F).looking_to(
    @math.Vec3::new(0.3F, -0.2F, -1.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let view_from_world = render3d_view_from_world_matrix(transform)
  let forward_world = transform.translation.add(transform.forward())
  let right_world = transform.translation.add(transform.right())
  let up_world = transform.translation.add(transform.up())
  let forward_view = view_from_world.mul_vec4(
    @math.Vec4::new(forward_world.x, forward_world.y, forward_world.z, 1.0F),
  )
  let right_view = view_from_world.mul_vec4(
    @math.Vec4::new(right_world.x, right_world.y, right_world.z, 1.0F),
  )
  let up_view = view_from_world.mul_vec4(
    @math.Vec4::new(up_world.x, up_world.y, up_world.z, 1.0F),
  )
  debug_inspect(
    render3d_view_test_approx_eq(forward_view.x, 0.0F),
    content="true",
  )
  debug_inspect(
    render3d_view_test_approx_eq(forward_view.y, 0.0F),
    content="true",
  )
  debug_inspect(
    render3d_view_test_approx_eq(forward_view.z, -1.0F),
    content="true",
  )
  debug_inspect(
    render3d_view_test_approx_eq(right_view.x, 1.0F),
    content="true",
  )
  debug_inspect(
    render3d_view_test_approx_eq(right_view.y, 0.0F),
    content="true",
  )
  debug_inspect(
    render3d_view_test_approx_eq(right_view.z, 0.0F),
    content="true",
  )
  debug_inspect(render3d_view_test_approx_eq(up_view.x, 0.0F), content="true")
  debug_inspect(render3d_view_test_approx_eq(up_view.y, 1.0F), content="true")
  debug_inspect(render3d_view_test_approx_eq(up_view.z, 0.0F), content="true")
}
