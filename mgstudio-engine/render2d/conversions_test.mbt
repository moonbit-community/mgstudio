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
fn abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn approx_eq(a : Float, b : Float) -> Bool {
  abs_float(a - b) < 0.0001F
}

///|
test "render2d: viewport_to_world and world_to_viewport roundtrip (identity camera)" {
  let camera = Camera::default()
  let projection = OrthographicProjection::default_2d()
  let transform = @math.Transform::identity()
  let target = @math.IVec2::new(100, 100)
  let scale_factor = 1.0F

  // Center of the target maps to world origin.
  let center = @math.Vec2::new(50.0F, 50.0F)
  let ok_center = match
    render2d_camera_viewport_to_world_2d(
      center, camera, projection, transform, target, scale_factor,
    ) {
    Some(world_center) =>
      approx_eq(world_center.x, 0.0F) && approx_eq(world_center.y, 0.0F)
    _ => false
  }
  inspect(ok_center, content="true")

  // Roundtrip an arbitrary point.
  let screen = @math.Vec2::new(12.5F, 87.25F)
  let ok_roundtrip = match
    render2d_camera_viewport_to_world_2d(
      screen, camera, projection, transform, target, scale_factor,
    ) {
    Some(world_pos) =>
      match
        render2d_camera_world_to_viewport_2d(
          world_pos, camera, projection, transform, target, scale_factor,
        ) {
        Some(screen_back) =>
          approx_eq(screen_back.x, screen.x) &&
          approx_eq(screen_back.y, screen.y)
        _ => false
      }
    _ => false
  }
  inspect(ok_roundtrip, content="true")
}

///|
test "render2d: viewport_to_world uses logical pixels when scale_factor != 1" {
  let camera = Camera::default()
  let projection = OrthographicProjection::default_2d()
  let transform = @math.Transform::identity()
  let target = @math.IVec2::new(200, 100) // physical
  let scale_factor = 2.0F

  // Logical center is (50, 25) because 200x100 physical at DPR=2 becomes 100x50 logical.
  let center = @math.Vec2::new(50.0F, 25.0F)
  let ok_center = match
    render2d_camera_viewport_to_world_2d(
      center, camera, projection, transform, target, scale_factor,
    ) {
    Some(world_center) =>
      approx_eq(world_center.x, 0.0F) && approx_eq(world_center.y, 0.0F)
    _ => false
  }
  inspect(ok_center, content="true")
}

///|
test "render2d: viewport rect clamps to target size" {
  let camera = Camera::default().with_viewport(
    Viewport::new(@math.IVec2::new(90, 90), @math.IVec2::new(50, 50)),
  )
  let projection = OrthographicProjection::default_2d()
  let transform = @math.Transform::identity()
  let target = @math.IVec2::new(100, 100)

  // Physical viewport is clamped to 10x10, so logical center should map to world origin.
  let screen = @math.Vec2::new(95.0F, 95.0F)
  let ok_center = match
    render2d_camera_viewport_to_world_2d(
      screen, camera, projection, transform, target, 1.0F,
    ) {
    Some(world_pos) =>
      approx_eq(world_pos.x, 0.0F) && approx_eq(world_pos.y, 0.0F)
    _ => false
  }
  inspect(ok_center, content="true")
}
